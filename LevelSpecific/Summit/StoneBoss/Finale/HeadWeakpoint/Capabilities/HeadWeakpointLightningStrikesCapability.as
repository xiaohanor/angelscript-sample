class UHeadWeakpointLightningStrikesCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AStoneBeastHeadWeakpointManager Manager;

	float FireRate = 0.5;
	float FireTime;

	TArray<int> SavedLastRandoms;
	int MaxSaved = 7;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = Cast<AStoneBeastHeadWeakpointManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Manager.bLightningAttack)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Manager.bLightningAttack)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FireTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		while (Time::GameTimeSeconds > FireTime)
		{
			FireTime += FireRate;

			int R = Math::RandRange(0,  Manager.LightingPoints.Num() - 1);

			while (SavedLastRandoms.Contains(R))
				R = Math::RandRange(0,  Manager.LightingPoints.Num() - 1);

			SavedLastRandoms.AddUnique(R);

			if (SavedLastRandoms.Num() > MaxSaved)
				SavedLastRandoms.RemoveAt(0);

			Manager.LightingPoints[R].ActivateLightning();
		}
	}
};