class UDragonSwordCombatAirAttackGroundPoundCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSword);
	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordCombat);

	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordAttack);
	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordAirAttack);

	default InterruptsCapabilities(DragonSwordCapabilityTags::DragonSwordGroundAttack);
	default InterruptsCapabilities(DragonSwordCapabilityTags::DragonSwordDashAttack);

	default DebugCategory = SummitDebugCapabilityTags::DragonSword;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 85;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 30);

	UDragonSwordUserComponent SwordComp;
	UDragonSwordCombatUserComponent CombatComp;

	UPlayerTargetablesComponent TargetablesComp;
	UPlayerMovementComponent MoveComp;
	UCombatHitStopComponent HitStopComp;
	USweepingMovementData Movement;
	FVector ForwardVector;

	bool bWasInAir = true;
	bool bHasStartedFalling = false;
	float TimeWhenHitGround = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwordComp = UDragonSwordUserComponent::Get(Owner);
		CombatComp = UDragonSwordCombatUserComponent::Get(Owner);

		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
		HitStopComp = UCombatHitStopComponent::Get(Owner);
		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!CombatComp.CanStartNewAttack())
			return false;

		if (CombatComp.PendingAttackData.AttackType != EDragonSwordCombatAttackType::Air)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CombatComp.IsActiveAttackType(EDragonSwordCombatAttackType::Air))
			return true;

		if (!bWasInAir && Time::GetGameTimeSince(TimeWhenHitGround) > DragonSwordAirAttack::AirGroundExitDuration)
		{
			return true;
		}

		if (CombatComp.HasPendingAttack())
		{
			if (CombatComp.bInsideComboWindow)
				return true;
		}

		if (CombatComp.bInsideSettleWindow && CombatComp.ShouldExitSettle())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CombatComp.SetActiveAttackData(CombatComp.PendingAttackData, this);
		CombatComp.StartAttackAnimation();

		bWasInAir = true;
		bHasStartedFalling = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Reset current combo when attack finishes
		if (CombatComp.HasActiveAttack() && CombatComp.ActiveAttackInstigator == this)
			CombatComp.StopActiveAttackData(this);

		if (IsBlocked())
			CombatComp.UnblockMovement();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		bool bIsInAir = MoveComp.IsInAir();
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				// Movement.AddDelta(DeltaMovement);
				if (ActiveDuration >= DragonSwordAirAttack::AirHangDuration)
				{
					if (!bHasStartedFalling)
					{
						Movement.AddVelocity(MoveComp.GravityDirection * DragonSwordAirAttack::AirFallInitialSpeed);
						bHasStartedFalling = true;
					}
					else
					{
						Movement.AddOwnerVerticalVelocity();
						Movement.AddAcceleration(MoveComp.GravityDirection * DragonSwordAirAttack::AirFallSpeedAcceleration);
					}
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, DragonSwordCombat::Feature);
		}

		if (!bIsInAir && bWasInAir)
		{
			TimeWhenHitGround = Time::GameTimeSeconds;
			bWasInAir = false;
			Player.PlayForceFeedback(CombatComp.GroundPoundForceFeedback, false, true, this, 1);
		}

		if (HasControl())
		{
			if (!bIsInAir)
			{
				CombatComp.TryAttack();
			}
		}
	}
}