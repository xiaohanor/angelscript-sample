class UControlledBabyDragonAirMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::AirMotion);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 160;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	
	float CurrentSpeed;
	FVector Direction;
	FVector LastDirection;

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
		Player.BlockCapabilities(BlockedWhileIn::AirMotion, this);

		CurrentSpeed = MoveComp.HorizontalVelocity.Size();
		Direction = Owner.ActorForwardVector;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::AirMotion, this);		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				float InputSize = MoveComp.MovementInput.Size();

				// Calculate the target speed
				float SpeedAlpha = Math::Clamp((InputSize - ControlledBabyDragon::MinimumInput) / (1.0 - ControlledBabyDragon::MinimumInput), 0.0, 1.0);
				float TargetSpeed = Math::Lerp(ControlledBabyDragon::AirHorizontalMinMoveSpeed, ControlledBabyDragon::AirHorizontalMaxMoveSpeed, SpeedAlpha) * MoveComp.MovementSpeedMultiplier;

				if (InputSize < KINDA_SMALL_NUMBER)
					TargetSpeed = 0.0;

				FVector TargetDirection = MoveComp.MovementInput.GetSafeNormal();
				Direction = Math::VInterpNormalRotationTo(Direction, TargetDirection, DeltaTime, ControlledBabyDragon::AirMovementRotationSpeed);

				float InterpSpeed = ControlledBabyDragon::AirHorizontalVelocityAcceleration;
				CurrentSpeed = Math::FInterpConstantTo(MoveComp.HorizontalVelocity.Size(), TargetSpeed, DeltaTime, InterpSpeed);

				//Get last direction before input reaches almost 0
				if (Direction.Size() > KINDA_SMALL_NUMBER)
					LastDirection = Direction.GetSafeNormal();

				FVector CurrentHorizontalVelocity = Math::VInterpConstantTo(MoveComp.HorizontalVelocity, LastDirection * CurrentSpeed, DeltaTime, ControlledBabyDragon::AirHorizontalVelocityAcceleration);
				Movement.AddHorizontalVelocity(CurrentHorizontalVelocity);
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();

				Movement.InterpRotationToTargetFacingRotation(ControlledBabyDragon::FacingDirectionInterpSpeed * MoveComp.MovementInput.Size());
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AirMovement");
		}
	}


};