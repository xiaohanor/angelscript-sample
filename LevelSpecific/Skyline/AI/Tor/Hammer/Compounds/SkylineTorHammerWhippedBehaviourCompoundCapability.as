class USkylineTorHammerWhippedBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);	
	
	USkylineTorHammerComponent HammerComp;
	UBasicAIHealthBarComponent HealthBarComp;
	USkylineTorHammerStateManager HammerStateManager;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		HealthBarComp = UBasicAIHealthBarComponent::GetOrCreate(Owner);
		HammerStateManager = USkylineTorHammerStateManager::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HammerComp.CurrentMode == ESkylineTorHammerMode::Whipped)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(HammerComp.CurrentMode == ESkylineTorHammerMode::Whipped)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HammerStateManager.EnableWhipTargetComp(this);
		HealthBarComp.SetHealthBarEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ResetCompoundNodes();
		HammerStateManager.ClearWhipTargetComp(this);
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return 	UHazeCompoundSelector()			
			.Try(USkylineTorHammerWhipAttackBehaviour())
			.Try(USkylineTorHammerWhipThrowBehaviour())
			.Try(USkylineTorHammerWhipGrabBehaviour())
			.Try(USkylineTorHammerReturnBehaviour())
			;
	}
}