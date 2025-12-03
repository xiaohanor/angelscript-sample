event void FSkylineEnforcerSentencedManagerSentencedEvent(AHazeActorSpawnerBase Spawner, int Index, int TotalSentenced);

class ASkylineEnforcerSentencedManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Visual;
	default Visual.WorldScale3D = FVector(5.0);
#endif

	UPROPERTY(EditAnywhere)
	TArray<AHazeActorSpawnerBase> Spawners;

	UPROPERTY()
	FSkylineEnforcerSentencedManagerSentencedEvent OnSentenced;

	UPROPERTY()
	FSkylineEnforcerSentencedManagerSentencedEvent OnPassiveSentenced;

	TMap<int, int> SentencedNum;
	TMap<int, int> PassiveSentencedNum;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		int Index = 0;
		for(auto Spawner : Spawners)
		{
			Spawner.OnPostSpawn.AddUFunction(this, n"Spawned");
			SentencedNum.Add(Index, 0);
			PassiveSentencedNum.Add(Index, 0);
			Index++;
		}		
	}

	UFUNCTION()
	private void Spawned(AHazeActor SpawnedActor)
	{
		USkylineEnforcerSentencedComponent SentencedComp = USkylineEnforcerSentencedComponent::GetOrCreate(SpawnedActor);
		SentencedComp.OnSentenced.AddUFunction(this, n"Sentenced");
		SentencedComp.OnPassiveSentenced.AddUFunction(this, n"PostSentenced");
	}

	UFUNCTION()
	private void PostSentenced(AHazeActorSpawnerBase Spawner)
	{
		int Index = Spawners.FindIndex(Spawner);
		PassiveSentencedNum.FindOrAdd(Index) += 1;
		OnPassiveSentenced.Broadcast(Spawner, Index, PassiveSentencedNum[Index]);
	}

	UFUNCTION()
	private void Sentenced(AHazeActorSpawnerBase Spawner)
	{
		int Index = Spawners.FindIndex(Spawner);
		SentencedNum.FindOrAdd(Index) += 1;
		OnSentenced.Broadcast(Spawner, Index, SentencedNum[Index]);
	}

	UFUNCTION()
	int GetSentencedAtIndex(int Index)
	{
		return SentencedNum[Index];
	}

	UFUNCTION()
	int GetPassiveSentencedAtIndex(int Index)
	{
		return PassiveSentencedNum[Index];
	}
}