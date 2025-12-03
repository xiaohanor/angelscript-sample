class UEvergreenBarrelKillCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 3;

	UEvergreenBarrelPlayerComponent BarrelPlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BarrelPlayerComp = UEvergreenBarrelPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(CurrentBarrel != nullptr)
			return false;

		TListedActors<AEvergreenBarrel> ListedBarrels;
		for(AEvergreenBarrel Barrel : ListedBarrels.Array)
		{
			if(BarrelPlayerComp.BarrelToBlock == Barrel)
				continue;

			if(Barrel.ShouldPlayerGetKilled())
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.KillPlayer();
	}

	AEvergreenBarrel GetCurrentBarrel() const property
	{
		return BarrelPlayerComp.CurrentBarrel;
	}
}