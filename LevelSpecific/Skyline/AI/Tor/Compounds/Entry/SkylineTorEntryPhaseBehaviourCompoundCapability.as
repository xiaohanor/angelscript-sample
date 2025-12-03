class USkylineTorEntryPhaseBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);	

	USkylineTorPhaseComponent PhaseComp;
	USkylineTorBehaviourComponent TorBehaviourComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PhaseComp = USkylineTorPhaseComponent::GetOrCreate(Owner);
		TorBehaviourComp = USkylineTorBehaviourComponent::GetOrCreate(Owner);
	}

	// Always active
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PhaseComp.Phase == ESkylineTorPhase::Entry)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PhaseComp.Phase == ESkylineTorPhase::Entry)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TorBehaviourComp.bIgnoreActivationRequirements = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()                                                          
	{
		TorBehaviourComp.bIgnoreActivationRequirements = false;
		ResetCompoundNodes();
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return 	UHazeCompoundSequence()
			.Then(USkylineTorIntroWaitBehaviour())
			.Then(USkylineTorHoldHammerVolleyBehaviour())
			.Then(USkylineTorIntroEnterBehaviour())
			;
	}
}

