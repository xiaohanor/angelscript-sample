class USkylineGeckoBehaviourCompoundCapability : UHazeCompoundCapability
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
							.Add(USkylineGeckoOverturnedBehaviour())
							.Add(USkylineGeckoStunnedBehaviour())
							.Add(USkylineGeckoHitBehaviour())
							.Add(USkylineGeckoWhipGrabbedBehaviour())
						)
						
						// Custom behaviour
						.Try(USkylineGeckoSplineEntryBehaviour())
						// .Try(USkylineGeckoMoveToLocationBehaviour())

						// Combat
						.Try(UHazeCompoundRunAll()
							.Add(USkylineGeckoFreezeWhenTargetedBehaviour())
							.Add(USkylineGeckoConstrainAttackBehaviour())
							.Add(USkylineGeckoPounceAttackBehaviour())
							// .Add(USkylineGeckoChaseAlongSplineBehaviour())
						)
						// Idle
						.Try(UHazeCompoundRunAll()
							// .Add(USkylineGeckoIdleMoveBehaviour())
							.Add(USkylineGeckoRetarget())
							.Add(USkylineGeckoPassiveBehaviour())
							.Add(UBasicEvadeBehaviour())
							.Add(USkylineGeckoGroundedCircleStrafeBehaviour())
							.Add(USkylineGeckoChaseBehaviour())					
						)
					)
				;
	}
}

