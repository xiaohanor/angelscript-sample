
class UControlledBabyDragonFloorMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::FloorMotion);
	default CapabilityTags.Add(PlayerFloorMotionTags::FloorMotionMovement);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 150;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	
	float CurrentSpeed = 0.0;
	FVector Direction = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MoveComp.IsOnWalkableGround() || MoveComp.HasUpwardsImpulse())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!MoveComp.IsOnWalkableGround() || MoveComp.HasUpwardsImpulse())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::FloorMotion, this);

		CurrentSpeed = MoveComp.HorizontalVelocity.Size();
		Direction = Player.ActorForwardVector;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::FloorMotion, this);		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{	
				FVector TargetDirection = MoveComp.MovementInput;
				float InputSize = MoveComp.MovementInput.Size();

				// While on edges, we force the player of them.
				// float EdgeAmount = MoveComp.CollisionShape.Shape.GetSphereRadius() * 0.5;
				// if(TargetDirection.IsNearlyZero() && MoveComp.IsOnInvalidGroundEdge(EdgeAmount))
				// {
				// 	InputSize = 1;
				// 	TargetDirection = MoveComp.GetCurrentGroundNormal().VectorPlaneProject(MoveComp.WorldUp).GetSafeNormal();
				// }

				Direction = Math::VInterpConstantTo(Direction, TargetDirection, DeltaTime, 15.0);

				// Calculate the target speed
				float SpeedAlpha = Math::Clamp((InputSize - ControlledBabyDragon::MinimumInput) / (1.0 - AdultDragonMovement::MinimumInput), 0.0, 1.0);
				float TargetSpeed = Math::Lerp(ControlledBabyDragon::MinMoveSpeed, ControlledBabyDragon::MaxMoveSpeed, SpeedAlpha) * MoveComp.MovementSpeedMultiplier;

				if (InputSize < KINDA_SMALL_NUMBER)
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
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			FName AnimTag = n"Movement";
			if(MoveComp.WasFalling())
				AnimTag = n"Landing";

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimTag);
		}
	}


};