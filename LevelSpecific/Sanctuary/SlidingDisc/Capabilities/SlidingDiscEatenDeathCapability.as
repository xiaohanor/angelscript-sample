class USlidingDiscEatenDeathCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASlidingDisc SlidingDisc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SlidingDisc = Cast<ASlidingDisc>(Owner);	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!SlidingDisc.bDisintegrated)
			return false;

		if(!Game::Mio.IsPlayerDead())
			return false;
		
		if(!Game::Zoe.IsPlayerDead())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Game::Mio.IsPlayerDead())
			return true;
		
		if(!Game::Zoe.IsPlayerDead())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		USlidingDiscEventHandler::Trigger_OnEatenByHydra(SlidingDisc);
		Game::Mio.ClearPointOfInterestByInstigator(this);
		Game::Mio.DeactivateCamera(SlidingDisc.Camera);
		Game::Mio.ActivateCamera(SlidingDisc.EatenCamera, .5, this, EHazeCameraPriority::VeryHigh);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		
		Game::Mio.DeactivateCamera(SlidingDisc.EatenCamera);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PrintToScreen("asdasdasdasdad");
	}
};