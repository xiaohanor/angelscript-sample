class UTundraShellyBehaviourCompoundCapability : UHazeCompoundCapability
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
						.Add(UTundraShellyShellMoveBehaviour())
						.Add(UTundraShellyShellBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(UTundraShellyAttackBehaviour())
						.Add(UBasicChaseBehaviour())
						.Add(UBasicTrackTargetBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(UBasicFindBalancedTargetBehaviour())
					)
				)	
			);
	}
}
