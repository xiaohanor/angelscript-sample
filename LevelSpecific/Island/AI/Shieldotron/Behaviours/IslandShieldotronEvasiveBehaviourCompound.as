

class UIslandShieldotronEvasiveBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);
	default TickGroupOrder = 90;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Only evasive team will activate
		UHazeTeam Team = HazeTeam::GetTeam(IslandShieldotronTags::IslandShieldotronEvasiveTeam);		
		if (Team == nullptr)
			return false;
		if (!Team.IsMember(Owner))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		UHazeTeam Team = HazeTeam::GetTeam(IslandShieldotronTags::IslandShieldotronEvasiveTeam);
		if (Team == nullptr)
			return true;
		if (!Team.IsMember(Owner))
			return true;
		return false;
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
				// .Add(UHazeCompoundSelector()
				// 	.Try(UIslandShieldotronDamageReactionBehaviour())
				// )
				.Add(UHazeCompoundSelector()
					.Try(UIslandShieldotronEntranceAnimationBehaviour())
					.Try(UIslandShieldotronLandBehaviour())
					.Try(UIslandShieldotronStunnedBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(UHazeCompoundSelector()
							.Try(UIslandShieldotronLeapTraversalEvadeBehaviour())
							.Try(UIslandShieldotronTraceMortarAttackBehaviour())					
							.Try(UIslandShieldotronOrbAttackBehaviour())
							.Try(UIslandShieldotronShuffleScenepointBehaviour())							
							//.Try(UIslandShieldotronSidestepBehaviour()) // if shuffle scenepoint is nullptr
							.Try(UBasicEvadeBehaviour())
						)
						//.Add(UIslandShieldotronRocketAttackBehaviour())
						//.Add(UIslandShieldotronRocketSpreadAttackBehaviour())
						.Add(UIslandShieldotronFindTargetBehaviour())
						.Add(UBasicTrackTargetBehaviour())
					)					
				)
			;
	}
}