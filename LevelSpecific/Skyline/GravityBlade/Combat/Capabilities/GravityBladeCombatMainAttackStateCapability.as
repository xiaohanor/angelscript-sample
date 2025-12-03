class UGravityBladeCombatMainAttackStateCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(GravityBladeTags::GravityBlade);
	
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeCombat);

	default DebugCategory = GravityBlade::DebugCategory;

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	UGravityBladeUserComponent BladeComp;
	UGravityBladeCombatUserComponent CombatComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BladeComp = UGravityBladeUserComponent::Get(Owner);
		CombatComp = UGravityBladeCombatUserComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!BladeComp.IsBladeEquipped())
			return false;

		if(!IsInMainAttackState())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!BladeComp.IsBladeEquipped() && !CombatComp.ThrowBladeData.IsValid())
			return true;

		if(!IsInMainAttackState())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(GravityBladeGrappleTags::GravityBladeGrappleGrapple, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(GravityBladeGrappleTags::GravityBladeGrappleGrapple, this);
	}

	private bool IsInMainAttackState() const
	{
		if(CombatComp.bInsideComboWindow || CombatComp.bInsideSettleWindow)
			return false;

		if(CombatComp.HasActiveAttack())
			return true;

		if(CombatComp.HasPendingAttack())
			return true;

		return false;
	}
}