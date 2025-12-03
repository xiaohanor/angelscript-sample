class UCoastWaterskiDeathCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Waterski");
	default CapabilityTags.Add(n"WaterskiDeath");

	UCoastWaterskiPlayerComponent WaterskiComp;
	UPlayerMovementComponent MoveComp;
	UPlayerHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WaterskiComp = UCoastWaterskiPlayerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		HealthComp = UPlayerHealthComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WaterskiComp.IsWaterskiing())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!WaterskiComp.IsWaterskiing())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HealthComp.OnDeathTriggered.AddUFunction(this, n"OnDeath");
		Player.ApplyRespawnPointOverrideDelegate(this, 
			FOnRespawnOverride(this, n"OnRespawnOverride"), EInstigatePriority::Normal);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HealthComp.OnDeathTriggered.Unbind(this, n"OnDeath");
		Player.ClearRespawnPointOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TArray<FHitResult> AllImpacts;
		TArray<FHitResult> WallImpacts = MoveComp.GetAllWallImpacts();

		AllImpacts.Append(MoveComp.GetAllGroundImpacts());
		AllImpacts.Append(WallImpacts);
		AllImpacts.Append(MoveComp.GetAllCeilingImpacts());
		for(FHitResult Hit : AllImpacts)
		{
			// There is a chance that the actor will have been destroyed so we have to null check
			if(Hit.Actor == nullptr)
				continue;

			auto ForceDeathComp = UCoastWaterskiForceDeathComponent::Get(Hit.Actor);
			if(ForceDeathComp == nullptr)
				continue;

			Player.KillPlayer();
			return;
		}

		for(FHitResult Hit : WallImpacts)
		{
			// There is a chance that the actor will have been destroyed so we have to null check
			if(Hit.Actor == nullptr)
				continue;

			auto IgnoreDeathComp = UCoastWaterskiIgnoreDeathComponent::Get(Hit.Actor);
			if(IgnoreDeathComp != nullptr)
				continue;

			Player.KillPlayer();
			return;
		}
	}

	UFUNCTION()
	private void OnDeath()
	{
		if(WaterskiComp.SpawnInWingsuitInstigators.Num() == 0)
			return;

		WaterskiComp.SpawnInWingsuitInstigators.Reset();
		WaterskiComp.StopWaterskiing();
		ActivateWingSuit(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	private bool OnRespawnOverride(AHazePlayerCharacter In_Player, FRespawnLocation& OutLocation)
	{
		return WaterskiComp.GetRespawnTransform(OutLocation);
	}
}