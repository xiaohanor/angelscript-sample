class UDragonSwordOnBackCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"DragonSwordOnBack");

	default DebugCategory = SummitDebugCapabilityTags::DragonSword;

	default TickGroup = EHazeTickGroup::Gameplay;

	UDragonSwordUserComponent SwordComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwordComp = UDragonSwordUserComponent::Get(Player);
		SwordComp.CreateSword();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SwordComp.bIsOnBack)
			return false;

		if (SwordComp.bIsSequenceActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SwordComp.bIsOnBack)
			return true;

		if (SwordComp.bIsSequenceActive)
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