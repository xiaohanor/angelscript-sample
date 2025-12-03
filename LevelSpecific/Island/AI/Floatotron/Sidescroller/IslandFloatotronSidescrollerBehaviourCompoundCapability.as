class UIslandFloatotronSidescrollerBehaviourCompoundCapability : UHazeCompoundCapability
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
		// targeting
		return UHazeCompoundRunAll()
				.Add(UIslandFloatotronSidescrollerCrowdRepulsionBehaviour())
				.Add(UHazeCompoundSelector()
					.Try(UHazeCompoundRunAll()
						.Add(UIslandFloatotronDamageReactionBehaviour())
					)
					.Try(UHazeCompoundRunAll()						
						.Add(UIslandFloatotronAttackBehaviour())						
						.Add(UIslandFloatotronSidescrollerChaseBehaviour())
						.Add(UBasicTrackTargetBehaviour())
					)
					.Try(UBasicFindBalancedTargetBehaviour())
				)
			;
	}
}