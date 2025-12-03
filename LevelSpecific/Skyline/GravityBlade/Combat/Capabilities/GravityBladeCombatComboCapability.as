class UGravityBladeCombatComboCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default CapabilityTags.Add(GravityBladeTags::GravityBlade);
	
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeCombat);

	default DebugCategory = GravityBlade::DebugCategory;

	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 100;

	UGravityBladeCombatUserComponent CombatComp;
	UGravityBladeUserComponent BladeComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CombatComp = UGravityBladeCombatUserComponent::Get(Owner);
		BladeComp = UGravityBladeUserComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!CombatComp.bHasActiveCombo)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CombatComp.bHasActiveCombo)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(CombatComp.bHasActiveCombo)
			CombatComp.bHasActiveCombo = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!HasControl())
			return;

		switch (CombatComp.ActiveComboType)
		{
			case EGravityBladeAttackAnimationType::AirAttack:
				if(!MoveComp.IsInAir())
					CombatComp.bHasActiveCombo = false;
			break;
			default:
				if(!CombatComp.HasActiveAttack() && !CombatComp.HasPendingAttack() && !CombatComp.bInsideSettleWindow)
					CombatComp.bHasActiveCombo = false;
			break;
		}
	}
}