class UPigMovementCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::FloorMotion);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default DebugCategory = PigTags::Pig;

	UPlayerPigComponent PigComponent;
	UPlayerMovementComponent MovementComponent;
	USteppingMovementData MoveData;

	UPigMovementSettings MovementSettings;

	float MoveSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PigComponent = UPlayerPigComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);
		MoveData = MovementComponent.SetupSteppingMovementData();

		MovementSettings = UPigMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MovementComponent.HasMovedThisFrame())
			return false;

		if (!MovementComponent.IsOnWalkableGround())
			return false;

		if (MovementComponent.HasUpwardsImpulse())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MovementComponent.HasMovedThisFrame())
			return true;

		if (!MovementComponent.IsOnWalkableGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.SetActorHorizontalVelocity(Player.ActorForwardVector * Player.ActorHorizontalVelocity.Size());
		MoveSpeed = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.MeshOffsetComponent.ResetOffsetWithLerp(this, 0.1);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				MoveSpeed = Math::FInterpTo(MoveSpeed, GetMovementSpeed(), DeltaTime, MovementSettings.Acceleration);

				// Don't interp from vel if none
				FVector InterpFrom = MovementComponent.HorizontalVelocity.IsNearlyZero() ? Player.ActorForwardVector : MovementComponent.HorizontalVelocity;

				// Don't interp to stick input if none
				FVector InterpTo = (MovementComponent.MovementInput.IsNearlyZero() ? Player.ActorForwardVector : MovementComponent.MovementInput).ConstrainToPlane(Player.MovementWorldUp);

				FVector Direction = Math::QInterpTo(InterpFrom.ToOrientationQuat(), InterpTo.ToOrientationQuat(), DeltaTime, 5.0).Vector();
				FVector HorizontalVelocity = Direction.GetSafeNormal() * MoveSpeed * GetMovementSpeedMultiplier();
				MoveData.AddHorizontalVelocity(HorizontalVelocity);

				MoveData.AddOwnerVerticalVelocity();
				MoveData.AddGravityAcceleration();

				MoveData.AddPendingImpulses();

				if (!MovementComponent.Velocity.IsNearlyZero())
					MoveData.SetRotation(MovementComponent.Velocity.Rotation());
			}
			else
			{
				MoveData.ApplyCrumbSyncedGroundMovement();
			}

			MovementComponent.ApplyMove(MoveData);

			if (Player.Mesh.CanRequestLocomotion())
				Player.RequestLocomotion(n"Movement", this);
		}
	}

	float GetMovementSpeed() const
	{
		float InputSize = MovementComponent.MovementInput.Size();
		if (Math::IsNearlyZero(InputSize))
			return 0.0;

		float MovementSpeed = Math::Lerp(MovementSettings.MoveSpeedMin, MovementSettings.MoveSpeedMax, InputSize) * MovementSettings.SpeedMultiplier;
		return MovementSpeed;
	}

	// Accelerate faster if movement input and facing direction are aligned
	float GetMovementSpeedMultiplier() const
	{
		if (MovementComponent.MovementInput.IsNearlyZero())
			return 1.0;

		FVector FacingDirection = MovementComponent.HorizontalVelocity.IsNearlyZero() ? Player.ActorForwardVector : MovementComponent.HorizontalVelocity.GetSafeNormal();
		float MoveDot = FacingDirection.DotProduct(MovementComponent.MovementInput);
		MoveDot = (Math::Abs(MoveDot - 1.0)) * 0.5;

		float SpeedMultiplier = Math::Saturate(1.0 - Math::Pow(MoveDot, 1.5));
		return SpeedMultiplier;
	}

	// This will rotate faster the more delta there is between current facing direction and input
	float GetRotationSpeedMultiplier(const FVector& CurrentFacingDirection) const
	{
		if (MovementComponent.MovementInput.IsNearlyZero())
			return 1.0;

		float DirectionDot = CurrentFacingDirection.DotProduct(MovementComponent.MovementInput);
		if (DirectionDot >= 0.0)
			return 1.0;

		// Multiply by angular distance
		return Math::Acos(DirectionDot / (CurrentFacingDirection.Size() * MovementComponent.MovementInput.Size()));
	}
}