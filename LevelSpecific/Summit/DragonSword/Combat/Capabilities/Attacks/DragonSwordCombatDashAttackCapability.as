class UDragonSwordCombatDashAttackCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSword);

	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordCombat);
	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordAttack);
	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordDashAttack);

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

	float StartVelocity;
	FVector ForwardVector;
	FVector AccumulatedTranslation;
	float TotalMovementLength;

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

		if (CombatComp.PendingAttackData.AttackType != EDragonSwordCombatAttackType::Dash)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CombatComp.IsActiveAttackType(EDragonSwordCombatAttackType::Dash))
			return true;

		if (ActiveDuration > CombatComp.ActiveAttackData.AnimationData.PlayLength)
			return true;

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
		Player.BlockCapabilities(PlayerMovementTags::Dash, this);

		if (HasControl())
		{
			CombatComp.bIsAirDash = MoveComp.IsInAir();
			StartVelocity = MoveComp.Velocity.Size() * .75;
			AccumulatedTranslation = FVector::ZeroVector;
			// Get forward vector after turning towards movement direction
			//  then use our new forward to find suction target
			ForwardVector = CombatComp.GetMovementDirection(Player.ActorForwardVector);
			TotalMovementLength = CombatComp.ActiveAttackData.AnimationData.AttackData.MovementLength;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(PlayerMovementTags::Dash, this);
		// Reset current combo when attack finishes
		if (CombatComp.HasActiveAttack() && CombatComp.ActiveAttackInstigator == this)
			CombatComp.StopActiveAttackData(this);

		if (IsBlocked())
			CombatComp.UnblockMovement();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector RootMovement = SwordComp.GetRootMotion(AccumulatedTranslation, ActiveDuration, TotalMovementLength, CombatComp.ActiveAttackData.AnimationData.PlayLength);

				FQuat TargetRotation = FQuat::MakeFromZX(Player.MovementWorldUp, ForwardVector);
				FQuat NewRotation = FQuat::Slerp(Player.ActorQuat, TargetRotation, 12.0 * DeltaTime);
				FVector DeltaMovement = TargetRotation.RotateVector(RootMovement);

				DeltaMovement = DeltaMovement.VectorPlaneProject(MoveComp.WorldUp);

				if (StartVelocity > KINDA_SMALL_NUMBER)
				{
					StartVelocity -= (StartVelocity * 3.0 * DeltaTime);
					Movement.AddVelocity(ForwardVector * StartVelocity);
				}

				Movement.AddDelta(DeltaMovement);
				Movement.SetRotation(NewRotation);
				Movement.AddGravityAcceleration();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, DragonSwordCombat::Feature);
		}

		if (HasControl())
		{
			if (CombatComp.bInsideHitWindow)
				CombatComp.TryAttack();
		}
	}
}