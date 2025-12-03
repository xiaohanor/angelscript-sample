class USummitCritterSwarmConstrainToAreaCapability : UHazeCapability
{
	USummitCritterSwarmComponent SwarmComp;
	UHazeActorRespawnableComponent RespawnComp;
	UBasicAIDestinationComponent DestinationComp;
	USummitCritterSwarmSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwarmComp = USummitCritterSwarmComponent::GetOrCreate(Owner);
		DestinationComp = UBasicAIDestinationComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnSpawn");
		Settings = USummitCritterSwarmSettings::GetSettings(Owner);
		OnSpawn();
	}

	UFUNCTION()
	private void OnSpawn()
	{	
		USummitCritterSwarmAreaRegistry AreaRegistry = Game::GetSingleton(USummitCritterSwarmAreaRegistry);		
		SwarmComp.Area = AreaRegistry.GetBestArea(Cast<AHazeActor>(Owner), RespawnComp.SpawnParameters);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SwarmComp.IsAllowedLocation(Owner.ActorLocation))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (SwarmComp.Area.IsWithin(Owner.ActorLocation, 0.9))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector ToCenter = (SwarmComp.Area.SphereComp.WorldLocation - Owner.ActorLocation).GetSafeNormal();
		DestinationComp.AddCustomAcceleration(ToCenter * Settings.AreaConstrainAcceleration);
	}
}
