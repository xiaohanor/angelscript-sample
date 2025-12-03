
class UGenericGoatJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Jump);
	default CapabilityTags.Add(PlayerMovementTags::GroundJump);
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 45;
	default TickGroupSubPlacement = 2;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UPlayerJumpComponent JumpComp;
	UPlayerSprintComponent SprintComp;
	UPlayerAirMotionComponent AirMotionComp;
	UPlayerFloorMotionComponent JogComp;
	USteppingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		JumpComp = UPlayerJumpComponent::GetOrCreate(Player);
		JogComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStartedDuringTime(ActionNames::MovementJump, JumpComp.Settings.InputBufferWindow) && !JumpComp.IsJumpBuffered())
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MoveComp.IsOnWalkableGround() && !JumpComp.IsInJumpGracePeriod())
			return false;

		// if (!MoveComp.IsOnWalkableGround())
		// 	return false;

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

		if (ActiveDuration >= 1.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Jump, this);
		JumpComp.ConsumeBufferedJump();

		// We are no longer in jump grace, since we just jumped
		JumpComp.StopJumpGracePeriod();
		JumpComp.StartJump();
		
		// Add jump impulse
		FVector VerticalVelocity = MoveComp.WorldUp * JumpComp.Settings.Impulse * 1.6;
		// FVector HorizontalVelocity = MoveComp.HorizontalVelocity;
		FVector HorizontalVelocity = MoveComp.HorizontalVelocity.GetSafeNormal()
			* Math::Max(AirMotionComp.Settings.HorizontalMoveSpeed * MoveComp.MovementInput.Size(),
						MoveComp.HorizontalVelocity.Size());

		//If we find a follow velocity component on the object we are jumping from
		if(MoveComp.GroundContact.IsValidBlockingHit())
		{
			if(MoveComp.GroundContact.Actor != nullptr)
			{
				UPlayerInheritVelocityComponent VelocityComp = Cast<UPlayerInheritVelocityComponent>(MoveComp.GroundContact.Actor.GetComponent(UPlayerInheritVelocityComponent));
				if(VelocityComp != nullptr)
					VelocityComp.AddFollowAdjustedVelocity(MoveComp, HorizontalVelocity, VerticalVelocity);
			}
		}
		
		GetGroundAlignedAdjustedVelocity(HorizontalVelocity, VerticalVelocity);
		Player.SetActorHorizontalAndVerticalVelocity(HorizontalVelocity, VerticalVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		JumpComp.StopJump();
		Player.UnblockCapabilities(BlockedWhileIn::Jump, this);		
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector AirControlVelocity = AirMotionComp.CalculateStandardAirControlVelocity(
					MoveComp.MovementInput,
					MoveComp.HorizontalVelocity,
					DeltaTime,
				);
				Movement.AddHorizontalVelocity(AirControlVelocity);
				Movement.AddOwnerVerticalVelocity();

				Movement.AddGravityAcceleration();
				Movement.InterpRotationToTargetFacingRotation(JumpComp.Settings.FacingDirectionInterpSpeed * MoveComp.MovementInput.Size());
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Jump");
		}

		// Buffer an air jump if we press it during jumping
		if (WasActionStarted(ActionNames::MovementJump) && ActiveDuration > 0.0)
			JumpComp.BufferJumpInput();
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
			// reduce the velocity so we are going in a vertical direction
			// more than a horizontal direction, making us not
			// fly of edges in a high speed
			float Mul = Math::Lerp(1.0, 0.5, Alpha);
			HorizontalVelocity *= Mul;
			VerticalVelocity *= Mul;
		}
	}
}