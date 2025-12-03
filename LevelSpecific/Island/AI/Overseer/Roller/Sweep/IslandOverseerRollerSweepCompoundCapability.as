class UIslandOverseerRollerSweepCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);

	UIslandOverseerRollerComponent RollerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RollerComp = UIslandOverseerRollerComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!RollerComp.bDetached)
			return false;
		if(RollerComp.Phase != EIslandOverseerPhase::IntroCombat)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!RollerComp.bDetached)
			return true;
		if(RollerComp.Phase != EIslandOverseerPhase::IntroCombat)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UIslandOverseerRollerEventHandler::Trigger_OnSweepTelegraphEnd(Owner);
		ResetCompoundNodes();
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
				.Add(UHazeCompoundSequence()
					.Then(UIslandOverseerRollerSweepEnterBehaviour())
					.Then(UIslandOverseerRollerSweepDropBehaviour())
					.Then(UIslandOverseerRollerSweepAttackBehaviour())
					.Then(UIslandOverseerRollerSweepSettleBehaviour())
					.Then(UIslandOverseerRollerSweepExitBehaviour())
				)
			;
	}
}

