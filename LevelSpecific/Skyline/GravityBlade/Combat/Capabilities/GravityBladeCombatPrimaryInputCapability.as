class UGravityBladeCombatPrimaryInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default CapabilityTags.Add(GravityBladeTags::GravityBlade);

	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeCombat);
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeCombatPrimaryInput);

	// Contextual move blocks
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::GrappleEnter);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::LedgeMantle);
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Skydive);
	default CapabilityTags.Add(BlockedWhileIn::Slide);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::Vault);
	default CapabilityTags.Add(BlockedWhileIn::WallRun);
	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);

	default DebugCategory = GravityBlade::DebugCategory;

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	UGravityBladeUserComponent BladeComp;
	UGravityBladeCombatUserComponent CombatComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BladeComp = UGravityBladeUserComponent::Get(Owner);
		CombatComp = UGravityBladeCombatUserComponent::Get(Owner);
	}	

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!IsActioning(ActionNames::PrimaryLevelAbility) && !CombatComp.bFakeDebugInput)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsActioning(ActionNames::PrimaryLevelAbility) && !CombatComp.bFakeDebugInput)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CombatComp.bIsPrimaryHeld = true;
		CombatComp.PrimaryHoldStartTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CombatComp.bIsPrimaryHeld = false;
		CombatComp.PrimaryHoldEndTime = Time::GameTimeSeconds;
	}
}