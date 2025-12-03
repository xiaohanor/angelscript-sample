class UCoastJetskiBehaviourCompoundCapability : UHazeCompoundCapability
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
		return UHazeCompoundRunAll()
				.Add(UCoastJetskiDamageReactionBehaviour())
				.Add(UBasicCrowdRepulsionBehaviour())
				.Add(UHazeCompoundSelector()
					.Try(UCoastJetskiDeployBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(UCoastJetskiTargetingBehaviour())
						.Add(UCoastJetskiAttackBehaviour())
						.Add(UCoastJetskiObstacleAvoidanceBehaviour())
						.Add(UCoastJetskiEngageBehaviour())
					)
				)
			;
	}
}
