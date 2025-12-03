class USummitWyrmBehaviourCompoundCapability : UHazeCompoundCapability
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
		return 	UHazeCompoundSelector()
					.Try(USummitWyrmFollowSplineBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(USummitWyrmHurtReactionBehaviour())						
					)
					.Try(UHazeCompoundRunAll()
						.Add(UHazeCompoundSequence()
							.Then(USummitWyrmAttackBehaviour())
							.Then(USummitWyrmRecoverBehaviour())
						)						
						.Add(USummitWyrmAttackPositioningBehaviour())
						.Add(USummitWyrmEngageBehaviour())
						.Add(USummitWyrmCombatRoamBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(UBasicFindBalancedTargetBehaviour())
						.Add(USummitWyrmRoamBehaviour())
					);
	}
}

