class USummitStoneBeastCrystalTurretBehaviourCompoundCapability : UHazeCompoundCapability
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
			//.Add(UIslandBeamTurretronDamageReactionBehaviour())
			.Add(UHazeCompoundSelector()
				//.Try(UIslandBeamTurretronInactiveBehaviour())
				.Try(UHazeCompoundSelector()
					//.Try(UIslandBeamTurretronFindProximityTargetBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(USummitStoneBeastCrystalTurretAttackBehaviour())
						.Add(USummitStoneBeastCrystalTurretTrackTargetBehaviour()) 
					)
					.Try(UHazeCompoundSelector()							
						//.Try(UIslandBeamTurretronFindPriorityTargetBehaviour()) // Sets same coloured player as target
						//.Try(UIslandBeamTurretronFindClosestTargetBehaviour())
					)
				)
				.Try(UBasicFindTargetBehaviour())
			);
	}
}