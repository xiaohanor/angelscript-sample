class UIslandTurretronBehaviourCompoundCapability : UHazeCompoundCapability
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
			.Add(UIslandTurretronDamageReactionBehaviour())			
			.Add(UHazeCompoundSelector()
				.Try(UIslandTurretronAttackBehaviour())
				.Try(UIslandTurretronFindPriorityTargetBehaviour()) // Sets same coloured player as target
				.Try(UIslandTurretronFindProximityTargetBehaviour()) // Switch to nearer target if lingering too long.
				.Try(UIslandBeamTurretronFindClosestTargetBehaviour()) // Resort to finding closest target.
			)			
			.Add(UIslandTurretronTrackTargetBehaviour());
	}
}