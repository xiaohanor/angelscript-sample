class UDragonSwordWieldingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"DragonSwordWielding");

	default DebugCategory = SummitDebugCapabilityTags::DragonSword;

	default TickGroup = EHazeTickGroup::Gameplay;

	UDragonSwordUserComponent SwordComp;
	ADragonSword Sword;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwordComp = UDragonSwordUserComponent::Get(Player);
		SwordComp.CreateSword();
	}

	// UFUNCTION(BlueprintOverride)
	// void OnRemoved()
	// {
	// 	Sword.DetachRootComponentFromParent();
	// 	Sword.DestroyActor();
	// 	Sword = nullptr;
	// }

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SwordComp.SwordIsActive())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SwordComp.SwordIsActive())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SwordComp.AddShowSwordInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SwordComp.RemoveShowSwordInstigator(this);
	}
};