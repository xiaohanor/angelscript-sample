class USummitDarkCaveMetalPileShootCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitDarkCaveMetalSpawner Spawner;

	float FireTime;

	int CurrentRounds = 0;
	float WaitTime;

	bool bStartAttack;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Spawner = Cast<ASummitDarkCaveMetalSpawner>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Spawner.bCanSpawn)
			return false;

		if (!Spawner.HasTargets())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Spawner.HasTargets())
			return true;

		if (!Spawner.bCanSpawn)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FireTime = Spawner.FireRate;
		CurrentRounds = Spawner.RoundsPerAttack;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds < WaitTime)
		{
			return;
		}
		else if (!bStartAttack && CurrentRounds != 0)
		{
			CurrentRounds = 0;
			bStartAttack = true;
		}

		FireTime -= DeltaTime;

		if (FireTime <= 0.0)
		{
			FireTime = Spawner.FireRate;
			CurrentRounds++;
			Spawner.SpawnProjectile();
		}

		if (CurrentRounds >= Spawner.RoundsPerAttack)
		{
			WaitTime = Time::GameTimeSeconds + Spawner.WaitTime;
			bStartAttack = false;
		}
	}	
};