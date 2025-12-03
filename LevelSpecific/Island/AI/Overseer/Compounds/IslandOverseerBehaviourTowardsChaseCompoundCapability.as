class UIslandOverseerTowardsChaseCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);

	UIslandOverseerPhaseComponent PhaseComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PhaseComp = UIslandOverseerPhaseComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PhaseComp.Phase != EIslandOverseerPhase::TowardsChase)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PhaseComp.Phase != EIslandOverseerPhase::TowardsChase)
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
		return UHazeCompoundRunAll()
				.Add(UHazeCompoundSelector()
					.Try(UHazeCompoundRunAll()
						.Add(UIslandOverseerTowardsChaseBehaviour())
						.Add(UIslandOverseerProximityDamageBehaviour())
						.Add(UIslandOverseerTowardsChaseSpeedBoostBehaviour())
						.Add(UIslandOverseerCrushableBehaviour())
						.Add(UHazeCompoundSelector()
							.Try(UIslandOverseerBeamAttackBehaviour())
							.Try(UIslandOverseerLaserAttackBehaviour())
						)
					)	
				)
			;
	}
}