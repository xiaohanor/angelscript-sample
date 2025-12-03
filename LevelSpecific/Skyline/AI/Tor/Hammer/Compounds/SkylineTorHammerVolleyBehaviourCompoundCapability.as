class USkylineTorHammerVolleyBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);	
	
	USkylineTorHammerComponent HammerComp;
	UBasicAIHealthBarComponent HealthBarComp;
	FInstigator DisableInstigator;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		HealthBarComp = UBasicAIHealthBarComponent::GetOrCreate(Owner);
		DisableInstigator = FInstigator(n"HammerVolleyInstigator");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HammerComp.CurrentMode == ESkylineTorHammerMode::Volley)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(HammerComp.CurrentMode == ESkylineTorHammerMode::Volley)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{		
		HealthBarComp.SetHealthBarEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ResetCompoundNodes();
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
		.Add(USkylineTorHammerHurtReactionBehaviour())
		.Add(UHazeCompoundSelector()
			.Try(UHazeCompoundSequence()
				.Then(USkylineTorHammerVolleyMoveBehaviour())
				.Then(USkylineTorHammerVolleyLandBehaviour())
				.Then(USkylineTorHammerThrowRecoverBehaviour())
			))
		.Add(USkylineTorHammerShockwaveAttackBehaviour())
		;
	}
}

