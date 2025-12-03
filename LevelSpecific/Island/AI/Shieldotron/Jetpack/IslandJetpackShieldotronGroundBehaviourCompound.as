

class UIslandJetpackShieldotronGroundBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);

	UIslandJetpackShieldotronComponent JetpackComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JetpackComp = UIslandJetpackShieldotronComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Activates after landing is completed
		if (JetpackComp.CurrentFlyState != EIslandJetpackShieldotronFlyState::IsGrounded)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Deactivates after take off is completed
		if (JetpackComp.CurrentFlyState == EIslandJetpackShieldotronFlyState::IsAirBorne)
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
					//.Try(UIslandShieldotronDamageReactionBehaviour())
					.Try(UBasicCrowdRepulsionBehaviour())
				)
				.Add(UHazeCompoundSelector()
					.Try(UIslandShieldotronStunnedBehaviour())
					.Try(UIslandJetpackShieldotronTakeOffBehaviour())
					.Try(UIslandShieldotronEntranceAnimationBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(UHazeCompoundSelector()
							.Try(UIslandShieldotronTraceMortarAttackBehaviour())
							.Try(UHazeCompoundRunAll()
								.Add(UHazeCompoundSelector()
									.Try(UIslandShieldotronMeleeAttackBehaviour())
									.Try(UBasicEvadeBehaviour())									
									.Try(UIslandJetpackShieldotronRocketAttackBehaviour())									
								)
								.Add(UBasicTrackTargetBehaviour())
								.Add(UHazeCompoundSelector()
									.Try(UIslandShieldotronShuffleScenepointBehaviour())
									.Try(UIslandShieldotronSidestepBehaviour()) // if Scenepoint is nullptr
								)
								.Add(UIslandShieldotronChaseBehaviour()) // if not holding a Scenepoint
								.Add(UIslandShieldotronFindTargetBehaviour())
							)
						)
					)					
				)
			;
	}
}