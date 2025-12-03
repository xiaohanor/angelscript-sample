class UIslandOverseerDoorCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);

	UIslandOverseerPhaseComponent PhaseComp;
	UIslandOverseerVisorComponent VisorComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PhaseComp = UIslandOverseerPhaseComponent::Get(Owner);
		VisorComp = UIslandOverseerVisorComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PhaseComp.Phase != EIslandOverseerPhase::Door)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PhaseComp.Phase != EIslandOverseerPhase::Door)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		VisorComp.Open();
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
				.Add(UHazeCompoundSelector()
					.Try(UHazeCompoundSequence()
						.Then(UIslandOverseerTremorAttackBehaviour())
						.Then(UIslandOverseerAdvanceBehaviour())
						.Then(UIslandOverseerTremorAttackBehaviour())
						.Then(UIslandOverseerAdvanceBehaviour())
						.Then(UIslandOverseerTremorAttackBehaviour())
						.Then(UIslandOverseerAdvanceBehaviour())
						.Then(UIslandOverseerDoorTransitionBehaviour())
						)
				)
				.Add(UIslandOverseerProximityDamageBehaviour())
			;
	}
}

