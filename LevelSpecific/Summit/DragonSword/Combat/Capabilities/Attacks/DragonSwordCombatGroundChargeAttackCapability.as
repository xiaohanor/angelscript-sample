class UDragonSwordCombatGroundChargeAttackCapability : UHazePlayerCapability
{
	// default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	// default CapabilityTags.Add(CapabilityTags::GameplayAction);

	// default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSword);

	// default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordCombat);
	// default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordAttack);
	// default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordGroundAttack);

	// default DebugCategory = SummitDebugCapabilityTags::DragonSword;

	// default TickGroup = EHazeTickGroup::ActionMovement;
	// default TickGroupOrder = 85;
	// default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 30);

	// UDragonSwordUserComponent SwordComp;
	// UDragonSwordCombatUserComponent CombatComp;

	// UPlayerTargetablesComponent TargetablesComp;
	// UPlayerMovementComponent MoveComp;
	// UCombatHitStopComponent HitStopComp;
	// USteppingMovementData Movement;
	// UDragonSwordCombatInputComponent InputComp;

	// UDragonSwordCombatTargetComponent CurrentTarget;
	// bool bHasFoundTarget = false;
	// // bool bHasSnappedTowardsTarget = false;
	// bool bHasHitTarget = false;

	// float TimeWhenReleased = MAX_flt;
	// bool bHasReleased = false;

	// float ChargeDuration = 0;

	// UFUNCTION(BlueprintOverride)
	// void Setup()
	// {
	// 	SwordComp = UDragonSwordUserComponent::Get(Owner);
	// 	CombatComp = UDragonSwordCombatUserComponent::Get(Owner);

	// 	TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
	// 	MoveComp = UPlayerMovementComponent::Get(Owner);
	// 	HitStopComp = UCombatHitStopComponent::Get(Owner);
	// 	Movement = MoveComp.SetupSteppingMovementData();
	// 	InputComp = UDragonSwordCombatInputComponent::GetOrCreate(Owner);
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldActivate() const
	// {
	// 	if (!InputComp.IsPrimaryHeld(0.1))
	// 		return false;

	// 	if (!CombatComp.CanStartNewAttack())
	// 		return false;

	// 	if (CombatComp.PendingAttackData.AttackType != EDragonSwordCombatAttackType::Charge)
	// 		return false;

	// 	return true;
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldDeactivate() const
	// {
	// 	if (!CombatComp.IsActiveAttackType(EDragonSwordCombatAttackType::Charge))
	// 		return true;

	// 	if (!CombatComp.GetHitUnderPlayer(DragonSwordCombat::GroundAttackDistanceThreshold).bBlockingHit)
	// 		return true;

	// 	float TimeSinceRelease = Time::GetGameTimeSince(TimeWhenReleased);
	// 	if (TimeSinceRelease > CombatComp.ActiveAttackData.AnimationData.PlayLength)
	// 		return true;

	// 	// if (CombatComp.HasPendingAttack())
	// 	// {
	// 	// 	if (CombatComp.bInsideComboWindow)
	// 	// 		return true;
	// 	// }

	// 	if (CombatComp.bInsideSettleWindow && CombatComp.ShouldExitSettle())
	// 		return true;

	// 	return false;
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnActivated()
	// {
	// 	bHasFoundTarget = false;
	// 	bHasHitTarget = false;

	// 	bHasReleased = !InputComp.IsPrimaryHeld();
	// 	TimeWhenReleased = MAX_flt;
	// 	if (bHasReleased)
	// 		TimeWhenReleased = InputComp.GetPrimaryHoldEndTime();

	// 	CombatComp.SetActiveAttackData(CombatComp.PendingAttackData, this);
	// 	CombatComp.StartAttackAnimation();
	// 	CombatComp.bIsHoldingChargeAttack = true;
	// 	ChargeDuration = 0;
	// 	Player.AddDamageInvulnerability(this, 0.4);
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnDeactivated()
	// {
	// 	// Reset current combo when attack finishes
	// 	if (CombatComp.HasActiveAttack() && CombatComp.ActiveAttackInstigator == this)
	// 		CombatComp.StopActiveAttackData(this);
	// }

	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {
	// 	if (MoveComp.PrepareMove(Movement))
	// 	{
	// 		if (HasControl())
	// 		{
	// 			if (!bHasReleased && InputComp.WasPrimaryReleased())
	// 			{
	// 				TimeWhenReleased = InputComp.GetPrimaryHoldEndTime();
	// 				bHasReleased = true;
	// 				CombatComp.bIsHoldingChargeAttack = false;
	// 			}

	// 			ChargeDuration = ActiveDuration;
	// 			float Quotient = Math::TruncToFloat(ChargeDuration / DragonSwordChargeAttack::HitRangeModifierUpdateInterval);
	// 			float Modifier = Quotient * DragonSwordChargeAttack::HitRangeModifierUpdateInterval;
	// 			float DistanceModifier = 1 + Math::Clamp(Modifier, 0, DragonSwordChargeAttack::HitRangeModifierMax);

	// 			if (bHasReleased && CombatComp.bInsideHitWindow)
	// 			{
	// 				bool bSuccessFulHit = CombatComp.TryAttack(DragonSwordCombat::HitRange * DistanceModifier);
	// 				if (bSuccessFulHit)
	// 					bHasHitTarget = true;
	// 			}
	// 			Movement.AddOwnerVerticalVelocity();
	// 			Movement.AddGravityAcceleration();
	// 		}
	// 		else
	// 		{
	// 			Movement.ApplyCrumbSyncedGroundMovement();
	// 		}
	// 		MoveComp.ApplyMoveAndRequestLocomotion(Movement, DragonSwordCombat::Feature);
	// 	}

	// 	SwordComp.PreviousSwordLocation = SwordComp.Weapon.ActorCenterLocation;
	// }
}