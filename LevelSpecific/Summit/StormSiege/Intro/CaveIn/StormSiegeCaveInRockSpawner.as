class AStormSiegeCaveInRockSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(15.0));
#endif

	UPROPERTY()
	TSubclassOf<AStormSiegeCaveInRock> RockClass;

	float RandTime;
	float MinTime = 1.5;
	float MaxTime = 3.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);	
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds < RandTime)
			return;

		RandTime = Time::GameTimeSeconds + Math::RandRange(MinTime, MaxTime);

		SpawnActor(RockClass, ActorLocation);
	}

	UFUNCTION()
	void ActivateSpawner()
	{
		RandTime = Time::GameTimeSeconds + Math::RandRange(MinTime, MaxTime);
		SetActorTickEnabled(true);	
	}

	UFUNCTION()
	void DeactivateSpawner()
	{
		SetActorTickEnabled(false);	
	}
}


class AStormSiegeCaveInRockSpawnerManager : AHazeActor
{
	UFUNCTION(BlueprintPure)
	TArray<AStormSiegeCaveInRockSpawner> GetAllStormSiegeCaveInRockSpawner() const
	{
		return TListedActors<AStormSiegeCaveInRockSpawner>().Array;
	}
}