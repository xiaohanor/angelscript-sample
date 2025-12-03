class ASummitMagicWaveSpawnerManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(6.0));

	UPROPERTY(EditAnywhere)
	AGemFloorBreaker GemBreaker;

	UPROPERTY()
	TSubclassOf<ASummitMagicWave> MagicWaveClass;

	float SpawnRate = 2.5;
	float SpawnTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > SpawnTime)
		{
			SpawnTime = Time::GameTimeSeconds + SpawnRate;
			// TODO (FL): Are these networked?
			SpawnActor(MagicWaveClass, ActorLocation, ActorRotation);
			FGemFloorBreakerOnMagicWaveSpawnedParams Params;
			Params.SpawnLocation = ActorLocation;
			UGemFloorBreakerEventHandler::Trigger_OnMagicWaveSpawned(GemBreaker, Params);
			GemBreaker.PlayMagicUnleash();
		}
	}

	UFUNCTION()
	void ActivateMagicwaveSpawner()
	{
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void DeactivateMagicwaveSpawner()
	{
		SetActorTickEnabled(false);
	}
}