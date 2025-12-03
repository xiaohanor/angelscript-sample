class USummitStoneBeastCritterCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);

	UHazeActorRespawnableComponent RespawnComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);	
		RespawnComp.OnRespawn.AddUFunction(this, n"Reset");
	}

	UFUNCTION()
	private void Reset()
	{
		ResetCompoundNodes();
	}

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
			//.Add(UBasicCrowdRepulsionBehaviour())
			.Add(UHazeCompoundSelector()				
				// Death
				.Try(USummitStoneBeastCritterFlingDeathBehaviour())
				// Entrance
				.Try(UBasicAIEntranceAnimationBehaviour())
				.Try(USummitStoneBeastCritterCrawlSplineEntranceBehaviour())
				.Try(UHazeCompoundSequence()
					.Then(USummitStoneBeastCritterFlySplineEntranceBehaviour())
					.Then(USummitStoneBeastCritterFlySplineEntranceLandingBehaviour())
				)
				// Combat
				.Try(UHazeCompoundRunAll()
					.Add(UHazeCompoundSelector()
						.Try(USummitStoneBeastCritterAttackBehaviour())
						.Try(UHazeCompoundRunAll()
							.Add(UBasicTrackTargetBehaviour())
						)
					)
					.Add(USummitStoneBeastCritterEncircleBehaviour())
					.Add(USummitStoneBeastCritterChaseBehaviour())					
					.Add(UBasicRaiseAlarmBehaviour())									
				)
				.Try(UHazeCompoundRunAll()
					.Add(UBasicFindPriorityTargetBehaviour())
					.Add(UBasicFindBalancedTargetBehaviour())
					.Add(UBasicRoamBehaviour())
				)
			);
	}
}