#if EDITOR
class UStormFallRockVisualiser : UHazeScriptComponentVisualizer
{
	//TODO Visualise total fall distances from spawner actor
}
#endif

class UStormFallRockDudVisualiser : UActorComponent
{

}

class AStormFallRockSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10.0));	

	UPROPERTY(EditAnywhere, Category = "Setup")
	TSubclassOf<AStormFallRock> FallRockClass;

	UPROPERTY(EditAnywhere, Category = "Setup")
	float SpawnRate = 4.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	FStormFallRockParams RockParams;

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bStartActive = false;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<AStormFallRock> ActiveRocks;

	UPROPERTY(DefaultComponent)
	UStormFallRockDudVisualiser DudVisualiser;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	float SpawnTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RockParams.Spawner = this;
		
		for (AStormFallRock Rock : ActiveRocks)
			Rock.Params = RockParams;

		if (!bStartActive)
		{
			for (AStormFallRock Rock : ActiveRocks)
			{
				Rock.Params = RockParams;
				Rock.DeactivateFall();
			}

			SetActorTickEnabled(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > SpawnTime)
		{
			SpawnTime = Time::GameTimeSeconds + SpawnRate;
			SpawnRock();
		}
	}

	void SpawnRock()
	{
		AStormFallRock Rock = SpawnActor(FallRockClass, ActorLocation, bDeferredSpawn = true);
		Rock.Params = RockParams;
		FinishSpawningActor(Rock);
	}

	UFUNCTION()
	void ActivateStormRockSpawner()
	{
		for (AStormFallRock Rock : ActiveRocks)
		{
			Rock.ActivateFall();
		}

		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void DeactivateStormRockSpawner()
	{
		for (AStormFallRock Rock : ActiveRocks)
		{
			Rock.DeactivateFall();
		}

		SetActorTickEnabled(false);
	}
}