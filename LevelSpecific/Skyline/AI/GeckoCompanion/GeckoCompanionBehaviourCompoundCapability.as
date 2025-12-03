class UGeckoCompanionBehaviourCompoundCapability : UHazeCompoundCapability
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
		return 	UHazeCompoundRunAll()
					.Add(UHazeCompoundSelector()
						// Stunned
						.Try(UHazeCompoundRunAll()		
							.Add(USkylineGeckoHitBehaviour())
						)
						
						// Idle 
						.Try(UHazeCompoundRunAll()
							.Add(UGeckoCompanioLeashedBehaviour())
							.Add(USkylineGeckoIdleMoveBehaviour())
						)
					)
				;
	}
}

