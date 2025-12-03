class UIslandWalkerWalkingCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);

	UIslandWalkerPhaseComponent PhaseComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PhaseComp = UIslandWalkerPhaseComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PhaseComp.Phase != EIslandWalkerPhase::Walking)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PhaseComp.Phase != EIslandWalkerPhase::Walking)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (AHazePlayerCharacter Player : Game::Players)		
		{
            Player.ApplyResolverExtension(UIslandWalkerSquishedResolverExtension, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ResetCompoundNodes();
		for (AHazePlayerCharacter Player : Game::Players)		
		{
           	Player.ClearResolverExtension(UIslandWalkerSquishedResolverExtension, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
				.Add(UHazeCompoundSelector()
					.Try(UIslandWalkerFallBehaviour())
					.Try(UIslandWalkerLegHurtBehaviour())
					.Try(UIslandWalkerSmashCageBehaviour())
					.Try(UHazeCompoundStatePicker()
						.State(UIslandWalkerJumpAttackBehaviour())
						.State(UIslandWalkerDefensiveSpawnBehaviour())
						.State(UIslandWalkerFireBurstBehaviour())
						.State(UIslandWalkerRepositionBehaviour())
						.State(UIslandWalkerStandingSpawnBehaviour())
						.State(UIslandWalkerSpinningLaserBehaviour())	
						.State(UIslandWalkerTrackTargetBehaviour())
					)
					.Try(UIslandWalkerTargetingBehaviour())
				)
			;
	}
}

