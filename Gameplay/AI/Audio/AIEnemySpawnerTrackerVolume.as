
// Tracks the spawners inside of the volume, if they are active or not.
class AAIEnemySpawnerTrackerVolume : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(VisibleAnywhere)
	TArray<AHazeActorSpawnerBase> Spawners;

#if EDITOR
	UPROPERTY(EditAnywhere)
	float Range = 2000;

	UPROPERTY(DefaultComponent)
	UAIEnemySpawnerTrackerVolumeVisualizerComponent VisualizeComponent;
#endif

	private bool bActiveSpawners = false;

	UFUNCTION(BlueprintPure)
	bool AnyEnemiesActive()
	{
		return bActiveSpawners;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (auto Spawner : Spawners)
		{
			Spawner.OnDepleted.AddUFunction(this, n"OnSpawnerDepleted");
			Spawner.OnPostSpawn.AddUFunction(this, n"OnPostSpawn");

			if (!Spawner.IsDepleted() && Spawner.SpawnerComp.IsSpawnerActive())
			{
				bActiveSpawners = Spawner.SpawnerComp.IsSpawnerActive();
			}
		}
	}

	UFUNCTION()
	private void OnSpawnerDepleted(AHazeActor LastActor)
	{
		UpdateActiveSpawnersCheck();
	}

	UFUNCTION()
	private void OnPostSpawn(AHazeActor SpawnedActor)
	{
		UpdateActiveSpawnersCheck();
	}

	void UpdateActiveSpawnersCheck()
	{
		bool bNewState = false;
		for (auto Spawner : Spawners)
		{
			if (!Spawner.IsDepleted() && Spawner.SpawnerComp.IsSpawnerActive())
			{
				bNewState = true;
				break;
			}
		}

		bActiveSpawners = bNewState;
	}

#if EDITOR 
	// UFUNCTION(BlueprintOverride)
	// void Tick(float DeltaSeconds)
	// {
	// 	PrintToScreen(f"{ActorNameOrLabel} - HasActiveSpawners: {bActiveSpawners}");
	// }

	UFUNCTION(CallInEditor, Category = "Editor")
	void GatherSpawners()
	{
		Spawners.Empty();

		auto EditorSpawners = Editor::GetAllEditorWorldActorsOfClass(AHazeActorSpawnerBase);
		for(auto Spawner : EditorSpawners)
		{
			if(Spawner.Level != Level)
				continue;

			if(ActorLocation.Distance(Spawner.GetActorLocation()) < Range)
			{
				Spawners.Add(Spawner);
			}
		}
	}
#endif
};

#if EDITOR

class UAIEnemySpawnerTrackerVolumeVisualizerComponent : UActorComponent 
{
	default bIsEditorOnly = true;
}

class UAIEnemySpawnerTrackerVolumeVisualizer  : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UAIEnemySpawnerTrackerVolumeVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Volume = Cast<AAIEnemySpawnerTrackerVolume>(Component.Owner);
        if (Volume == nullptr)
            return;

		DrawWireSphere(Volume.ActorLocation, Volume.Range, FLinearColor::DPink);
	}
}

#endif