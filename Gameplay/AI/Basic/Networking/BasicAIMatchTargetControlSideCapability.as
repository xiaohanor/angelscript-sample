// 
class UBasicAIMatchTargetControlSideCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::ControlSideSwitch);

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UBasicAITargetingComponent TargetComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TargetComp = UBasicAITargetingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!TargetComp.HasValidTarget())
			return false;
		if (Owner.HasControl() == TargetComp.Target.HasControl())
			return false;

		// Target has control on our remote side, time to switch!
		return true;
	}

	// Will only run on the new control side
	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
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