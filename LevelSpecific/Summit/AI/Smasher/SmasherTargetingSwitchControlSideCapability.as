class USmasherTargetingSwitchControlSideCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::ControlSideSwitch);

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UBasicAITargetingComponent TargetComp;
	USummitMeltComponent MeltComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TargetComp = UBasicAITargetingComponent::Get(Owner);
		MeltComp = USummitMeltComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MeltComp.bMelted)
			return false; // Stay on Zoe side while melted

		if (!TargetComp.HasValidTarget())
			return false;

		if (Owner.HasControl() == TargetComp.Target.HasControl())
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
		 // We want to be on target side so attack precision is the same as in local play.
		Owner.SetActorControlSide(TargetComp.Target);		

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
