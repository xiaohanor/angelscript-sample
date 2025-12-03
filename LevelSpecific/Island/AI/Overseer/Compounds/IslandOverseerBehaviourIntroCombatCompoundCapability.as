class UIslandOverseerIntroCombatCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);

	UIslandOverseerPhaseComponent PhaseComp;
	UIslandOverseerVisorComponent VisorComp;
	UBasicAIHealthComponent HealthComp;
	UBasicAIHealthBarComponent HealthBarComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PhaseComp = UIslandOverseerPhaseComponent::Get(Owner);
		VisorComp = UIslandOverseerVisorComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HealthBarComp = UBasicAIHealthBarComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PhaseComp.Phase != EIslandOverseerPhase::IntroCombat)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PhaseComp.Phase != EIslandOverseerPhase::IntroCombat)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ResetCompoundNodes();
		for(AAIIslandOverseerEye Eye : UIslandOverseerDeployEyeManagerComponent::Get(Owner).Eyes)
			Eye.Return();
		VisorComp.Close();

		for(AHazePlayerCharacter Player : Game::Players)
			Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HealthComp.CurrentHealth <= PhaseComp.IntroCombatHealthThreshold)
		{
			PhaseComp.Phase = EIslandOverseerPhase::Flood;
			HealthComp.SetCurrentHealth(PhaseComp.IntroCombatHealthThreshold);
			HealthBarComp.SnapBarToHealth();
		}
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
				.Add(UHazeCompoundSelector()
					.Try(UHazeCompoundSequence()
						.Then(UIslandOverseerPeekBehaviour())
						.Then(UIslandOverseerDeployRollerBehaviour())
						.Then(UIslandOverseerWaitBehaviour(0.75))
						.Then(UIslandOverseerPeekBehaviour())
						.Then(UIslandOverseerWaitBehaviour(1))
						.Then(UIslandOverseerDeployEyeAttackBehaviour())
						.Then(UIslandOverseerWaitBehaviour(0.25))
					)
				);
	}
}