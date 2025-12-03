class UBlockBehavioursWhenControlledByCutsceneCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CutsceneBehaviour");

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 1; // Before all movement and gameplay

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Owner.OnPreSequencerControl.AddUFunction(this, n"OnCutsceneStarted");
		Owner.OnPostSequencerControl.AddUFunction(this, n"OnCutsceneStopped");
	}

	UFUNCTION()
	private void OnCutsceneStarted(FHazePreSequencerControlParams Params)
	{
		// Since cutscenes can start at any time, we can't wait for this capability to activate
		Owner.BlockCapabilities(BasicAITags::Behaviour, this);
		Owner.BlockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION()
	private void OnCutsceneStopped(FHazePostSequencerControlParams Params)
	{
		Owner.UnblockCapabilities(BasicAITags::Behaviour, this);
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return false;
	}
}
