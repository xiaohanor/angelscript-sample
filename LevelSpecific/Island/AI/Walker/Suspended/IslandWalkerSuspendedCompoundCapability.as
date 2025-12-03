class UIslandWalkerSuspendedBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);

	UIslandWalkerPhaseComponent PhaseComp;
	UIslandWalkerComponent SuspendComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PhaseComp = UIslandWalkerPhaseComponent::GetOrCreate(Owner);
		SuspendComp = UIslandWalkerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PhaseComp.Phase != EIslandWalkerPhase::Suspended)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PhaseComp.Phase != EIslandWalkerPhase::Suspended)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ResetCompoundNodes();
		Owner.ClearSettingsByInstigator(IslandWalker::SuspendedInstigator);		
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
				.Add(UHazeCompoundSelector()
					.Try(UIslandWalkerSuspendedFallDownBehaviour())
					.Try(UIslandWalkerSuspendedIntroBehaviour())
					.Try(UIslandWalkerSuspendedCableCutBehaviour())
					.Try(UIslandWalkerSuspendedHurtReactionBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(UHazeCompoundStatePicker()
							.State(UIslandWalkerSuspendedFirewallBehaviour())
							.State(UIslandWalkerSuspendedClusterMinesBehaviour())
						)
						.Add(UIslandWalkerSuspendedTrackTargetBehaviour())
						.Add(UIslandWalkerSuspendedBehaviour())
						.Add(UIslandWalkerSuspendedFindTargetBehaviour())
					)
				)
			;
	}
}

