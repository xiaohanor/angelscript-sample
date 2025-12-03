class UTundraGnatBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);

	// Always active
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSelector()
				.Try(UTundraLeapEntryBehaviour())
				.Try(UTundraGnatBeaverSpearEntryBehaviour())
				.Try(UTundraGnatClimbEntryBehaviour())
				.Try(UHazeCompoundRunAll()
					.Add(UBasicCrowdRepulsionBehaviour())
					.Add(UHazeCompoundSelector()
						.Try(UTundraGnapeFleeBehaviour())
						.Try(UTundraGnatStartingTauntBehaviour())
						.Try(UTundraGnatShakenOffBehaviour())
						.Try(UTundraGnapeAvoidMonkeyBehaviour())
						.Try(UTundraGnatAnnoyBehaviour())
						.Try(UTundraGnatEngageBehaviour())
					)
				)
			   ;
	}
}
