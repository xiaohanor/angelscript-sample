class UIslandWalkerHeadEscapeBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);

	UIslandWalkerHeadComponent HeadComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HeadComp = UIslandWalkerHeadComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (HeadComp.State != EIslandWalkerHeadState::Escape)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HeadComp.State != EIslandWalkerHeadState::Escape)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ResetCompoundNodes();
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundStatePicker()
				.State(UIslandWalkerHeadFloodedEscapeBehaviour())
				.State(UIslandWalkerHeadEscapeBehaviour())
			;
	}
}