class UDragonSwordCombatGroundChargeAttackBoomerangCapability : UHazePlayerCapability
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
	// USteppingMovementData Movement;
	// UDragonSwordCombatInputComponent InputComp;

	// UDragonSwordCombatTargetComponent CurrentTarget;
	// bool bHasFoundTarget = false;
	// // bool bHasSnappedTowardsTarget = false;
	// bool bHasHitTarget = false;

	// float TimeWhenReleased = MAX_flt;
	// bool bHasReleased = false;

	// bool bHasThrownBoomerang = false;

	// float ChargeDuration = 0;

	// uint NumSpawnedBoomerangs = 0;

	// UFUNCTION(BlueprintOverride)
	// void Setup()
	// {
	// 	SwordComp = UDragonSwordUserComponent::Get(Owner);
	// 	CombatComp = UDragonSwordCombatUserComponent::Get(Owner);

	// 	TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
	// 	MoveComp = UPlayerMovementComponent::Get(Owner);
	// 	Movement = MoveComp.SetupSteppingMovementData();
	// 	InputComp = UDragonSwordCombatInputComponent::GetOrCreate(Owner);
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldActivate() const
	// {
	// 	if (!CombatComp.CanStartNewAttack())
	// 		return false;

	// 	if (CombatComp.PendingAttackData.AttackType != EDragonSwordCombatAttackType::Charge)
	// 		return false;

	// 	return true;
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldDeactivate() const
	// {
	// 	if (bHasThrownBoomerang)
	// 		return true;

	// 	return false;
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnActivated()
	// {
	// 	bHasFoundTarget = false;
	// 	bHasHitTarget = false;
	// 	bHasThrownBoomerang = false;

	// 	bHasReleased = !InputComp.IsSecondaryHeld();
	// 	TimeWhenReleased = MAX_flt;
	// 	if (bHasReleased)
	// 		TimeWhenReleased = InputComp.GetSecondaryHoldEndTime();

	// 	CombatComp.SetActiveAttackData(CombatComp.PendingAttackData, this);
	// 	CombatComp.StartAttackAnimation();
	// 	ChargeDuration = 0;
	// 	// CombatComp.BlockMovement();
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnDeactivated()
	// {
	// 	// Reset current combo when attack finishes
	// 	if (CombatComp.HasActiveAttack() && CombatComp.ActiveAttackInstigator == this)
	// 		CombatComp.StopActiveAttackData(this);

	// 	// CombatComp.UnblockMovement();
	// }

	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {
	// 	if (MoveComp.PrepareMove(Movement))
	// 	{
	// 		if (HasControl())
	// 		{
	// 			if (!bHasReleased && InputComp.WasSecondaryReleased())
	// 			{
	// 				TimeWhenReleased = InputComp.GetSecondaryHoldEndTime();
	// 				bHasReleased = true;
	// 			}

	// 			if (bHasReleased && !bHasThrownBoomerang)
	// 			{
	// 				bHasThrownBoomerang = true;

	// 				ChargeDuration = Math::Max(InputComp.GetSecondaryHoldTime(), InputComp.GetSecondaryPreviousHoldTime());
	// 				// float Quotient = Math::TruncToFloat(ChargeDuration / DragonSwordBoomerang::DistanceModifierUpdateInterval);
	// 				// float Modifier = Quotient * DragonSwordBoomerang::DistanceModifierUpdateInterval;
	// 				float DistanceModifier = 1;

	// 				FVector TargetLocation = Player.ActorCenterLocation + Player.ActorForwardVector * DragonSwordBoomerang::MinThrowDistance * DistanceModifier;
	// 				CrumbSpawnBoomerang(Player.ActorCenterLocation, TargetLocation);
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

	// UFUNCTION(CrumbFunction)
	// void CrumbSpawnBoomerang(FVector SpawnLocation, FVector TargetLocation)
	// {
	// 	auto BoomerangInstance = SpawnActor(CombatComp.BoomerangClass, SpawnLocation, FRotator::MakeFromZX(Player.ActorForwardVector, Player.ActorUpVector), NAME_None, true);

	// 	BoomerangInstance.Setup(Player, TargetLocation);
	// 	BoomerangInstance.MakeNetworked(Owner);
	// 	NumSpawnedBoomerangs += 1;
	// 	BoomerangInstance.SetActorControlSide(Owner);
	// 	FinishSpawningActor(BoomerangInstance);
	// 	CombatComp.SwordBoomerang = BoomerangInstance;
	// 	CombatComp.BlockSword(n"SwordBoomerang");
	// }
}