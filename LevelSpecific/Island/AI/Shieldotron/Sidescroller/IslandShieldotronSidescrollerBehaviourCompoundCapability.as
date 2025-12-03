class UIslandShieldotronSidescrollerBehaviourCompoundCapability : UHazeCompoundCapability
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
					.Try(UHazeCompoundRunAll()
						.Add(UIslandShieldotronStunnedBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(UIslandShieldotronSidescrollerDamageReactionBehaviour()) // needed for damage handling, even if not actually activated
						//.Add(UIslandShieldotronSidescrollerMortarAttackBehaviour())		
						.Add(UIslandShieldotronSidescrollerMeleeAttackBehaviour())
						.Add(UIslandShieldotronSidescrollerChaseBehaviour())
						.Add(UIslandShieldotronSidescrollerAvoidBehaviour())
						.Add(UIslandShieldotronSidescrollerAttackBehaviour())
						.Add(UBasicTrackTargetBehaviour())
						.Add(UIslandShieldotronFindTargetBehaviour())
					)
				)
			;
	}
}