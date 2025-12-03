
class UControlledBabyDragonJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Jump);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 45;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerJumpComponent JumpComp;
	
	float HorizontalMoveSpeed;
	float HorizontalVelocityInterpSpeed;
	float CurrentSpeed;
	FVector Direction;
	FVector LastDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		JumpComp = UPlayerJumpComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStartedDuringTime(ActionNames::MovementJump, 0.2) && !JumpComp.IsJumpBuffered())
			return false;
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (!MoveComp.IsOnWalkableGround() || !JumpComp.IsInJumpGracePeriod())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (MoveComp.HasGroundContact())
			return true;
		if (MoveComp.HasCeilingContact())
			return true;
		if (MoveComp.HasImpulse())
			return true;
		if (MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp) < -KINDA_SMALL_NUMBER)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(BlockedWhileIn::Jump, this);
		JumpComp.ConsumeBufferedJump();

		CurrentSpeed = MoveComp.HorizontalVelocity.Size();
		Direction = Owner.ActorForwardVector;

		HorizontalVelocityInterpSpeed = HorizontalMoveSpeed * 3.0;
		
		// Add jump impulse
		FVector VerticalVelocity = MoveComp.WorldUp * ControlledBabyDragon::JumpImpulse;
		FVector CurrentHorizontalVelocity = MoveComp.HorizontalVelocity;

		GetGroundAlignedAdjustedVelocity(CurrentHorizontalVelocity, VerticalVelocity);
		Owner.SetActorHorizontalAndVerticalVelocity(CurrentHorizontalVelocity, VerticalVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Jump, this);		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
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
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Jump");
		}
	}

	void GetGroundAlignedAdjustedVelocity(FVector& HorizontalVelocity, FVector& VerticalVelocity) const
	{
		if(!MoveComp.IsOnWalkableGround())
			return;

		FVector GroundNormal = MoveComp.GetCurrentGroundNormal();
		float SlopeDot = GroundNormal.DotProduct(Owner.ActorForwardVector);
		float SlopeAngle = Math::RadiansToDegrees(SlopeDot);
		float Alpha = Math::Abs(SlopeAngle) / MoveComp.WalkableSlopeAngle;

		// Downhill
		if (SlopeDot > KINDA_SMALL_NUMBER)
		{
			// align the horizontal velocity with the world up, 
			//making us leave the ground and not follow the slope down
			FVector HorizontalAlignedVelocity = HorizontalVelocity.VectorPlaneProject(MoveComp.WorldUp).GetSafeNormal() * HorizontalVelocity.Size();	
			Alpha = Math::EaseOut(0.0, 1.0, Alpha, 2.0);
			HorizontalVelocity = Math::Lerp(HorizontalVelocity, HorizontalAlignedVelocity, Alpha);
		}
		// Uphill
		else if(SlopeDot < -KINDA_SMALL_NUMBER)
		{
			// reduce the velocty so we are going in a vertical direction
			// more than a horizontal direction, making us not
			// fly of edges in a high speed
			float Mul = Math::Lerp(1.0, 0.5, Alpha);
			HorizontalVelocity *= Mul;
			VerticalVelocity *= Mul;
		}
	}


};