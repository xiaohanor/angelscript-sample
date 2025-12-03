class USanctuaryDoppelgangerBehaviourCompoundCapability : UHazeCompoundCapability
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
					.Try(USanctuaryDoppelGangerRevealBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(UHazeCompoundSelector()
							// Full mimic
							.Try(USanctuaryDoppelgangerMimicBehaviour())
							// Mimic appearance but move around by yourself
							.Try(UHazeCompoundRunAll()
								.Add(USanctuaryDoppelGangerWatsonPortBehaviour())								
								.Add(USanctuaryDoppelGangerMatchJumpBehaviour())
								.Add(USanctuaryDoppelGangerMatchPauseBehaviour())
								.Add(USanctuaryDoppelGangerRoamBehaviour())					
								.Add(USanctuaryDoppelGangerStalkerBehaviour())					
								.Add(USanctuaryDoppelGangerMatchPositionBehaviour())
							)	
						)
						// Creepy stuff during mimic
						.Add(USanctuaryDoppelGangerCreepyBlinkBehaviour())
					)
					// Stunned
					.Try(UHazeCompoundRunAll()
						//...
					)
					// Combat
					.Try(UHazeCompoundRunAll()
						.Add(USanctuaryDoppelGangerAttackBehaviour())
						.Add(UBasicChaseBehaviour())
						.Add(UBasicTrackTargetBehaviour())
					)
					// Targeting
					.Try(UHazeCompoundRunAll()
						.Add(UBasicFindBalancedTargetBehaviour())
					);
	}
}