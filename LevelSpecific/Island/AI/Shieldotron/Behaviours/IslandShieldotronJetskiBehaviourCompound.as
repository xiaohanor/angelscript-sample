class UIslandShieldotronJetskiBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);
	default TickGroupOrder = 90;

	UIslandShieldotronSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = UIslandShieldotronSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Only aggressive team will activate
		if (!Settings.bUseJetskiShieldotronBehaviour)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(BasicAITags::CompoundBehaviour, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ResetCompoundNodes();
		Owner.UnblockCapabilities(BasicAITags::CompoundBehaviour, this);
	}
	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
				.Add(UHazeCompoundSelector()
					//.Try(UIslandShieldotronDamageReactionBehaviour())
					.Try(UBasicCrowdRepulsionBehaviour())
				)
				.Add(UHazeCompoundSelector()
					.Try(UIslandShieldotronEntranceAnimationBehaviour())
					.Try(UIslandShieldotronLandBehaviour())
					.Try(UIslandShieldotronStunnedBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(UHazeCompoundSelector()
							.Try(UIslandShieldotronShuffleScenepointBehaviour())
							.Try(UIslandShieldotronJetskiTraceMortarAttackBehaviour())
							.Try(UIslandShieldotronOrbAttackBehaviour())
						)
						.Add(UBasicTrackTargetBehaviour())
						.Add(UHazeCompoundSelector()
							.Try(UIslandShieldotronChaseBehaviour()) // if not holding a shuffle Scenepoint
							.Try(UIslandShieldotronSidestepBehaviour()) // if not holding a shuffle Scenepoint
						)
						.Add(UHazeCompoundSelector()
							.Try(UIslandTurretronFindProximityTargetBehaviour()) // something borrowed
							.Try(UBasicFindTargetBehaviour())
						)
					)
				)
			;
	}
}