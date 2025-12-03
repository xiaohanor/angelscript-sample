
class UControlledBabyDragonSprintCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Sprint);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 149;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerSprintComponent SprintComp;

	float CurrentSpeed = 0.0;
	FVector Direction = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MoveComp.IsOnWalkableGround())
			return false;

		// This impulse will bring us up in the air, so dont activate
		if(MoveComp.HasUpwardsImpulse())
			return false;

		if (SprintComp.IsForcedToSprint())
			return true;

		if (!SprintComp.IsSprintToggled())
			return false;

		if (MoveComp.MovementInput.IsNearlyZero())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!MoveComp.IsOnWalkableGround())
			return true;

		if (MoveComp.HasUpwardsImpulse())
			return true;

		if (SprintComp.IsForcedToSprint())
			return false;

		if (!SprintComp.IsSprintToggled())
			return true;

		if (MoveComp.MovementInput.IsNearlyZero())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Sprint, this);

		CurrentSpeed = MoveComp.HorizontalVelocity.Size();
		SprintComp.SetSprintActive(true);
		Player.ApplyCameraSettings(SprintComp.SprintCameraSetting, 2, this, SubPriority = 51);
		Direction = Player.ActorForwardVector;

		SprintComp.AnimData.bWantsToMove = false;
		
		Player.ResetAirJumpUsage();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Sprint, this);

		SprintComp.SetSprintActive(false);
		Player.ClearCameraSettingsByInstigator(this, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Player.PlayCameraShake(SprintComp.SprintShake, 0.45);

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector TargetDirection = MoveComp.MovementInput;
				float InputSize = MoveComp.MovementInput.Size();
				Direction = Math::VInterpConstantTo(Direction, TargetDirection, DeltaTime, 15.0);

				// Calculate the target speed
				float SpeedAlpha = Math::Clamp((InputSize - ControlledBabyDragon::MinimumInput) / (1.0 - AdultDragonMovement::MinimumInput), 0.0, 1.0);
				float TargetSpeed = Math::Lerp(ControlledBabyDragon::SprintMinMoveSpeed, ControlledBabyDragon::SprintMaxMoveSpeed, SpeedAlpha) * MoveComp.MovementSpeedMultiplier;
				if(MoveComp.MovementInput.IsNearlyZero())
					TargetSpeed = 0.0;
			
				// Update new velocity
				float InterpSpeed = ControlledBabyDragon::MovementAcceleration;
				if(TargetSpeed < CurrentSpeed)
					InterpSpeed = ControlledBabyDragon::MovementDeceleration;
				CurrentSpeed = Math::FInterpConstantTo(MoveComp.HorizontalVelocity.Size(), TargetSpeed, DeltaTime, InterpSpeed);
				FVector HorizontalVelocity = Direction.GetSafeNormal() * CurrentSpeed;
				
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.AddHorizontalVelocity(HorizontalVelocity);
				//Movement.ApplyMaxEdgeDistanceUntilUnwalkable(FMovementSettingsValue::MakePercentage(0.25));

				Movement.InterpRotationToTargetFacingRotation(ControlledBabyDragon::FacingDirectionInterpSpeed);

				// Turn off the sprint when moving to slow
				float HorizontalVelSq = MoveComp.HorizontalVelocity.SizeSquared();
				if(HorizontalVelSq < Math::Square(50.0))
				{
					SprintComp.SetSprintActive(false);
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			SprintComp.AnimData.bWantsToMove = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();

			FName AnimTag = n"Sprint";
			if(MoveComp.WasFalling())
				AnimTag = n"Landing";

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimTag);
		}
	}
}