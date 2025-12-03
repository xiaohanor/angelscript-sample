class UAdultDragonFreeFlyingCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"AdultDragon");
	default CapabilityTags.Add(n"AdultDragonFreeFlying");

	default DebugCategory = n"AdultDragon";

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	UAdultDragonFreeFlightSettings FlightSettings;
	UAdultDragonAirDriftingSettings DriftSettings;
	USimpleMovementData Movement;

	UPlayerMovementComponent MoveComp;
	UAdultDragonFreeFlyingComponent FlyingComp;
	UPlayerAdultDragonComponent DragonComp;
	UNiagaraComponent OutsideBoundaryEffectComp;

	FHazeAcceleratedFloat AccPitch;
	FHazeAcceleratedFloat AccYaw;

	float TurningTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FlightSettings = UAdultDragonFreeFlightSettings::GetSettings(Player);
		DriftSettings = UAdultDragonAirDriftingSettings::GetSettings(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		FlyingComp = UAdultDragonFreeFlyingComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DragonComp.AnimationState.Apply(EAdultDragonAnimationState::Flying, this, EInstigatePriority::Low);
		Player.ApplyCameraSettings(FlyingComp.CameraSpeedSettings, FlightSettings.CameraBlendInTime, this, SubPriority = 63);
		DragonComp.AimingInstigators.Add(this);
		AccPitch.SnapTo(Player.ActorRotation.Pitch);
		AccYaw.SnapTo(Player.ActorRotation.Yaw);

		TurningTimer = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.AnimationState.Clear(this);
		Player.ClearCameraSettingsByInstigator(this, FlightSettings.CameraBlendOutTime);
		Player.StopCameraShakeByInstigator(this);
		DragonComp.AimingInstigators.RemoveSingleSwap(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl() && AdultDragonFreeFlying::bKillPlayerOutsideBoundary)
		{
			if (CheckIsOutsideKillBoundary(Player.ActorCenterLocation))
			{
				if (OutsideBoundaryEffectComp != nullptr)
				{
					OutsideBoundaryEffectComp.DeactivateImmediately();
					OutsideBoundaryEffectComp = nullptr;
				}

				Player.KillPlayer();
			}
			else
			{
				HandleBoundaryEffect();
			}
		}

		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FRotator DesiredRotation = UpdateMovementDesiredRotation(DeltaTime);

				float MinSpeedAcceleration = 0;
				if (DragonComp.Speed < FlightSettings.MoveSpeedRange.Min)
					MinSpeedAcceleration = FlightSettings.Acceleration * DeltaTime;

				float PitchAcceleration = GetPitchAcceleration(DeltaTime);
				float MoveSpeed = DragonComp.Speed + PitchAcceleration + MinSpeedAcceleration;
				MoveSpeed = FlightSettings.MoveSpeedRange.Clamp(MoveSpeed);
				MoveSpeed += DragonComp.GetBonusMovementSpeed();

				// Apply rubberbanding
				MoveSpeed *= FlyingComp.RubberBandingMoveSpeedMultiplier;

				if (!AdultDragonFreeFlying::bKillPlayerOutsideBoundary)
					RotateDesiredRotationTowardsSpline(DeltaTime, DesiredRotation);

				Movement.SetRotation(DesiredRotation);

				FVector Velocity = Player.ActorForwardVector * MoveSpeed;
				FVector NewLocation = Player.ActorCenterLocation + Velocity * DeltaTime;
				FVector MovementDelta = NewLocation - Player.ActorCenterLocation;

				Movement.AddDelta(MovementDelta);
				DragonComp.Speed = MoveSpeed;
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			UpdateSpeedEffects();
			DragonComp.RequestLocomotionDragonAndPlayer(n"AdultDragonFlying");
			MoveComp.ApplyMove(Movement);
		}
	}

	void HandleBoundaryEffect()
	{
		float DistanceOutsideBoundary = GetDistanceOutsideBoundary(Player.ActorCenterLocation);
		if (DistanceOutsideBoundary > MIN_flt)
		{
			if (OutsideBoundaryEffectComp == nullptr)
				OutsideBoundaryEffectComp = Niagara::SpawnLoopingNiagaraSystemAttached(FlyingComp.OutsideBoundaryEffect, DragonComp.DragonMesh);

			OutsideBoundaryEffectComp.Activate();
		}
		else
		{
			if (OutsideBoundaryEffectComp != nullptr)
			{
				OutsideBoundaryEffectComp.DeactivateImmediately();
				OutsideBoundaryEffectComp = nullptr;
			}
		}
	}

	// Accelerates going downwards and decelerates going upwards
	float GetPitchAcceleration(float DeltaTime) const
	{
		float Pitch = Player.ActorRotation.Pitch;
		float PitchAmplitude = Math::Abs(Pitch);
		float SpeedChange = Pitch >= 0 ? -FlightSettings.SpeedLostGoingUp : FlightSettings.SpeedGainedGoingDown;
		return SpeedChange * PitchAmplitude * DeltaTime;
	}

	bool CheckIsOutsideKillBoundary(FVector Location)
	{
		auto SplinePos = FlyingComp.RubberBandSpline.Spline.GetClosestSplinePositionToWorldLocation(Location);
		float KillRadius = FlyingComp.RubberBandSpline.GetKillRadiusAtSplinePosition(SplinePos);

		FVector SplineToLocation = Location - SplinePos.WorldLocation;
		FVector SplineToLocationOnPlane = SplineToLocation.VectorPlaneProject(SplinePos.WorldForwardVector);
		float Distance = SplineToLocationOnPlane.Size();

		return Distance - KillRadius > 0;
	}

	float GetDistanceOutsideBoundary(FVector Location) const
	{
		auto SplinePos = FlyingComp.RubberBandSpline.Spline.GetClosestSplinePositionToWorldLocation(Location);
		float BoundaryRadius = FlyingComp.RubberBandSpline.GetBoundaryRadiusAtSplinePosition(SplinePos);

		FVector SplineToLocation = Location - SplinePos.WorldLocation;
		FVector SplineToLocationOnPlane = SplineToLocation.VectorPlaneProject(SplinePos.WorldForwardVector);
		float Distance = SplineToLocationOnPlane.Size();

		return Math::Max(Distance - BoundaryRadius, 0);
	}

	void RotateDesiredRotationTowardsSpline(float DeltaTime, FRotator&out DesiredRotation)
	{
		float DistanceOutsideBoundary = GetDistanceOutsideBoundary(Player.ActorCenterLocation);
		if (DistanceOutsideBoundary <= MIN_flt)
			return;

		float DistanceAlpha = Math::NormalizeToRange(DistanceOutsideBoundary, 0, 5000);
		float InterpSpeed = Math::Lerp(0, 1, DistanceAlpha);

		auto TargetSplinePos = FlyingComp.RubberBandSpline.Spline.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);
		TargetSplinePos.Move(10);

		FVector ToSpline = (TargetSplinePos.WorldLocation - Player.ActorCenterLocation).GetSafeNormal();
		FQuat ToSplineQuat = FQuat::MakeFromXZ(ToSpline, FVector::UpVector);

		DesiredRotation = FQuat::Slerp(DesiredRotation.Quaternion(), ToSplineQuat, InterpSpeed * DeltaTime).Rotator();
	}

	FRotator UpdateMovementDesiredRotation(float DeltaTime)
	{
		FVector MovementInput = MoveComp.MovementInput;
		float DesiredPitch = Player.ActorRotation.Pitch;

		if (!Math::IsNearlyZero(MovementInput.X))
		{
			float XAmplitude = Math::Abs(MovementInput.X);
			DesiredPitch = MovementInput.X > 0 ? XAmplitude * FlightSettings.PitchMaxAmount : XAmplitude * FlightSettings.PitchMinAmount;
		}

		float DesiredYawChange = MovementInput.Y * FlightSettings.WantedYawSpeed;
		AccPitch.AccelerateTo(DesiredPitch, FlightSettings.PitchRotationDuration, DeltaTime);

		// Used for camera
		DragonComp.WantedRotation.Pitch = DesiredPitch;
		DragonComp.WantedRotation.Yaw = Player.ActorRotation.Yaw + DesiredYawChange;

		FRotator NewRotation = Player.ActorRotation;
		NewRotation.Pitch = AccPitch.Value;
		NewRotation.Yaw += DesiredYawChange * DeltaTime;

		return NewRotation;
	}

	void UpdateSpeedEffects()
	{
		float SpeedFraction = Math::NormalizeToRange(Player.ActorVelocity.Size(), FlightSettings.MoveSpeedRange.Min, FlightSettings.MoveSpeedRange.Max);

		Player.ApplyManualFractionToCameraSettings(FlightSettings.FOVSpeedScale.GetFloatValue(SpeedFraction), this);
		Player.PlayCameraShake(FlyingComp.SpeedShake, this, FlightSettings.CameraShakeAmount.GetFloatValue(SpeedFraction));

		// SpeedEffect::RequestSpeedEffect(Player, FlightSettings.SpeedEffectValue.GetFloatValue(SpeedFraction), this, EInstigatePriority::Normal);
	}
};