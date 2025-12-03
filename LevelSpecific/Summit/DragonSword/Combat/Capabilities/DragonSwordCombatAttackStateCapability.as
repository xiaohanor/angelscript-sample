class UDragonSwordCombatAttackStateCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSword);
	
	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordCombat);

	default DebugCategory = SummitDebugCapabilityTags::DragonSword;

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	UDragonSwordUserComponent SwordComp;
	UDragonSwordCombatUserComponent CombatComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwordComp = UDragonSwordUserComponent::Get(Owner);
		CombatComp = UDragonSwordCombatUserComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!SwordComp.IsWeaponEquipped())
			return false;

		if(!IsActivelyInCombat())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!SwordComp.IsWeaponEquipped())
			return true;

		if(!MoveComp.IsInAir())
		{
			if(!IsActivelyInCombat())
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UDragonSwordCombatEventHandler::Trigger_StartAttackSequence(SwordComp.Weapon);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(SwordComp.Weapon != nullptr)
			UDragonSwordCombatEventHandler::Trigger_StopAttackSequence(SwordComp.Weapon);

		if(CombatComp.HasPendingAttack())
			CombatComp.PendingAttackData.Invalidate();

		if(CombatComp.HasActiveAttack())
			CombatComp.ActiveAttackData.Invalidate();
	}

	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {
	// 	if(DragonSwordCombat::DEBUG_RequestOverrideWithAttackState)
	// 	{
	// 		if(Player.Mesh.CanRequestOverrideFeature())
	// 			Player.Mesh.RequestOverrideFeature(DragonSwordCombat::Feature, this);
	// 	}
	// }

	private bool IsActivelyInCombat() const
	{
		if(CombatComp.HasActiveAttack())
			return true;

		if(CombatComp.HasPendingAttack())
			return true;

		if(CombatComp.bInsideSettleWindow)
			return true;

		return false;
	}
}