class USkylineExploderBehaviourCompoundCapability : UHazeCompoundCapability
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
					// Stunned
					.Try(UHazeCompoundRunAll()
						.Add(UGravityWhipThrowBehaviour())
						.Add(UGravityWhipGloryKillBehaviour())
						.Add(UGravityWhipLiftBehaviour())
						.Add(UGravityBladeHitReactionBehaviour())
					)
					// Combat
					.Try(UHazeCompoundRunAll()
						.Add(USkylineExploderFindTargetBehaviour())
						.Add(USkylineExploderProximityExplosionBehaviour())
						.Add(UBasicFindProximityTargetBehaviour())
						.Add(UBasicChaseBehaviour())
						.Add(UBasicTrackTargetBehaviour())
						.Add(UBasicRaiseAlarmBehaviour())
						.Add(UBasicRoamBehaviour())
					);
	}
}

