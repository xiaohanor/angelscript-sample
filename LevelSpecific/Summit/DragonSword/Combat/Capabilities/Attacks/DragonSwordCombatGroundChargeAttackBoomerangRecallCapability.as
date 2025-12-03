class UDragonSwordCombatGroundChargeAttackBoomerangRecallCapability : UHazePlayerCapability
{
	// default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	// default CapabilityTags.Add(CapabilityTags::GameplayAction);
	// default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSword);

	// default DebugCategory = SummitDebugCapabilityTags::DragonSword;

	// default TickGroup = EHazeTickGroup::ActionMovement;
	// default TickGroupOrder = 85;
	// default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 30);

	// UDragonSwordUserComponent SwordComp;
	// UDragonSwordCombatUserComponent CombatComp;
	// UDragonSwordCombatInputComponent InputComp;

	// UFUNCTION(BlueprintOverride)
	// void Setup()
	// {
	// 	SwordComp = UDragonSwordUserComponent::Get(Owner);
	// 	CombatComp = UDragonSwordCombatUserComponent::Get(Owner);
	// 	InputComp = UDragonSwordCombatInputComponent::GetOrCreate(Owner);
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldActivate() const
	// {
	// 	if (!CombatComp.CanStartNewAttack(bUsableWhileMoving = true))
	// 		return false;

	// 	if (!CombatComp.HasBoomerang())
	// 		return false;

	// 	return true;
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldDeactivate() const
	// {
	// 	if (InputComp.WasPrimaryPressed() || InputComp.WasSecondaryPressed())
	// 		return true;

	// 	return false;
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnActivated()
	// {
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnDeactivated()
	// {
	// 	// CombatComp.SwordBoomerang.Recall();
	// 	CombatComp.SwordBoomerang = nullptr;
	// }
}