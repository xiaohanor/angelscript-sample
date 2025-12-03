class USkylineGecko2DBehaviourCompoundCapability : UHazeCompoundCapability
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
					.Add(UBasicCrowdRepulsionBehaviour())
					.Add(UHazeCompoundSelector()
						// Stunned
						.Try(UHazeCompoundRunAll()		
							.Add(UGravityWhipThrowBehaviour())
							.Add(UGravityWhipLiftBehaviour())												
							.Add(USkylineGeckoOverturnedBehaviour())
							.Add(USkylineGeckoStunnedBehaviour())
							.Add(USkylineGeckoHitBehaviour())
						)
						
						// Custom behaviour
						.Try(USkylineGeckoMoveToLocationBehaviour())

						// Combat vs Zoe
						.Try(UHazeCompoundRunAll()
							.Add(UHazeCompoundStatePicker()
								.State(USkylineGeckoGroundPositioningBehaviour())
								.State(USkylineGeckoGroundChargeBehaviour())
								.State(USkylineGeckoPerchPositioningBehaviour())
								.State(USkylineGecko2DDakkaAttackBehaviour())
								.State(USkylineGecko2DBlobAttackBehaviour())
							)
							.Add(USkylineGeckoPerchBehaviour())
						)

						// Combat vs Mio
						.Try(UHazeCompoundRunAll()
							.Add(UHazeCompoundSequence()
								.Then(USkylineGecko2DPounceAttackBehaviour())
							)
							.Add(USkylineGeckoChaseBehaviour())									
						)

						// Idle
						.Try(UHazeCompoundRunAll()
							.Add(USkylineGeckoTargetingBehaviour())
						)
					)
				;
	}
}

