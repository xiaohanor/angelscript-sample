struct FJetskiAirDiveMovementActivateParams
{
	EJetskiMovementState PreviousMovementState;
};

/**
 * Faster dive while airborne and pressing the dive button
 */
class UJetskiAirDiveMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(Jetski::Tags::JetskiDive);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 129;

	AJetski Jetski;
	UJetskiMovementComponent MoveComp;
	UJetskiMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Jetski = Cast<AJetski>(Owner);
		MoveComp = Jetski.MoveComp;
		MoveData = MoveComp.SetupJetskiMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FJetskiAirDiveMovementActivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!Jetski.Input.IsActioningDive())
			return false;

		if(MoveComp.VerticalSpeed > 0)
			return false;

		if(IsWithinBlockAirDiveZone())
			return false;

		Params.PreviousMovementState = Jetski.GetMovementState();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!Jetski.Input.IsActioningDive())
			return true;

		if(IsWithinBlockAirDiveZone())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FJetskiAirDiveMovementActivateParams Params)
	{
		Jetski.SetMovementState(EJetskiMovementState::Air);
		Jetski.bIsAirDiving = true;

		if(Params.PreviousMovementState != EJetskiMovementState::Air)
			UJetskiEventHandler::Trigger_OnStartAirMovement(Jetski);

		SpeedEffect::RequestSpeedEffect(Jetski.Driver, 1, this, EInstigatePriority::Normal, 1, false);
		
		Jetski.ApplySettings(JetskiUnderwaterSettings, this);
		Jetski.ApplySettings(JetskiAirMovementSettings, this);

		UJetskiEventHandler::Trigger_OnStartAirDive(Jetski);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Jetski.bIsAirDiving = false;

		if(Jetski.GetMovementState() != EJetskiMovementState::Air)
			UJetskiEventHandler::Trigger_OnStopAirMovement(Jetski);

		SpeedEffect::ClearSpeedEffect(Jetski.Driver, this);

		Jetski.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData, Jetski.ActorUpVector))
			return;

		if(HasControl())
		{
			const FVector Velocity = Jetski.SetNewForwardVelocity(MoveComp.Velocity, EJetskiUp::Global, DeltaTime);
			MoveData.AddVelocity(Velocity);

			MoveData.AddAcceleration(FVector::DownVector * MoveComp.GetGravityForce() * (MoveComp.MovementSettings.AirDiveGravityMultiplier));

			const FVector Forward = -FVector::UpVector.CrossProduct(Jetski.ActorRightVector).GetSafeNormal();
			FVector TargetDir = Math::Lerp(Forward, FVector::DownVector, 0.5);
			TargetDir.Normalize();

			Jetski.AccelerateUpTowards(FQuat::MakeFromXY(TargetDir, Jetski.ActorRightVector), 0.5, DeltaTime, this);

			Jetski.SteerJetski(MoveData, DeltaTime);


			MoveData.AddPendingImpulses();
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}

	bool IsWithinBlockAirDiveZone() const
	{
		const float DistanceAlongSpline = Jetski.GetDistanceAlongSpline();
		auto BlockDiveData = Jetski.JetskiSpline.Spline.FindPreviousComponentAlongSpline(UJetskiSplineDiveZoneComponent, false, DistanceAlongSpline);
		if(!BlockDiveData.IsSet())
			return false;

		auto BlockDiveComp = Cast<UJetskiSplineDiveZoneComponent>(BlockDiveData.Value.Component);
		if(BlockDiveComp.ZoneType != EJetskiSplineDiveZoneType::BlockAirDive)
			return false;

		return true;
	}
}