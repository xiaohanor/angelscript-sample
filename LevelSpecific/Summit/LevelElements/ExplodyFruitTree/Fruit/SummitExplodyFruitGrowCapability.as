class USummitExplodyFruitGrowCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitExplodyFruit Fruit;

	FVector StartMeshScale;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Fruit = Cast<ASummitExplodyFruit>(Owner);
		StartMeshScale = Fruit.TopScaleRoot.WorldScale;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Fruit.bIsEnabled)
			return false;

		if(Fruit.bIsInitialFruit)
			return false;

		if(Time::GetGameTimeSince(Fruit.TimeLastSpawned) > Fruit.FruitGrowTime)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Fruit.bIsEnabled)
			return true;

		if(Time::GetGameTimeSince(Fruit.TimeLastSpawned) > Fruit.FruitGrowTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Fruit.bIsGrowing = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Fruit.bIsGrowing = false;
		Fruit.TopScaleRoot.SetWorldScale3D(StartMeshScale);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float TimeSinceSpawned = Time::GetGameTimeSince(Fruit.TimeLastSpawned);
		float ScaleAlpha = TimeSinceSpawned / Fruit.FruitGrowTime;

		Fruit.TopScaleRoot.SetWorldScale3D(StartMeshScale * ScaleAlpha);
	}
};