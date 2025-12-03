class UDragonSwordCombatAttackRecoilCapability : UHazePlayerCapability
{
	// default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	// default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	// default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSword);
	
	// default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordCombat);
	// default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordAttackRecoil);

	// default DebugCategory = SummitDebugCapabilityTags::DragonSword;

	// default TickGroup = EHazeTickGroup::BeforeMovement;
	// default TickGroupOrder = 50;

	// UDragonSwordUserComponent SwordComp;
	// UDragonSwordCombatUserComponent CombatComp;
	
	// UPlayerMovementComponent MoveComp;
	// USteppingMovementData Movement;

	// UFUNCTION(BlueprintOverride)
	// void Setup()
	// {
	// 	SwordComp = UDragonSwordUserComponent::Get(Owner);
	// 	CombatComp = UDragonSwordCombatUserComponent::Get(Owner);

	// 	MoveComp = UPlayerMovementComponent::Get(Owner);
	// 	Movement = MoveComp.SetupSteppingMovementData();
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldActivate() const
	// {
	// 	if (CombatComp.ActiveRecoil.EndTimestamp < Time::GameTimeSeconds)
	// 		return false;

	// 	return false;
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldDeactivate() const
	// {
	// 	if (CombatComp.ActiveRecoil.EndTimestamp < Time::GameTimeSeconds)
	// 		return true;

	// 	return false;
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnActivated()
	// {
	// 	Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnDeactivated()
	// {
	// 	Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);

	// 	CombatComp.ActiveRecoil = FDragonSwordRecoilData();
	// }

	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {
	// 	if (MoveComp.PrepareMove(Movement))
	// 	{
	// 		if(HasControl())
	// 		{
	// 			Movement.StopMovementWhenLeavingEdgeThisFrame();
	// 			Movement.AddGravityAcceleration();
	// 			Movement.AddOwnerVerticalVelocity();
	// 		}
	// 		else
	// 		{
	// 			Movement.ApplyCrumbSyncedAirMovement();
	// 		}

	// 		MoveComp.ApplyMoveAndRequestLocomotion(Movement, DragonSwordCombat::Feature);
	// 	}
	// }
}