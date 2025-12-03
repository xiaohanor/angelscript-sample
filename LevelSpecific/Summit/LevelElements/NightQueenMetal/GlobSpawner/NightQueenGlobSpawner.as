class ANightQueenGlobSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;
	default Root.SetWorldScale3D(FVector(6.0));

	UPROPERTY(Category = "Setup")
	TSubclassOf<ANightQueenMetalGlob> GlobClass;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float SpawnInterval = 1.5;
	float SpawnTime;

	UPROPERTY(EditAnywhere, Category = "Settings")
	int SpawnSize = 6;

	UPROPERTY(EditAnywhere)
	TArray<ANightQueenMetalGlob> GlobArray;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (GlobArray.Num() == 0)
			SpawnPool();

		DeactivateAllGlobs();
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > SpawnTime)
		{
			ActivateGlob();
			SpawnTime = Time::GameTimeSeconds + SpawnInterval;
		}
	}

	void DeactivateAllGlobs()
	{
		for (ANightQueenMetalGlob Glob : GlobArray)
		{
			if (!Glob.IsActorDisabledBy(this))
				Glob.AddActorDisable(this);
		}
	}

	void ActivateGlob()
	{
		for (ANightQueenMetalGlob Glob : GlobArray)
		{
			if (Glob.IsActorDisabled())
			{
				Glob.ActorLocation = ActorLocation;
				Glob.RemoveActorDisable(this);
				// Glob.BoxComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
				// Glob.SetInstantActive();
				// Glob.OnNightQueenGlobDestroyed.AddUFunction(this, n"OnNightQueenGlobDestroyed");
				return;
			}
		}

		CreateGlob();
	}

	UFUNCTION(CallInEditor)
	void SpawnPool()
	{
		for (ANightQueenMetalGlob Glob : GlobArray)
		{
			Glob.DestroyActor();
		}

		GlobArray.Empty();

		for (int i = 0; i < SpawnSize; i++)
		{
			CreateGlob();
		}
	}

	void CreateGlob()
	{
		ANightQueenMetalGlob Glob = SpawnActor(GlobClass, ActorLocation);
		Glob.ActorLocation += FVector(0.0, 0.0, 800.0);
		Glob.OnNightQueenGlobDestroyed.AddUFunction(this, n"OnNightQueenGlobDestroyed");
		GlobArray.Add(Glob);		
	}

	UFUNCTION()
	private void OnNightQueenGlobDestroyed(ANightQueenMetalGlob Glob)
	{
		// Glob.OnNightQueenGlobDestroyed.UnbindObject(this);
		// Glob.BoxComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		if (!Glob.IsActorDisabledBy(this))
			Glob.AddActorDisable(this);
	}
}