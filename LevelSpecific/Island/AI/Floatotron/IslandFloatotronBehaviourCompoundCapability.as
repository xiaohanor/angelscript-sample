

class UIslandFloatotronBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

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
					.Try(UIslandFloatotronDamageReactionBehaviour())
					.Try(UBasicCrowdRepulsionBehaviour())
				)
				.Add(UHazeCompoundSelector()
					.Try(UHazeCompoundRunAll()
						.Add(UIslandFloatotronAttackBehaviour())
						.Add(UIslandFloatotronChaseBehaviour())
						.Add(UIslandFloatotronHeightOffsetBehaviour())
						.Add(UBasicTrackTargetBehaviour())
					)
					.Try(UBasicFindBalancedTargetBehaviour())
				)
			;
	}
}