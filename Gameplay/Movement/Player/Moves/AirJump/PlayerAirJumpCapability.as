
class UPlayerAirJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Jump);
	default CapabilityTags.Add(PlayerMovementTags::AirJump);

	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::WallRun);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::Vault);
	default CapabilityTags.Add(BlockedWhileIn::LedgeMantle);

	default BlockExclusionTags.Add(n"ExcludeAirJumpAndDash");

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	//Late active tick to allow transitions out, early inactive to give activation priority.
	default TickGroupOrder = 40;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 5, 3);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UPlayerJumpComponent JumpComp;
	UPlayerSprintComponent SprintComp;
	UPlayerFloorMotionComponent FloorMotionComp;
	UPlayerAirJumpComponent AirJumpComp;
	UPlayerAirMotionComponent AirMotionComp;
	UPlayerStrafeComponent StrafeComp;
	UPlayerSlideComponent SlideComp;
	USteppingMovementData Movement;

	float HorizontalVelocityInterpSpeed;

	bool bShouldSnapRotation = false;

	bool bIsMovementInputLocked = false;
	FVector2D LockedStickDirection;
	float InputLockedTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		JumpComp = UPlayerJumpComponent::GetOrCreate(Player);
		AirJumpComp = UPlayerAirJumpComponent::GetOrCreate(Player);
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
		FloorMotionComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
		StrafeComp = UPlayerStrafeComponent::GetOrCreate(Player);
		SlideComp = UPlayerSlideComponent::GetOrCreate(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// If we're still in the ascent of a jump, don't trigger air jump (the jump will buffer it)
		if(JumpComp.StartedJumpingWithinDuration(JumpComp.Settings.PostJumpAirJumpCooldown))
			return false;

		if(!MoveComp.IsInAir())
			return false;

		//Should we have a buffer time?
		if(!WasActionStarted(ActionNames::MovementJump) && !JumpComp.IsJumpBuffered())
		{
			if(!Accessibility::AutoJumpDash::ShouldAutoAirJump(Player))
				return false;
		}

		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!AirJumpComp.bCanAirJump)
			return false;

		// If we're still in the grace period for the jump, we want to trigger floor jump not air jump
		if(JumpComp.IsInJumpGracePeriod())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(MoveComp.HasGroundContact())
			return true;

		if(MoveComp.HasCeilingContact())
			return true;

		if(MoveComp.HasImpulse())
			return true;

		if(MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp) < -KINDA_SMALL_NUMBER)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Jump, this);
		Player.BlockCapabilities(BlockedWhileIn::AirJump, this);
		AirJumpComp.bCanAirJump = false;
		JumpComp.ConsumeBufferedJump();

		// Check if there are any auto-targets to jump to instead
		float BestAutoTargetScore = 0.0;
		for (auto& AutoTarget : AirJumpComp.AutoTargets)
		{
			float Score = 1.0;
			FVector TargetPoint = AutoTarget.Component.WorldTransform.TransformPosition(AutoTarget.LocalOffset);

			FVector FlatDelta = (TargetPoint - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp);
			if (FlatDelta.IsNearlyZero())
				continue;

			if (AutoTarget.bCheckFlatDistance)
			{
				float Distance = FlatDelta.Size();
				if (Distance < AutoTarget.MinFlatDistance - KINDA_SMALL_NUMBER)
					continue;
				if (Distance > AutoTarget.MaxFlatDistance)
					continue;
				Score /= Math::Max(Distance, 0.001);
			}

			if (AutoTarget.bCheckHeightDifference)
			{
				float HeightDifference = (Player.ActorLocation - TargetPoint).DotProduct(MoveComp.WorldUp);
				if (HeightDifference < AutoTarget.MinHeightDifference)
					continue;
				if (HeightDifference > AutoTarget.MaxHeightDifference)
					continue;
				Score /= Math::Max(HeightDifference, 0.001);
			}

			if (AutoTarget.bCheckInputAngle)
			{
				if (MoveComp.MovementInput.Size() < 0.1)
					continue;

				float Angle = MoveComp.MovementInput.GetAngleDegreesTo(FlatDelta);
				if (Angle > AutoTarget.MaxInputAngle)
					continue;

				Score /= Math::Max(Angle, 0.001);
			}

			// Auto target passed all the checks, apply it
			if (Score > BestAutoTargetScore)
			{
				bIsMovementInputLocked = true;
				InputLockedTimer = 0.0;
				LockedStickDirection = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

				//Debug::DrawDebugLine(Player.ActorLocation, TargetPoint, FLinearColor::Red, 10.0, 10.0);

				Player.ApplyMovementInput(FlatDelta.GetSafeNormal(), this, EInstigatePriority::High);
				BestAutoTargetScore = Score;
			}
		}

		float HorizontalTargetSpeed = AirMotionComp.Settings.HorizontalMoveSpeed + AirJumpComp.Settings.BonusHorizontalSpeed;

		// ITT movement would carry your velocity UNLESS you were giving stick input (full or majority?)
		// in which it would snap up to full horizontal velocity
		// Air control in ITT was way stronger and probably blended in much faster then this.

		FVector HorizontalVelocity;
		if(MoveComp.MovementInput.Size() <= KINDA_SMALL_NUMBER || EvaluteInputVelocityAlignment())
		{
			HorizontalVelocity = MoveComp.HorizontalVelocity;
		}
		else
		{
			HorizontalVelocity = MoveComp.MovementInput * HorizontalTargetSpeed;
			if(Player.IsStrafeEnabled() || (Player.IsAnyCapabilityActive(PlayerMovementTags::Slide) && !SlideComp.IsFreeformSlide()))
				bShouldSnapRotation = false;
			else
				bShouldSnapRotation = true;
		}

		//Add Vertical impulse
		FVector VerticalVelocity = MoveComp.WorldUp * AirJumpComp.Settings.Impulse;

		// During some launches we want to keep upward velocity even if we double jump
		if (AirJumpComp.bKeepLaunchVelocityDuringAirJumpUntilLanded
			&& Time::GameTimeSeconds < AirJumpComp.KeepLaunchVelocityUntilTime)
		{
			if (MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp) > 0)
				VerticalVelocity = MoveComp.WorldUp * Math::Max(MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp), AirJumpComp.Settings.Impulse);
		}

		AirJumpComp.bPerformedDoubleJump = true;

		Player.SetActorHorizontalAndVerticalVelocity(HorizontalVelocity, VerticalVelocity);

		UPlayerCoreMovementEffectHandler::Trigger_AirJump_Started(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// If we've just done an air jump auto target, we temporarily lock input in that direction,
		// until either we significantly change the stick direction or it times out.
		if (bIsMovementInputLocked)
		{
			InputLockedTimer += DeltaTime;

			FVector2D CurrentInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			if (InputLockedTimer > 1.0 || LockedStickDirection.Distance(CurrentInput) > 0.25 || !MoveComp.IsInAir())
			{
				bIsMovementInputLocked = false;
				Player.ClearMovementInput(this);
			}
		}
	}

	//Should we maintain our horizontal velocity or is our intent to cancel/redirect
	bool EvaluteInputVelocityAlignment()
	{
		float InputVelocityDot = MoveComp.MovementInput.DotProduct(MoveComp.HorizontalVelocity.GetSafeNormal());

		float Rad = Math::Acos(InputVelocityDot);
		float AngleDifference = Math::RadiansToDegrees(Rad);
	
		if(AngleDifference <= AirJumpComp.Settings.VelocityRedirectionAngle)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Jump, this);
		Player.UnblockCapabilities(BlockedWhileIn::AirJump, this);
		AirJumpComp.bPerformedDoubleJump = false;

		UPlayerCoreMovementEffectHandler::Trigger_AirJump_CancelledOrReachedApex(Player);
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

				if (bShouldSnapRotation && !MoveComp.HorizontalVelocity.IsNearlyZero())
				{
					Movement.SetRotation(MoveComp.HorizontalVelocity.ToOrientationQuat());
					bShouldSnapRotation = false;
				}
				else
				{
					if(Player.IsStrafeEnabled())
					{
						FRotator NewRotation = Math::RInterpConstantShortestPathTo(Owner.ActorRotation, StrafeComp.GetDefaultFacingRotation(Player) , DeltaTime, StrafeComp.Settings.FacingDirectionInterpSpeed);
						FVector RelativeVelocity = Owner.ActorTransform.InverseTransformVectorNoScale(MoveComp.HorizontalVelocity);
						StrafeComp.AnimData.BlendSpaceVector = FVector2D(RelativeVelocity.Y, RelativeVelocity.X);	
						Movement.SetRotation(NewRotation);
					}
					else
						Movement.InterpRotationToTargetFacingRotation(AirJumpComp.Settings.FacingDirectionInterpSpeed * MoveComp.MovementInput.Size());
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, Player.IsStrafeEnabled() ? n"StrafeJump" : n"Jump");
		}
	}
}