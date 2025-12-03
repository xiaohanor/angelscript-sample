enum EGravityBladeCombatEvaluateRushResult
{
	NoTarget,
	Regular,
	Rush
}

class UGravityBladeCombatAttackActivationCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(GravityBladeTags::GravityBlade);
	default CapabilityTags.Add(GravityBladeTags::GravityBladeWield);
	
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeCombat);
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeAttackActivation);

	// Contextual move blocks
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::GrappleEnter);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::LedgeMantle);
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Skydive);
	default CapabilityTags.Add(BlockedWhileIn::Slide);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::Vault);
	default CapabilityTags.Add(BlockedWhileIn::WallRun);
	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);

	default DebugCategory = GravityBlade::DebugCategory;

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 110;

	UGravityBladeCombatUserComponent CombatComp;
	UGravityBladeUserComponent BladeComp;
	UPlayerTargetablesComponent TargetablesComp;
	UPlayerMovementComponent MoveComp;

	// Whether our air attack has been consumed. Resets when grounded.
	bool bAirAttackConsumed = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CombatComp = UGravityBladeCombatUserComponent::Get(Owner);
		BladeComp = UGravityBladeUserComponent::Get(Owner);
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBladeCombatAttackData& PendingAttackData) const
	{
		if(!BladeComp.IsBladeEquipped())
			return false;

		if(CombatComp.HasPendingAttack())
			return false;

		if(!CombatComp.WasPrimaryPressed())
			return false;

		if(CombatComp.HasActiveAttack())
		{
			// Only allow activation if we are inside a combo window
			if (!CombatComp.bInsideComboWindow)
				return false;
			if (!CombatComp.HasRemainingAttacksInCombo() && !CombatComp.bInsideSettleWindow)
				return false;
			if (CombatComp.ActiveAttackData.MovementType == EGravityBladeAttackMovementType::OpportunityAttack)
				return false;
		}

		auto Target = Cast<UGravityBladeCombatTargetComponent>(TargetablesComp.GetPrimaryTargetForCategory(GravityBladeCombat::TargetableCategory));

		EGravityBladeAttackMovementType MovementType;
		EGravityBladeAttackAnimationType AnimationType;
		if (!GetAttackType(MovementType, AnimationType, Target))
			return false;

		FGravityBladeCombatAttackAnimationData AttackAnimation;
		bool bHasTarget = Target != nullptr;
		if(!GetAttackAnimation(MovementType, AnimationType, bHasTarget, AttackAnimation))
			return false;

		PendingAttackData = FGravityBladeCombatAttackData(MovementType, AnimationType, Target, AttackAnimation);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBladeCombatAttackData PendingAttackData)
	{
		CombatComp.SetPendingAttackData(PendingAttackData);
		CombatComp.PrimaryHoldStartTime = 0;
		CombatComp.PrimaryHoldEndTime = 0;

		if (MoveComp.IsInAir())
			bAirAttackConsumed = true;
	}

	private bool GetAttackType(
		EGravityBladeAttackMovementType&out MovementType,
		EGravityBladeAttackAnimationType&out AnimationType,
		UGravityBladeCombatTargetComponent Target,
	) const
	{
		UGravityBladeCombatInteractionResponseComponent InteractionResponseComp;
		UGravityBladeOpportunityAttackTargetComponent OpportunityAttackTarget;

		if (Target != nullptr)
		{
			InteractionResponseComp = UGravityBladeCombatInteractionResponseComponent::Get(Target.Owner);
			OpportunityAttackTarget = UGravityBladeOpportunityAttackTargetComponent::Get(Target.Owner);
		}

		if (OpportunityAttackTarget != nullptr && OpportunityAttackTarget.IsOpportunityAttackEnabled())
		{
			MovementType = EGravityBladeAttackMovementType::OpportunityAttack;
			AnimationType = EGravityBladeAttackAnimationType::GroundAttack;
			return true;
		}

		// Interaction attacks should always use their special sequences
		if (InteractionResponseComp != nullptr && InteractionResponseComp.InteractionType != EGravityBladeCombatInteractionType::None)
		{
			if (MoveComp.IsInAir())
				MovementType = EGravityBladeAttackMovementType::Air;
			else
				MovementType = EGravityBladeAttackMovementType::Ground;

			switch (InteractionResponseComp.InteractionType)
			{
				case EGravityBladeCombatInteractionType::LadderKick:
					if (MoveComp.IsInAir())
						AnimationType = EGravityBladeAttackAnimationType::Interaction_Air_LadderKick;
					else
						AnimationType = EGravityBladeAttackAnimationType::Interaction_Ground_LadderKick;
				break;
				case EGravityBladeCombatInteractionType::LockBreak:
					if (MoveComp.IsInAir())
						AnimationType = EGravityBladeAttackAnimationType::Interaction_Air_Uppercut;
					else
						AnimationType = EGravityBladeAttackAnimationType::Interaction_Ground_Uppercut;
				break;
				case EGravityBladeCombatInteractionType::VerticalUp:
					if (MoveComp.IsInAir())
						AnimationType = EGravityBladeAttackAnimationType::Interaction_Air_Vertical_Up;
					else
						AnimationType = EGravityBladeAttackAnimationType::Interaction_Ground_Vertical_Up;
				break;
				case EGravityBladeCombatInteractionType::VerticalDown:
					if (MoveComp.IsInAir())
						AnimationType = EGravityBladeAttackAnimationType::	Interaction_Air_Vertical_Down;
					else
						AnimationType = EGravityBladeAttackAnimationType::Interaction_Ground_Vertical_Down;
				break;
				case EGravityBladeCombatInteractionType::VerticalHigh:
					if (MoveComp.IsInAir())
						AnimationType = EGravityBladeAttackAnimationType::	Interaction_Air_Vertical_Down;
					else
						AnimationType = EGravityBladeAttackAnimationType::Interaction_Ground_Vertical_Down;
				break;
				case EGravityBladeCombatInteractionType::HorizontalLeft:
					if (MoveComp.IsInAir())
						AnimationType = EGravityBladeAttackAnimationType::Interaction_Air_Horizontal_Left;
					else
						AnimationType = EGravityBladeAttackAnimationType::Interaction_Ground_Horizontal_Left;
				break;
				case EGravityBladeCombatInteractionType::HorizontalRight:
					if (MoveComp.IsInAir())
						AnimationType = EGravityBladeAttackAnimationType::Interaction_Air_Horizontal_Right;
					else
						AnimationType = EGravityBladeAttackAnimationType::Interaction_Ground_Horizontal_Right;
				break;

				case EGravityBladeCombatInteractionType::Uppercut:
					if (MoveComp.IsInAir())
						AnimationType = EGravityBladeAttackAnimationType::Interaction_Air_Uppercut;
					else
						AnimationType = EGravityBladeAttackAnimationType::Interaction_Ground_Uppercut;
				break;
				case EGravityBladeCombatInteractionType::DiagonalUpRight:
					if (MoveComp.IsInAir())
						AnimationType = EGravityBladeAttackAnimationType::Interaction_Air_Diagonal_UpRight;
					else
						AnimationType = EGravityBladeAttackAnimationType::Interaction_Ground_Diagonal_UpRight;
				break;
				case EGravityBladeCombatInteractionType::HorizontalSwing:
					if (MoveComp.IsInAir())
						AnimationType = EGravityBladeAttackAnimationType::Interaction_Air_Horizontal_Swing;
					else
						AnimationType = EGravityBladeAttackAnimationType::Interaction_Ground_Horizontal_Swing;
				break;
				case EGravityBladeCombatInteractionType::BallBossSwing:
					if (MoveComp.IsInAir())
						AnimationType = EGravityBladeAttackAnimationType::Interaction_Air_BallBoss_Swing;
					else
						AnimationType = EGravityBladeAttackAnimationType::Interaction_Ground_BallBoss_Swing;
				break;
				case EGravityBladeCombatInteractionType::None:
				break;
			}

			return true;
		}

		// Switch to air attacks when in air
		if (MoveComp.IsInAir())
		{
			if (bAirAttackConsumed)
			{
				if (!CombatComp.bHasActiveCombo)
					return false;
				if (CombatComp.IsComboOnLastAttackOfSequence())
					return false;
			}

			// Allow an air slam attack if the target is right below us
			if (Target != nullptr)
			{
				FVector TopOfTarget = Target.Owner.ActorLocation;

				AHazeCharacter CharacterTarget = Cast<AHazeCharacter>(Target.Owner);
				if (CharacterTarget != nullptr)
					TopOfTarget = CharacterTarget.CapsuleComponent.WorldLocation + CharacterTarget.CapsuleComponent.UpVector * CharacterTarget.CapsuleComponent.ScaledCapsuleHalfHeight;

				FVector DeltaToTarget = TopOfTarget - Player.ActorLocation;
				float VerticalDistance = DeltaToTarget.DotProduct(MoveComp.WorldUp);
				float HorizontalDistance = DeltaToTarget.ConstrainToPlane(MoveComp.WorldUp).Size();

	 			if (VerticalDistance <= -GravityBladeCombat::AirSlamMinimumHeightDifference
					&& HorizontalDistance <= GravityBladeCombat::AirSlamMaximumDistance)
				{
					MovementType = EGravityBladeAttackMovementType::AirSlam;
					AnimationType = EGravityBladeAttackAnimationType::AirSlamAttack;
					return true;
				}
			}

			// If we just did a dash, use the dash attacks
			if (CombatComp.DashedRecently())
			{
				if (CombatComp.MostRecentDashType == EGravityBladeCombatDashType::AirDash)
				{
					MovementType = EGravityBladeAttackMovementType::AirHover;
					AnimationType = EGravityBladeAttackAnimationType::AirDashAttack;
					return true;
				}
				else if (CombatComp.MostRecentDashType == EGravityBladeCombatDashType::RollDashJump)
				{
					MovementType = EGravityBladeAttackMovementType::Air;
					AnimationType = EGravityBladeAttackAnimationType::RollDashJumpAttack;
					return true;
				}
			}

			// Allow continuing air dash combos
			if (CombatComp.bHasActiveCombo && CombatComp.ActiveComboType == EGravityBladeAttackAnimationType::AirDashAttack && !CombatComp.IsComboOnLastAttackOfSequence())
			{
				MovementType = EGravityBladeAttackMovementType::AirHover;
				AnimationType = EGravityBladeAttackAnimationType::AirDashAttack;
				return true;
			}

			// Allow continuing roll dash jump combos
			if (CombatComp.bHasActiveCombo && CombatComp.ActiveComboType == EGravityBladeAttackAnimationType::RollDashJumpAttack && !CombatComp.IsComboOnLastAttackOfSequence())
			{
				MovementType = EGravityBladeAttackMovementType::Air;
				AnimationType = EGravityBladeAttackAnimationType::RollDashJumpAttack;
				return true;
			}

			MovementType = EGravityBladeAttackMovementType::Air;
			AnimationType = EGravityBladeAttackAnimationType::AirAttack;

			// Allow continuing air rush combo here
			if (CombatComp.bHasActiveCombo && CombatComp.ActiveComboType == EGravityBladeAttackAnimationType::AirRushAttack && !CombatComp.IsComboOnLastAttackOfSequence())
				AnimationType = EGravityBladeAttackAnimationType::AirRushAttack;

			return true;
		}
		else
		{
			// If we just did a dash, use the dash attacks
			if (CombatComp.DashedRecently() && CombatComp.MostRecentDashType != EGravityBladeCombatDashType::AirDash)
			{
				MovementType = EGravityBladeAttackMovementType::Ground;

				if (MoveComp.MovementInput.DotProduct(CombatComp.MostRecentDashDirection) < 0)
					AnimationType = EGravityBladeAttackAnimationType::DashTurnaroundAttack;
				else if (CombatComp.MostRecentDashType == EGravityBladeCombatDashType::RollDash)
					AnimationType = EGravityBladeAttackAnimationType::RollDashAttack;
				else
					AnimationType = EGravityBladeAttackAnimationType::DashAttack;

				return true;
			}

			// Continue with sprinting attacks until the combo is done
			if (CombatComp.IsSprinting() || (CombatComp.bHasActiveCombo && CombatComp.ActiveComboType == EGravityBladeAttackAnimationType::SprintAttack && !CombatComp.IsComboOnLastAttackOfSequence()))
			{
				MovementType = EGravityBladeAttackMovementType::Ground;
				AnimationType = EGravityBladeAttackAnimationType::SprintAttack;
				return true;
			}

			// Fall back to normal ground attacks
			MovementType = EGravityBladeAttackMovementType::Ground;
			AnimationType = EGravityBladeAttackAnimationType::GroundAttack;

			if (CombatComp.bHasActiveCombo && !CombatComp.IsComboOnLastAttackOfSequence())
			{
				// Allow continuing ground rush combo here
				if (CombatComp.ActiveComboType == EGravityBladeAttackAnimationType::GroundRushAttack)
					AnimationType = EGravityBladeAttackAnimationType::GroundRushAttack;

				// Allow continuing dash combos
				if (CombatComp.ActiveComboType == EGravityBladeAttackAnimationType::DashAttack)
					AnimationType = EGravityBladeAttackAnimationType::DashAttack;

				// Allow continuing dash combos
				if (CombatComp.ActiveComboType == EGravityBladeAttackAnimationType::DashTurnaroundAttack)
					AnimationType = EGravityBladeAttackAnimationType::DashTurnaroundAttack;

				// Allow continuing roll dash combos
				if (CombatComp.ActiveComboType == EGravityBladeAttackAnimationType::RollDashAttack)
					AnimationType = EGravityBladeAttackAnimationType::RollDashAttack;
			}

			return true;
		}
	}

	private bool GetAttackAnimation(
		EGravityBladeAttackMovementType MovementType,
		EGravityBladeAttackAnimationType AnimationType,
		bool bHasTarget,
		FGravityBladeCombatAttackAnimationData&out AttackAnimation
	) const
	{
		int AttackIndex = -1;
		int SequenceIndex = -1;
		if (CombatComp.bHasActiveCombo && CombatComp.ActiveComboType == AnimationType && CombatComp.HasRemainingAttacksInCombo())
		{
			// We still have attacks remaining in our current combo
			AttackIndex = CombatComp.ActiveComboAttackIndex + 1;
			SequenceIndex = CombatComp.ActiveComboSequenceIndex;
		}

		// If the attack or sequence isn't valid anymore, start a new sequence
		if (!CombatComp.IsAttackIndexValid(AnimationType, SequenceIndex, AttackIndex))
		{
			AttackIndex = 0;
			SequenceIndex = CombatComp.GetNextSequenceIndexForType(AnimationType);
		}

		return CombatComp.GetAttackAnimationData(AnimationType, SequenceIndex, AttackIndex, AttackAnimation);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (MoveComp.IsOnWalkableGround())
			bAirAttackConsumed = false;
	}
}