class ACrystalObstacleManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(4.0));
#endif

	UPROPERTY(EditAnywhere)
	TSubclassOf<ACrystalObstacle> CrystalObstacleClass;

	UPROPERTY(EditAnywhere)
	float StartDelay = 0.0;

	TArray<FVector> Positions;

	int Counter = 0;
	int MaxCount;

	UPROPERTY(EditAnywhere)
	float FireRate = 1.5;

	UPROPERTY(EditAnywhere)
	bool bStartActive = false;

	float FireTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Positions.Add(FVector(0.0));
		// Positions.Add(FVector(0.0, 150.0, 0.0));
		// Positions.Add(FVector(0.0, -150.0, 0.0));

		MaxCount = Positions.Num() - 1;

		SetActorTickEnabled(bStartActive);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > FireTime)
		{
			FireTime = Time::GameTimeSeconds + FireRate;
			SpawnObstacle();
		}		
	}

	void SpawnObstacle()
	{
		// FVector Location = ActorLocation + ActorRightVector * Positions[Counter].Y;

		ACrystalObstacle Obstacle = SpawnActor(CrystalObstacleClass, ActorLocation);
		Obstacle.AttachToActor(GetAttachParentActor(), NAME_None, EAttachmentRule::KeepWorld);

		// Counter++;

		// if (Counter > MaxCount)
		// 	Counter = 0;
	}

	UFUNCTION()
	void ActivateCrystalObstacleSpawner()
	{
		SetActorTickEnabled(true);
		FireTime = Time::GameTimeSeconds + StartDelay;
	}

	UFUNCTION()
	void DeactivateCrystalObstacleSpawner()
	{
		SetActorTickEnabled(false);
	}
};