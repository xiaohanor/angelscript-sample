class ASanctuaryDodgerDamageArea : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USphereComponent RangeComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UHazeActorNetworkedSpawnPoolComponent SpawnPool;
	USanctuaryDodgerSettings DodgerSettings;
	private float SpawnTime;
	float DamageTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{		
		SpawnPool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(Class, this);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
	}
	
	UFUNCTION()
	private void OnReset()
	{
		SpawnTime = Time::GameTimeSeconds;

		if(!IsActorTickEnabled())
			SetActorTickEnabled(true);
		
		if(IsActorDisabled())
			RemoveActorDisable(this);
	}

	void SetLauncher(AHazeActor InLauncher) property
	{
		DodgerSettings = USanctuaryDodgerSettings::GetSettings(InLauncher);
		DamageTime = SpawnTime + DodgerSettings.DamageAreaInterval;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(SpawnTime != 0.0 && Time::GetGameTimeSince(SpawnTime) > DodgerSettings.DamageAreaLifetime)
		{
			SetActorTickEnabled(false);
			AddActorDisable(this);
			RespawnComp.UnSpawn();
			SpawnPool.UnSpawn(this);	
			return;		
		}

		if(Time::GetGameTimeSeconds() < DamageTime)
			return;

		DamageTime += DodgerSettings.DamageAreaInterval;

		for(AHazePlayerCharacter Player: Game::Players)
		{
			float DamageFactor = Damage::GetRadialDamageFactor(Player.ActorLocation, RangeComp.WorldLocation, RangeComp.SphereRadius);
			UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player);
			if(HealthComp != nullptr && DamageFactor > 0)
				HealthComp.DamagePlayer(DamageFactor * DodgerSettings.DamageAreaDamage, nullptr, nullptr);
		}
	}
}