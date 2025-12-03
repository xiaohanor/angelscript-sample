class USummitStoneBeastZapperCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);

	UHazeActorRespawnableComponent RespawnComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
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
			.Add(UBasicCrowdRepulsionBehaviour())
			.Add(UHazeCompoundSelector()
				// Entrance
				.Try(UBasicAIEntranceAnimationBehaviour())
				.Try(UBasicSplineEntranceBehaviour())
				// Combat
				.Try(UHazeCompoundRunAll()
					.Add(UHazeCompoundSequence()
						//.Then(USummitStoneBeastZapperAttackBehaviour())
						.Then(USummitStoneBeastZapperBeamAttackBehaviour())
						.Then(USummitStoneBeastZapperRecoveryBehaviour())
					)
					.Add(UBasicTrackTargetBehaviour())
					//.Add(USummitStoneBeastZapperAttackBehaviour())
					.Add(USummitStoneBeastScenepointShuffleScenepointBehaviour())
					.Add(UBasicRaiseAlarmBehaviour())								
				)
				.Try(UHazeCompoundRunAll()
					.Add(UBasicFindPriorityTargetBehaviour())
					.Add(UBasicFindBalancedTargetBehaviour())
				)
			);
	}
}