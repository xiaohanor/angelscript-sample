

class UIslandShieldotronBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
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
					//.Try(UIslandShieldotronDamageReactionBehaviour())
					.Try(UBasicCrowdRepulsionBehaviour())
				)
				.Add(UHazeCompoundSelector()
					.Try(UIslandShieldotronEntranceAnimationBehaviour())
					.Try(UIslandShieldotronLandBehaviour())
					.Try(UIslandShieldotronStunnedBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(UHazeCompoundSelector()
							//.Try(UIslandShieldotronDodgeBehaviour())
							.Try(UIslandShieldotronShuffleScenepointBehaviour())
							//.Try(UIslandShieldotronTraceMortarAttackBehaviour())
							//.Try(UIslandShieldotronRocketSpreadAttackBehaviour())
							//.Try(UIslandShieldotronRocketAttackBehaviour())
							.Try(UIslandShieldotronCloseRangeAttackBehaviour())
							.Try(UIslandShieldotronOrbAttackBehaviour())
							//.Try(UIslandShieldotronKeepDistanceBehaviour())
							.Try(UIslandShieldotronMeleeAttackBehaviour())  // will block mortar attack while active.
							//.Try(UBasicEvadeBehaviour())
						)
						.Add(UBasicTrackTargetBehaviour())
						.Add(UHazeCompoundSelector()
							.Try(UIslandShieldotronChaseBehaviour()) // if not holding a shuffle Scenepoint
							.Try(UIslandShieldotronSidestepBehaviour()) // if not holding a shuffle Scenepoint
						)
						.Add(UIslandShieldotronFindTargetIgnoreColourBehaviour())
					)
				)
			;
	}
}