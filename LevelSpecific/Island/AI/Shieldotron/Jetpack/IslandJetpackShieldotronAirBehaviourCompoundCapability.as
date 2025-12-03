class UIslandJetpackShieldotronAirBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);
	default TickGroupOrder = 90;

	UIslandJetpackShieldotronComponent JetpackComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JetpackComp = UIslandJetpackShieldotronComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Activates after take off is completed
		if (JetpackComp.CurrentFlyState != EIslandJetpackShieldotronFlyState::IsAirBorne)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Deactivates after landing is completed
		if (JetpackComp.CurrentFlyState == EIslandJetpackShieldotronFlyState::IsGrounded)
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
				.Add(UIslandShieldotronFindTargetBehaviour())
				.Add(UHazeCompoundSelector()
					//.Try(UIslandShieldotronDamageReactionBehaviour())
					.Try(UBasicCrowdRepulsionBehaviour())
				)
				.Add(UHazeCompoundSelector()					
					.Try(UHazeCompoundRunAll()
						.Add(UHazeCompoundSelector()
							.Try(UIslandShieldotronScenepointEntranceBehaviour())
							.Try(UBasicScenepointEntranceBehaviour())
							.Try(UHazeCompoundRunAll()
								.Add(UHazeCompoundStatePicker()
									.State(UIslandJetpackShieldotronLemonHorizontalAttackBehaviour())
									.State(UIslandJetpackShieldotronLemonVerticalAttackBehaviour())
								)
								.Add(UBasicEvadeBehaviour())
								.Add(UBasicTrackTargetBehaviour())
								.Add(UHazeCompoundSelector()
									.Try(UIslandJetpackShieldotronHoldWaypointBehaviour())
									.Try(UHazeCompoundRunAll()
										.Add(UIslandJetpackShieldotronEngageAttackPositionBehaviour())
										.Add(UIslandJetpackShieldotronMatchHeightBehaviour())
										.Add(UIslandJetpackShieldotronHoverChaseBehaviour())
									)
								)
								.Add(UIslandJetpackShieldotronAvoidWallsBehaviour())
								.Add(UIslandJetpackShieldotronDriftBehaviour())
							)
						)
					)					
				)
			;
	}
}