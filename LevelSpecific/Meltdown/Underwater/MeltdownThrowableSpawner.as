class AMeltdownThrowableSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(EditInstanceOnly)
	TArray<AActor> SpawnLocations;

	UPROPERTY(EditAnywhere)
	TArray<TSubclassOf<AActor>> ThrowableClasses;

	UPROPERTY(EditAnywhere)
	float SpawnInterval = 5.0;

	private TArray<AActor> CurrentThrowables;
	private float Timer = 0.0;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentThrowables.SetNum(SpawnLocations.Num());
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Timer += DeltaSeconds;
		if (Timer >= SpawnInterval)
		{
			Timer = 0.0;

			TArray<int> OpenSlots;
			for (int i = 0, Count = CurrentThrowables.Num(); i < Count; ++i)
			{
				if (!IsValid(CurrentThrowables[i]))
					OpenSlots.Add(i);
			}

			if (OpenSlots.Num() != 0)
			{
				int SlotIndex = OpenSlots[Math::RandRange(0, OpenSlots.Num() - 1)];
				int ThrowableIndex = Math::RandRange(0, ThrowableClasses.Num() - 1);

				FVector Location = SpawnLocations[SlotIndex].ActorLocation;
				AActor Throwable = SpawnActor(ThrowableClasses[ThrowableIndex], Location);

				CurrentThrowables[SlotIndex] = Throwable;
			}
		}
	}
};