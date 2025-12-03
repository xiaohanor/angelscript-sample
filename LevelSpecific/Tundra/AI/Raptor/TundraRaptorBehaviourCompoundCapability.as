class UTundraRaptorBehaviourCompoundCapability : UHazeCompoundCapability
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
			.Add(UHazeCompoundSelector()
				.Try(UHazeCompoundSelector()
					.Try(UHazeCompoundRunAll()
						.Add(UTundraRaptorDamageBehaviour())
						.Add(UTundraRaptorTrappedBehaviour())						
					)
					.Try(UHazeCompoundRunAll()
						.Add(UTundraRaptorCircleBehaviour())
						.Add(UTundraRaptorGotoCircleBehaviour())
						.Add(UTundraRaptorAttackBehaviour())
						.Add(UBasicFlyingChaseBehaviour())
						.Add(UBasicTrackTargetBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(UTundraRaptorFindTargetBehaviour())
						.Add(UTundraRaptorReturnBehaviour())
					)
				)	
			);
	}
}
