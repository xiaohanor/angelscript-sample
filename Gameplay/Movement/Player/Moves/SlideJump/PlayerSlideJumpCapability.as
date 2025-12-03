
class UPlayerSlideJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Slide);
	default CapabilityTags.Add(PlayerMovementTags::Jump);
	default CapabilityTags.Add(PlayerSlideTags::SlideJump);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 36;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UPlayerSlideJumpComponent JumpComp;
	UPlayerSlideComponent SlideComp;
	UPlayerAirMotionComponent AirMotionComp;
	USteppingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		JumpComp = UPlayerSlideJumpComponent::GetOrCreate(Player);
		SlideComp = UPlayerSlideComponent::GetOrCreate(Player);
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!JumpComp.bJump)
			return false;

		if (MoveComp.HasMovedThisFrame())
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

		if (MoveComp.HasUpwardsImpulse())
			return true;

		// if (MoveComp.HasCeilingImpact())
		// 	return true;

		//If we have started descending and we no longer have any active slides
		if(MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp) < 0 && SlideComp.ActiveSlide.IsDefaultValue())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Slide, this);

		FVector VerticalVelocity = MoveComp.WorldUp * JumpComp.Settings.VerticalImpulse;
		FVector HorizontalVelocity = MoveComp.HorizontalVelocity;

		//If we find a follow velocity component on the object we are jumping from
		if(MoveComp.GroundContact.IsValidBlockingHit())
		{
			if(MoveComp.GroundContact.Actor != nullptr)
			{
				UPlayerInheritVelocityComponent VelocityComp = Cast<UPlayerInheritVelocityComponent>(MoveComp.GroundContact.Actor.GetComponent(UPlayerInheritVelocityComponent));
				if(VelocityComp != nullptr)
				{
					VelocityComp.AddFollowAdjustedVelocity(MoveComp, HorizontalVelocity, VerticalVelocity);
				}
			}
		}

		Player.SetActorHorizontalAndVerticalVelocity(HorizontalVelocity, VerticalVelocity);
		SlideComp.AnimData.bSlideJumpActive = true;
		JumpComp.bJump = false;

		UPlayerCoreMovementEffectHandler::Trigger_Slide_Jump(Player);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Slide, this);
		SlideComp.AnimData.Reset();
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
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Slide");	
		}
	}
}