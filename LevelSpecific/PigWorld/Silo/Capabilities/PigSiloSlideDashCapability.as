class UPigSiloSlideDashCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;
	default DebugCategory = PigTags::Pig;

	UPlayerPigSiloComponent PigSiloComponent;
	UPlayerMovementComponent MovementComponent;
	USweepingMovementData MoveData;

	FSplinePosition SplinePosition;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PigSiloComponent = UPlayerPigSiloComponent::Get(Player);
		MovementComponent = UPlayerMovementComponent::Get(Player);
		MoveData = MovementComponent.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return false;
		
		// if (!WasActionStarted(ActionNames::Cancel))
		// 	return false;

		// if (!PigSiloComponent.IsSiloMovementActive())
		// 	return false;

		// if (MovementComponent.HasMovedThisFrame())
		// 	return false;
	
		// if (MovementComponent.HasUpwardsImpulse())
		// 	return false;

		// return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!PigSiloComponent.IsSiloMovementActive())
			return true;

		if (MovementComponent.HasMovedThisFrame())
			return true;

		if (ActiveDuration > 0.8)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		float DistanceAlongSpline = PigSiloComponent.SiloPlatform.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
		SplinePosition = FSplinePosition(PigSiloComponent.SiloPlatform.Spline, DistanceAlongSpline, true);

		Player.CapsuleComponent.OverrideCapsuleSize(30, 30, this, EInstigatePriority::High);

		// Spawn vfx
		Niagara::SpawnOneShotNiagaraSystemAtLocation(PigSiloComponent.SlideDashVFX, Player.ActorLocation + Player.ActorForwardVector * 100, Player.ActorRotation + FRotator(90, 0, 0));

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(PigTags::SpecialAbility, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.CapsuleComponent.ClearCapsuleSizeOverride(this);

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(PigTags::SpecialAbility, this);
	}

	// Eman TODO: Raw shiet
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			float SplineMoveDelta = 800 * DeltaTime;
			SplinePosition.Move(SplineMoveDelta);

			FVector MoveDelta = SplinePosition.GetWorldLocation() - Player.ActorLocation;
			MoveDelta += SplinePosition.GetWorldRightVector() * PigSiloComponent.SiloPlatform.GetHorizontalOffsetForPlayer(Player);

			MoveData.AddDelta(MoveDelta);

			MoveData.AddOwnerVerticalVelocity();
			MoveData.AddGravityAcceleration();
			MoveData.AddGravityAcceleration();
			MoveData.AddGravityAcceleration();

			MoveData.SetRotation(SplinePosition.WorldForwardVector.Rotation());
			MovementComponent.ApplyMove(MoveData);

			if (Player.Mesh.CanRequestLocomotion())
				Player.RequestLocomotion(n"SlideDash", this);

			Player.MeshOffsetComponent.LerpToRotation(PigSiloComponent, SplinePosition.WorldRotation, 0.2);
		}
	}
}