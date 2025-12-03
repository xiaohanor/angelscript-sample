class AWingSuitBots : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationRooot;

	UPROPERTY(DefaultComponent, Attach = RotationRooot)
	UHazeSkeletalMeshComponentBase BossSkelMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeRawVelocityTrackerComponent VelocityTrackerComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AWingsuitBotProjectile> ProjectileClass;

	UHazeActorNetworkedSpawnPoolComponent SpawnPool;
	FCoastBossAnimData AnimData;

	/**
	 * Spacing between each bot in the animation skeleton
	 */
	UPROPERTY()
	float BotSpacing = 705;

	/**
	 * How much to spread out the last 3 bots
	 */
	UPROPERTY()
	float LastBotSpread = 1000;

	/**
	 * 0.0 - 1.0, How much "noise" to apply. 0 Will cause the bots to follow in a perfect spline
	 */
	UPROPERTY(Meta = (ClampMin = "0.0", ClampMax = "1.0"))
	float AnimNoiseAlpha = 1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnPool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(ProjectileClass, this);
		SpawnPool.OnSpawnedBySpawner.FindOrAdd(this).AddUFunction(this, n"OnSpawned");
		AnimData.Init(BossSkelMesh);
	}

	UFUNCTION()
	private void OnSpawned(AHazeActor SpawnedActor, FHazeActorSpawnParameters Params)
	{
		if(!HasControl())
			return;

		auto Projectile = Cast<AWingsuitBotProjectile>(SpawnedActor);
		Projectile.Init(this, SpawnPool);
		UWingSuitBotsEffectHandler::Trigger_OnShootAirMine(this);
	}

	UFUNCTION()
	void SpawnProjectile(FVector Location, FRotator Rotation)
	{
		if(!HasControl())
			return;

		FHazeActorSpawnParameters Params;
		Params.Location = Location;
		Params.Rotation = Rotation;
		Params.Spawner = this;
		SpawnPool.SpawnControl(Params);
	}
}