class USlidingDiscDestroyCapability : UHazeCapability
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
		if(!Game::Mio.IsPlayerDead())
			return false;
		
		if(!Game::Zoe.IsPlayerDead())
			return false;

		if(!SlidingDisc.bIsSliding)
			return false;

		if(SlidingDisc.bDisintegrated)
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
		USlidingDiscEventHandler::Trigger_OnDiscDestroyed(SlidingDisc);
		SlidingDisc.DiscMesh.AddComponentVisualsBlocker(this);
		SlidingDisc.TrailVFX.Deactivate();
		SlidingDisc.BP_TurnOffTorches();
		SlidingDisc.DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};