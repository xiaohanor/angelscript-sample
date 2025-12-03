class USummitSmashapultBehaviourCompoundCapability : UHazeCompoundCapability
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
					.Try(UBasicAIEntranceAnimationBehaviour())
					.Try(UBasicSplineEntranceBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(USummitSmashapultLobProjectileBehaviour())
						.Add(USummitSmashapultHoldBehaviour())
					)	
			   ;
	}
}
