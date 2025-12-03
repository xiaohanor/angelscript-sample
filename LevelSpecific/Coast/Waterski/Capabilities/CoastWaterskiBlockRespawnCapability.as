class UCoastWaterskiBlockRespawnCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Waterski");
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	// We want this to be before Respawn capability
	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UCoastWaterskiPlayerComponent WaterskiComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WaterskiComp = UCoastWaterskiPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WaterskiComp.IsWaterskiing())
			return false;

		if(!Player.IsPlayerDead())
			return false;

		if(!RespawnPointIsWithinBlockRespawnZone())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!WaterskiComp.IsWaterskiing())
			return true;

		if(!Player.IsPlayerDead())
			return true;

		if(!RespawnPointIsWithinBlockRespawnZone())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(n"Respawn", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(n"Respawn", this);
	}

	bool RespawnPointIsWithinBlockRespawnZone() const
	{
		FRespawnLocation Location;
		WaterskiComp.GetRespawnTransform(Location);
		FVector RespawnPoint = Location.RespawnTransform.Location;

#if !RELEASE
		TEMPORAL_LOG(this).Point("Respawn Point", RespawnPoint);
#endif

		TListedActors<ACoastWaterskiBlockRespawnZone> ListedBlockRespawnZones;
		for(ACoastWaterskiBlockRespawnZone Zone : ListedBlockRespawnZones)
		{
			if(Zone.IsPointWithinZone(RespawnPoint))
				return true;
		}

		return false;
	}
}