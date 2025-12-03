class UPigSlideCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PigTags::PigSlide);

	// Tick before regular movement and landing capability
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 70;

	default DebugCategory = PigTags::Pig;

	UPlayerMovementComponent MovementComponent;
	USweepingMovementData MoveData;

	UPigMovementSettings Settings;

	FVector GroundNormal;

	// Used to smooth-out ground normal
	const float NormalInterpSpeed = 60.0;

	UHazeCrumbSyncedVectorComponent CrumbedInput;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CrumbedInput = UHazeCrumbSyncedVectorComponent::GetOrCreate(Player, n"PigSlideCrumbedInput");

		MovementComponent = UPlayerMovementComponent::Get(Player);
		MoveData = MovementComponent.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Eman TODO: Dev shit
		// if (IsActioning(ActionNames::Cancel))
		// 	return true;

		if (MovementComponent.HasMovedThisFrame())
			return false;

		if (!MovementComponent.IsOnSlidingGround() && !IsOnPigSlidingGround())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// if (IsActioning(ActionNames::Cancel))
		// 	return false;

		if (MovementComponent.HasMovedThisFrame())
			return true;

		if (!MovementComponent.IsOnSlidingGround() && !IsOnPigSlidingGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GroundNormal = MovementComponent.CurrentGroundImpactNormal;
		Settings = UPigMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.MeshOffsetComponent.ResetOffsetWithLerp(this, 0.2);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				// Smoothen ground normal
				GroundNormal = Math::VInterpNormalRotationTo(GroundNormal, MovementComponent.CurrentGroundImpactNormal, DeltaTime, NormalInterpSpeed);

				// Get slide direction
				FVector SlideDirection = GroundNormal.CrossProduct(MovementComponent.WorldUp).GetSafeNormal();
				SlideDirection = GroundNormal.CrossProduct(SlideDirection).GetSafeNormal();

				// Constrain input to slide direction with an angle clamp
				FVector Input = MovementComponent.MovementInput.ConstrainToPlane(GroundNormal);
				Input = Input.ConstrainToCone(SlideDirection, Math::DegreesToRadians(Settings.SlideMaxInputAngleRelativeToSlope));
				CrumbedInput.SetValue(Input);

				FVector Velocity = MovementComponent.Velocity + SlideDirection * Settings.SlideMoveSpeed * DeltaTime;

				if (!Input.IsNearlyZero())
					Velocity = Velocity.RotateTowards(Input, Input.Size() * 100.0 * DeltaTime);

				Velocity = Velocity.GetClampedToMaxSize(Settings.SlideMoveSpeed);

				MoveData.AddVelocity(Velocity);
				MoveData.AddGravityAcceleration();

				if (!Velocity.IsNearlyZero())
					MoveData.InterpRotationTo(Velocity.ToOrientationQuat(), 30);
			}
			else
			{
				MoveData.ApplyCrumbSyncedGroundMovement();
			}

			MovementComponent.ApplyMove(MoveData);

			if (Player.Mesh.CanRequestLocomotion())
				Player.RequestLocomotion(n"SlideDash", this);

			// Rotate visuals to input slightly faster than actual movement
			FVector MeshRotationForward = MovementComponent.Velocity.RotateTowards(CrumbedInput.Value, CrumbedInput.Value.Size() * 10);
			FQuat MeshRotation = FQuat::MakeFromX(MeshRotationForward);
			Player.MeshOffsetComponent.LerpToRotation(this, MeshRotation, 0.2);
		}
	}

	bool IsOnPigSlidingGround() const
	{
		if (MovementComponent.GroundContact.Actor != nullptr)
			if (MovementComponent.GroundContact.Actor.ActorHasTag(n"PigSlide"))
				return true;

		if (MovementComponent.GroundContact.Component != nullptr)
			if (MovementComponent.GroundContact.Component.HasTag(n"PigSlide"))
				return true;

		return false;
	}
}