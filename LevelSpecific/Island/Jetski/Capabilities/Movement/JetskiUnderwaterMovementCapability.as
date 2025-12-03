asset JetskiUnderwaterSettings of UJetskiSettings
{
	SlowMaxSteeringAmount = 70;
	FastMaxSteeringAmount = 55;
};

asset JetskiUnderwaterMovementSettings of UJetskiMovementSettings
{
    MaxSpeed = 4000;
    MaxSpeedWhileTurning = 1000;
    Acceleration = 3000;
    Deceleration = 500;
};

struct FJetskiUnderwaterMovementActivateParams
{
	EJetskiMovementState PreviousMovementState;
	bool bWasActioningDive = false;
};

class UJetskiUnderwaterMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 110;

	AJetski Jetski;
	UJetskiMovementComponent MoveComp;
	UJetskiMovementData MoveData;

	bool bWasActioningDive = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Jetski = Cast<AJetski>(Owner);
		MoveComp = Jetski.MoveComp;
		MoveData = MoveComp.SetupJetskiMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FJetskiUnderwaterMovementActivateParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!Jetski.IsInWater())
			return false;

		bool bWantsToDive = false;
		if(Jetski.Input.IsActioningDive())
			bWantsToDive = true;
		else if(IsWithinForceDiveZone())
			bWantsToDive = true;

		if(!bWantsToDive)
			return false;

		Params.PreviousMovementState = Jetski.GetMovementState();
		Params.bWasActioningDive = Jetski.Input.IsActioningDive();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!Jetski.IsInWater())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FJetskiUnderwaterMovementActivateParams Params)
	{
		Jetski.SetMovementState(EJetskiMovementState::Underwater);
		Jetski.bIsJumpingFromUnderwater = false;

		if(Params.PreviousMovementState == EJetskiMovementState::Air || Params.PreviousMovementState == EJetskiMovementState::Ground)
		{
			float VerticalSpeed = MoveComp.VerticalSpeed;

			if(VerticalSpeed < 0)
			{
				const float VelocityKeptMultiplier = Jetski.Input.IsActioningDive() ? MoveComp.MovementSettings.UnderwaterLandVelocityKeptWhenDivingMultiplier : MoveComp.MovementSettings.UnderwaterLandVelocityKeptMultiplier;
				VerticalSpeed *= VelocityKeptMultiplier;
			}

			Jetski.SetActorVelocity(FVector(MoveComp.Velocity.X, MoveComp.Velocity.Y, VerticalSpeed));
		}

		Jetski.ApplySettings(JetskiUnderwaterSettings, this);
		Jetski.ApplySettings(JetskiUnderwaterMovementSettings, this);
		bWasActioningDive = Params.bWasActioningDive;

		UJetskiEventHandler::Trigger_OnStartDiving(Jetski);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Jetski.bIsJumpingFromUnderwater = false;

		bWasActioningDive = false;

		Jetski.ClearSettingsByInstigator(this);

		UJetskiEventHandler::Trigger_OnStoppedDiving(Jetski);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Underwater, we use global up as our target
		Jetski.AccelerateUpTowards(FQuat::MakeFromZX(FVector::UpVector, Jetski.ActorForwardVector), 1, DeltaTime, this);

		if (!MoveComp.PrepareMove(MoveData, Jetski.ActorUpVector))
			return;

		if (HasControl())
		{
			ControlMovement(DeltaTime);
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}

	void ControlMovement(float DeltaTime)
	{
		float VerticalSpeed = MoveComp.VerticalSpeed;
		if(!Jetski.Input.IsActioningDive())
		{
			Jetski.bIsJumpingFromUnderwater = true;

			float JumpAcceleration = MoveComp.MovementSettings.UnderwaterDiveJumpAcceleration;

			if(!Jetski.JosefVolumes.IsEmpty() && Jetski.JosefVolumes.Last().bUpJumpAcceleration)
				JumpAcceleration *= 2;

			// Start going upwards quickly
			VerticalSpeed = Math::FInterpConstantTo(
				VerticalSpeed,
				MoveComp.MovementSettings.UnderwaterDiveJumpSpeed,
				DeltaTime,
				JumpAcceleration
			);

			if(bWasActioningDive)
			{
				CrumbStartSurfacing();
			}
		}
		else
		{
			Jetski.bIsJumpingFromUnderwater = false;

			// Dive towards a set distance under the water plane
			const float WaterLineHeight = Jetski.GetCenterOfSphere();
			const float WaveHeight = Jetski.GetWaterPlaneHeight();
			const float TargetHeight = WaveHeight + (MoveComp.MovementSettings.UnderwaterDiveDepth);

			FHazeAcceleratedFloat AccDive;

			AccDive.SnapTo(WaterLineHeight, VerticalSpeed);

			AccDive.SpringTo(
				TargetHeight,
				MoveComp.MovementSettings.UnderwaterDiveReachBottomStiffness,
				MoveComp.MovementSettings.UnderwaterDiveReachBottomDamping,
				DeltaTime
			);

			VerticalSpeed = AccDive.Velocity;
		}

		const float InitialForwardSpeed = Jetski.GetForwardSpeed(EJetskiUp::WaterPlane);
		const float Speed = Jetski.GetAcceleratedSpeed(InitialForwardSpeed, DeltaTime);

		const FVector HorizontalVelocity = Jetski.GetHorizontalForward(EJetskiUp::WaterPlane) * Speed;
		const FVector VerticalVelocity= Jetski.MoveComp.WorldUp * VerticalSpeed;
		MoveData.AddVelocity(HorizontalVelocity + VerticalVelocity);

		Jetski.SteerJetski(MoveData, DeltaTime);
		bWasActioningDive = Jetski.Input.IsActioningDive();
	}

	float GetCurrentDiveHeight() const
	{
		return Jetski.GetCenterOfSphere() - Jetski.GetWaveHeight();
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartSurfacing()
	{
		UJetskiEventHandler::Trigger_OnStopDiving(Jetski);
	}

	bool IsWithinForceDiveZone() const
	{
		const float DistanceAlongSpline = Jetski.GetDistanceAlongSpline();
		auto BlockDiveData = Jetski.JetskiSpline.Spline.FindPreviousComponentAlongSpline(UJetskiSplineDiveZoneComponent, false, DistanceAlongSpline);
		if(!BlockDiveData.IsSet())
			return false;

		auto BlockDiveComp = Cast<UJetskiSplineDiveZoneComponent>(BlockDiveData.Value.Component);
		if(BlockDiveComp.ZoneType != EJetskiSplineDiveZoneType::ForceDive)
			return false;

		return true;
	}
};