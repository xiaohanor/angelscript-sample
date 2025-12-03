enum EDragonSwordCombatEvaluateRushResult
{
	NoTarget,
	Regular,
	Rush
}

class UDragonSwordCombatAttackActivationCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSword);

	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordCombat);
	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordAttackActivation);

	default DebugCategory = SummitDebugCapabilityTags::DragonSword;

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 110;

	UDragonSwordCombatUserComponent CombatComp;
	UDragonSwordUserComponent SwordComp;
	UPlayerTargetablesComponent TargetablesComp;
	UPlayerMovementComponent MoveComp;
	UDragonSwordCombatInputComponent InputComp;

	float LastDashTime = -BIG_NUMBER;

	bool bShouldUseTargeting = true;

	bool bIsWithinGroundThreshold = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CombatComp = UDragonSwordCombatUserComponent::Get(Owner);
		SwordComp = UDragonSwordUserComponent::Get(Owner);
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
		InputComp = UDragonSwordCombatInputComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDragonSwordCombatAttackData& PendingAttackData) const
	{
		if (!SwordComp.IsWeaponEquipped())
			return false;

		if (!CombatComp.HasSword())
			return false;

		if (CombatComp.HasPendingAttack())
			return false;

		if (CombatComp.HasActiveAttack())
		{
			// Only allow activation if we are inside a combo window
			if (!CombatComp.bInsideComboWindow)
				return false;
		}

		if (!InputComp.WasPrimaryPressed())
			return false;


		// bool bIsPressAttack = InputComp.WasPrimaryPressed() && !InputComp.IsPrimaryHeld();
		// bool bIsChargeAttack = !bIsPressAttack && InputComp.IsPrimaryHeld();
		// if (!bIsPressAttack && !bIsChargeAttack)
		// 	return false;

		FDragonSwordCombatAttackTypeData AttackTypeData = GetBaseAttackType();

		// // Only allow holding button when doing charge or air attack
		// if (!(AttackTypeData.IsCharge() || AttackTypeData.IsAir()) && bIsChargeAttack)
		// 	return false;

		// bool bIsChargingInPlace = bIsChargeAttack && !MoveComp.IsMoving();
		// if (AttackTypeData.IsCharge() && !bIsChargingInPlace)
		// 	return false;

		check(AttackTypeData.IsValid());

		if (AttackTypeData.IsAir() && bIsWithinGroundThreshold)
			return false;

		bool bHasTarget = false;

		FDragonSwordCombatAttackAnimationData AttackAnimation;
		if (!GetAttackAnimation(AttackTypeData, AttackAnimation))
			return false;

		PendingAttackData = FDragonSwordCombatAttackData(AttackTypeData, AttackAnimation);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDragonSwordCombatAttackData PendingAttackData)
	{
		LastDashTime = -BIG_NUMBER;
		CombatComp.SetPendingAttackData(PendingAttackData);
		CombatComp.DesiredFacingDirection = CombatComp.GetMovementDirection(Player.ActorForwardVector);
		CombatComp.ActivationMovementInput = MoveComp.MovementInput;

		Player.PlayForceFeedback(CombatComp.SwingForceFeedback, false, false, this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (CombatComp.IsDashing() || CombatComp.IsAirDashing())
			LastDashTime = Time::GameTimeSeconds;

		bIsWithinGroundThreshold = CombatComp.GetHitUnderPlayer(DragonSwordCombat::GroundAttackDistanceThreshold).bBlockingHit;
	}

	private FDragonSwordCombatAttackTypeData GetBaseAttackType() const
	{
		if (!MoveComp.IsInAir() || bIsWithinGroundThreshold)
		{
			// If we are dashing, or most recent attack was dash, keep dashing
			// Only use these windows if we have recently pressed, ignore if holding
			if (InputComp.WasPrimaryPressed())
			{
				if (IsInDashGracePeriod() || (CombatComp.HasActiveCombo() && CombatComp.ComboData.MostRecentAttackType.IsDash() && CombatComp.ComboData.CanContinueCombo(EDragonSwordCombatAttackType::Dash)))
					return FDragonSwordCombatAttackTypeData(EDragonSwordAttackMovementType::Dash);
			}
		}

		switch (CombatComp.GetCurrentMovementType())
		{
			case EDragonSwordAttackMovementType::Air:
				return FDragonSwordCombatAttackTypeData(EDragonSwordCombatAttackType::Air);

			case EDragonSwordAttackMovementType::Ground:
			{
				if (CombatComp.HasActiveCombo() && CombatComp.ComboData.MostRecentAttackType.IsSprint() && CombatComp.ComboData.CanContinueCombo(EDragonSwordCombatAttackType::Sprint))
					return FDragonSwordCombatAttackTypeData(EDragonSwordAttackMovementType::Sprint);
				else
					return FDragonSwordCombatAttackTypeData(EDragonSwordCombatAttackType::Ground);
			}
			case EDragonSwordAttackMovementType::Dash:
				return FDragonSwordCombatAttackTypeData(EDragonSwordAttackMovementType::Dash);

			case EDragonSwordAttackMovementType::Sprint:
				return FDragonSwordCombatAttackTypeData(EDragonSwordCombatAttackType::Sprint);

			case EDragonSwordAttackMovementType::Charge:
				return FDragonSwordCombatAttackTypeData(EDragonSwordCombatAttackType::Charge);

			case EDragonSwordAttackMovementType::StillAttack:
				return FDragonSwordCombatAttackTypeData();

			default:
				check(false); // Unhandled movement type
				break;
		}

		return FDragonSwordCombatAttackTypeData();
	}

	private bool GetAttackAnimation(FDragonSwordCombatAttackTypeData AttackTypeData, FDragonSwordCombatAttackAnimationData&out AttackAnimation) const
	{
		if (CombatComp.HasActiveCombo())
		{
			EDragonSwordCombatAttackType ComboAttackType;
			int ComboAttackIndex;
			int SequenceIndex;
			if (!CombatComp.ComboData.CanContinueCombo(AttackTypeData,  ComboAttackType, ComboAttackIndex, SequenceIndex))
				return false;

			if (ComboAttackType == EDragonSwordCombatAttackType::INVALID)
			{
				return false;
			}
			else
			{
				FDragonSwordAttackSequenceData Sequence = CombatComp.AnimFeature.GetSequenceFromAttackType(ComboAttackType, SequenceIndex);
				AttackAnimation = FDragonSwordCombatAttackAnimationData(Sequence, ComboAttackIndex, SequenceIndex);
			}
		}
		else
		{
			int AttackIndex = 0;

			// This is the first attack
			int SequenceIndex = CombatComp.ProgressToNextSequenceForType(AttackTypeData.GetMovementType());

			CombatComp.GetAttackAnimationData(AttackTypeData.ToType(), SequenceIndex, AttackIndex, AttackAnimation);
		}

		return true;
	}

	private EDragonSwordCombatEvaluateRushResult EvaluateRushConditions(UDragonSwordCombatTargetComponent InTarget, FDragonSwordCombatAttackTypeData InAttackTypeData) const
	{
		FVector Horizontal = InTarget.WorldLocation - Player.ActorLocation;
		Horizontal = Horizontal.VectorPlaneProject(Player.MovementWorldUp);
		float HorizontalDistance = Horizontal.Size();

		if (HorizontalDistance < DragonSwordCombat::RushDistanceThreshold)
		{
			return EDragonSwordCombatEvaluateRushResult::Regular;
		}
		else if (HorizontalDistance > DragonSwordCombat::MaxRushDistance)
		{
			return EDragonSwordCombatEvaluateRushResult::NoTarget;
		}
		else if (!InTarget.bCanRushTowards)
		{
			// We are within rush distance, but are not allowed to rush
			return EDragonSwordCombatEvaluateRushResult::Regular;
		}

		switch (InAttackTypeData.GetMovementType())
		{
			case EDragonSwordAttackMovementType::Air:
			{
				return EvaluateAirRush(InTarget);
			}

			case EDragonSwordAttackMovementType::Ground:
			case EDragonSwordAttackMovementType::Sprint:
			{
				return EvaluateGroundRush(InTarget);
			}

			case EDragonSwordAttackMovementType::Dash:
			{
				if (MoveComp.IsInAir())
					return EvaluateAirRush(InTarget);
				else
					return EvaluateGroundRush(InTarget);
			}
			default:
				break;
		}

		check(false);
		return EDragonSwordCombatEvaluateRushResult::NoTarget;
	}

	private EDragonSwordCombatEvaluateRushResult EvaluateAirRush(UDragonSwordCombatTargetComponent InTarget) const
	{
		if (CombatComp.HasActiveCombo())
		{
			// Don't rush after air rushes
			if (CombatComp.ComboData.HasAttack(EDragonSwordCombatAttackType::AirRush))
				return EDragonSwordCombatEvaluateRushResult::NoTarget;

			// Don't rush after air dash rush
			if (CombatComp.ComboData.HasAttack(EDragonSwordAttackMovementType::Dash) && CombatComp.bIsAirDash)
				return EDragonSwordCombatEvaluateRushResult::NoTarget;
		}

		FPlane GroundPlane(CombatComp.LastGroundedLocation, Player.MovementWorldUp);
		if (GroundPlane.PlaneDot(InTarget.WorldLocation) > 0)
		{
			FVector TargetOnGroundPlane = InTarget.WorldLocation.PointPlaneProject(GroundPlane.Origin, GroundPlane.Normal);
			float TargetVerticalDistance = TargetOnGroundPlane.Distance(InTarget.WorldLocation);

			if (TargetVerticalDistance > DragonSwordCombat::AirRushMaxHeight)
				return EDragonSwordCombatEvaluateRushResult::NoTarget;
			else
				return EDragonSwordCombatEvaluateRushResult::Rush;
		}
		else
		{
			return EDragonSwordCombatEvaluateRushResult::Rush;
		}
	}

	private EDragonSwordCombatEvaluateRushResult EvaluateGroundRush(UDragonSwordCombatTargetComponent InTarget) const
	{
		FPlane GroundPlane(Player.ActorLocation, Player.MovementWorldUp);
		FVector TargetOnGroundPlane = InTarget.WorldLocation.PointPlaneProject(GroundPlane.Origin, GroundPlane.Normal);
		float TargetVerticalDistance = TargetOnGroundPlane.Distance(InTarget.WorldLocation);

		if (TargetVerticalDistance > 200)
			return EDragonSwordCombatEvaluateRushResult::NoTarget;

		return EDragonSwordCombatEvaluateRushResult::Rush;
	}

	bool IsInDashGracePeriod() const
	{
		if (WasActionStarted(ActionNames::MovementDash))
			return true;

		return LastDashTime + DragonSwordCombat::DashGraceTime > Time::GameTimeSeconds;
	}
}