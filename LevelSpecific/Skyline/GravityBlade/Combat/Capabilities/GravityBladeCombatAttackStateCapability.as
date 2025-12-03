class UGravityBladeCombatAttackStateCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(GravityBladeTags::GravityBlade);
	
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeCombat);

	default CapabilityTags.Add(n"GravityBladeCombatAttackState");

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
		if(!BladeComp.IsBladeEquipped() && !CombatComp.ThrowBladeData.IsValid())
			return false;

		if(!IsActivelyInCombat())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!BladeComp.IsBladeEquipped() && !CombatComp.ThrowBladeData.IsValid())
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
		UGravityBladeCombatEventHandler::Trigger_StartAttackSequence(BladeComp.Blade);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(BladeComp.Blade != nullptr)
			UGravityBladeCombatEventHandler::Trigger_StopAttackSequence(BladeComp.Blade);

		if(CombatComp.HasPendingAttack())
			CombatComp.PendingAttackData.Invalidate();

		if(CombatComp.HasActiveAttack())
			CombatComp.ActiveAttackData.Invalidate();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(GravityBladeCombat::DEBUG_RequestOverrideWithAttackState)
		{
			if(Player.Mesh.CanRequestOverrideFeature())
				Player.Mesh.RequestOverrideFeature(GravityBladeCombat::Feature, this);
		}
	}

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