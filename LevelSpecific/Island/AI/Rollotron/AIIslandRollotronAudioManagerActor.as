class AAIIslandRollotronAudioManagerActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY(DefaultComponent)
	USoundDefContextComponent SoundDefComp;

	UPROPERTY(EditInstanceOnly)
	TArray<TSoftObjectPtr<AHazeActorSingleSpawner>> Spawners;

	private TArray<AAIIslandRollotron> SpawnedRollotrons;

	TArray<AAIIslandRollotron> GetRollotrons() const property
	{
		return SpawnedRollotrons;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(auto& SpawnerPtr : Spawners)
		{
			// If a single spawner isnt loaded, no spawners are loaded
			AHazeActorSingleSpawner Spawner = SpawnerPtr.Get();
			if(Spawner == nullptr)
			 	break;

			Spawner.OnPostSpawn.AddUFunction(this, n"OnSpawnRollotron");
			Spawner.OnPostUnspawn.AddUFunction(this, n"OnRemoveRollotron");

			SetActorTickEnabled(false);
		}
	}

	UFUNCTION()
	void OnSpawnRollotron(AHazeActor Actor)
	{
		SpawnedRollotrons.Add(Cast<AAIIslandRollotron>(Actor));
		UIslandRollotronEffectHandler::Trigger_OnWaveSpawned(this);
	}

	UFUNCTION()
	void OnRemoveRollotron(AHazeActor Actor)
	{
		SpawnedRollotrons.RemoveSingleSwap(Cast<AAIIslandRollotron>(Actor));
	}	
}