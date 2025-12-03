class UIslandOverseerDoorCutHeadCompoundCapability : UHazeCompoundCapability
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
		if(PhaseComp.Phase != EIslandOverseerPhase::DoorCutHead)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PhaseComp.Phase != EIslandOverseerPhase::DoorCutHead)
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
					.Try(UIslandOverseerDoorCloseBehaviour())
					.Try(UIslandOverseerDoorForceBehaviour())
					.Try(UIslandOverseerDoorHoldBehaviour())
					.Try(UIslandOverseerDoorCutHeadBehaviour())
				)
				.Add(UHazeCompoundStatePicker()
					.State(UIslandOverseerLaserBombAttackBehaviour())
					.State(UIslandOverseerShakeAttackBehaviour())
					.State(UIslandOverseerDoorShakeAttackBehaviour())
				)
				.Add(UIslandOverseerProximityDamageBehaviour())
			;
	}
}

