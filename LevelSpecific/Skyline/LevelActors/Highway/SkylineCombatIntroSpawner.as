event void FSkylineCombatIntroSpawnerFinishedIntroSpawningEvent(TArray<AHazeActor> IntroActors);

class ASkylineCombatIntroSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Visual;
	default Visual.WorldScale3D = FVector(5.0);
#endif

	UPROPERTY(EditAnywhere)
	AHazeActorSpawnerBase Spawner;

	UPROPERTY(EditAnywhere)
	int IntroSpawningTarget = 5;

	UPROPERTY()
	FSkylineCombatIntroSpawnerFinishedIntroSpawningEvent OnFinishedIntroSpawning;

	UPROPERTY()
	TArray<AHazeActor> IntroActors;

	private bool bHasFinishedIntroSpawning;
	private int IntroSpawnNum;
	private bool bEnabled;
	private bool bPreEnabled;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Spawner);
		Spawner.OnPostSpawn.AddUFunction(this, n"PostSpawning");
	}

	UFUNCTION()
	private void PostSpawning(AHazeActor SpawnedActor)
	{
		if(!bPreEnabled)
			return;
		if(bHasFinishedIntroSpawning)
			return;
		IntroSpawnNum++;
		IntroActors.AddUnique(SpawnedActor);
		SpawnedActor.AddActorDisable(this);
		SpawnedActor.BlockCapabilities(n"Entrance", SpawnedActor);

		if(IntroSpawnNum == IntroSpawningTarget)
		{
			bHasFinishedIntroSpawning = true;
			if(bEnabled)
			{
				if(HasControl())
					CrumbIntroSpawningFinished(IntroActors);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbIntroSpawningFinished(TArray<AHazeActor> _IntroActors)
	{
		OnFinishedIntroSpawning.Broadcast(_IntroActors);
	}

	UFUNCTION()
	void EnableIntroActors()
	{
		for(AHazeActor Actor : IntroActors)
			Actor.RemoveActorDisable(this);
	}

	UFUNCTION()
	void PreEnable()
	{
		// !!! This will be called on both sides, but in order to ensure that bPreEnabled 
		// is set on both sides before any spawning we want remote side to decide when we are ready !!!
		if(!HasControl())
			CrumbRemotePreEnable();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbRemotePreEnable()
	{
		bPreEnabled = true;
		Spawner.ActivateSpawner();
	}

	UFUNCTION()
	void Enable()
	{
		bEnabled = true;
		bPreEnabled = true;

		if(bHasFinishedIntroSpawning)
		{
			if(HasControl())
				CrumbIntroSpawningFinished(IntroActors);
		}
	}

	UFUNCTION()
	void Disable()
	{
		bEnabled = false;
		bPreEnabled = false;
	}
}