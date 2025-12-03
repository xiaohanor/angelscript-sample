class USmasherMeltedSwitchControlSideCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::ControlSideSwitch);

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	USummitMeltComponent MeltComp;
	UBasicAIEntranceComponent EntranceComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MeltComp = USummitMeltComponent::Get(Owner);
		EntranceComp = UBasicAIEntranceComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!MeltComp.bMelted)
			return false;

		if (EntranceComp.bHasStartedEntry && !EntranceComp.bHasCompletedEntry)
			return false;

		// Switch to Zoe control so smashing crystal will be responsive
		if (Owner.HasControl() == Game::Zoe.HasControl())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{		
		 // We want fast reaction on Zoe's side after melting. Other capabilities may switch to Mio if she's selected as a target
		Owner.SetActorControlSide(Game::Zoe);		

		// Stop behaviour and movement until switch is complete
		Owner.BlockCapabilities(CapabilityTags::Movement, this);
		Owner.BlockCapabilities(BasicAITags::CompoundBehaviour, this);
		Owner.BlockCapabilities(BasicAITags::Behaviour, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		Owner.UnblockCapabilities(BasicAITags::CompoundBehaviour, this);
		Owner.UnblockCapabilities(BasicAITags::Behaviour, this);
	}
};
