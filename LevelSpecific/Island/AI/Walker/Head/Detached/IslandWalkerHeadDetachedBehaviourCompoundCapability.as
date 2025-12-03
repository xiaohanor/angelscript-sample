class UIslandWalkerHeadDetachedBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);

	UIslandWalkerHeadComponent HeadComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HeadComp = UIslandWalkerHeadComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (HeadComp.State != EIslandWalkerHeadState::Detached)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HeadComp.State != EIslandWalkerHeadState::Detached)
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
		return UHazeCompoundSelector()
				.Try(UIslandWalkerHeadCrashBehaviour())
				.Try(UHazeCompoundRunAll()
					.Add(UIslandWalkerHeadHurtReactionBehaviour()) 
					.Add(UHazeCompoundSelector()
						.Try(UIslandWalkerHeadDetachIntroBehaviour())
						.Try(UIslandWalkerHeadFireSwoopBehaviour())
						.Try(UIslandWalkerHeadRepositionBehaviour())
						.Try(UIslandWalkerHeadFindTargetBehaviour())
					)
					.Add(UIslandWalkerHeadGrenadeDetonatedBehaviour())
				)
			;
	}
}