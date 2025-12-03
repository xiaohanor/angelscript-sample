class AMoonGuardianCatZeesManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY()
	TSubclassOf<AMoonGuardianCatZees> ZeeClass;

	float SpawnRate = 0.5;
	float SpawnTime;

	TArray<AMoonGuardianCatZees> CurrentZees;

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
			SpawnActor(ZeeClass, ActorLocation, ActorRotation);
		}
	}

	void SetZeeSpawning(bool bCanSpawn)
	{
		SetActorTickEnabled(bCanSpawn);

		if (!bCanSpawn)
		{
			SetActorTickEnabled(false);
		}
	}
};