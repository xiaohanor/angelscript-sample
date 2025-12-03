class UIslandWalkerIntroCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);

	UIslandWalkerPhaseComponent PhaseComp;
	UIslandWalkerLegsComponent LegsComp;		
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PhaseComp = UIslandWalkerPhaseComponent::GetOrCreate(Owner);
		LegsComp = UIslandWalkerLegsComponent::Get(Owner);		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if ((PhaseComp.Phase != EIslandWalkerPhase::Intro) && 
			(PhaseComp.Phase != EIslandWalkerPhase::IntroEnd))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if ((PhaseComp.Phase != EIslandWalkerPhase::Intro) && 
			(PhaseComp.Phase != EIslandWalkerPhase::IntroEnd))
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
		if (!LegsComp.bIsPoweredUp)
			LegsComp.PowerUpLegs();
		for (AHazePlayerCharacter Player : Game::Players)		
		{
            Player.ClearResolverExtension(UIslandWalkerSquishedResolverExtension, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundStatePicker()
				.State(UIslandWalkerIntroBehaviour())
				.State(UIslandWalkerIntroEndBehaviour())
			   ;
	}
}


