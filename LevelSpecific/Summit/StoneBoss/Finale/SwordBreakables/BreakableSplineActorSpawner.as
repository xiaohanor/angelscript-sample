struct FStoneBreakableSplineData
{
	UPROPERTY(EditAnywhere)
	TSubclassOf<AStoneBreakableSplineActor> StoneSplineClass;

	UPROPERTY(EditAnywhere)
	ASplineActor Spline;

	UPROPERTY(EditAnywhere)
	float SpawnDelayTime;

	UPROPERTY(EditAnywhere)
	float SpawnTime;

	UPROPERTY(EditAnywhere)
	float Speed = 200.0;
}

class ABreakableSplineActorSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(6.0));
#endif

	UPROPERTY(EditAnywhere)
	TSubclassOf<AStoneBreakableSplineActor> StoneSplineClass;

	UPROPERTY(EditAnywhere)
	TArray<FStoneBreakableSplineData> SplineData;

	UPROPERTY(EditAnywhere)
	bool bStartActive = false;

	UPROPERTY(EditAnywhere)
	float OverrideSpeed = -1.0;

	UPROPERTY(EditAnywhere)
	float SpawnRate = 1.6;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);

		if (bStartActive)
			ActivateBreakableSpawning();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (FStoneBreakableSplineData& Data : SplineData)
		{
			Data.SpawnTime -= DeltaSeconds;

			while (Data.SpawnTime <= 0.0)
			{
				Data.SpawnTime += SpawnRate;
				
				if (OverrideSpeed > 0.0)
					Data.Speed = OverrideSpeed;

				if (Data.StoneSplineClass == nullptr)
				{
					SpawnNewSplineBreakable(Data, StoneSplineClass);
				}
				else
				{
					SpawnNewSplineBreakable(Data, Data.StoneSplineClass);
				}
			}
		}
	}

	UFUNCTION()
	void ActivateBreakableSpawning()
	{
		SetActorTickEnabled(true);

		for (FStoneBreakableSplineData& Data : SplineData)
		{
			Data.SpawnTime = SpawnRate + Data.SpawnDelayTime;
		}
	}

	UFUNCTION()
	void DeactivateBreakableSpawning()
	{
		SetActorTickEnabled(false);
	}

	void SpawnNewSplineBreakable(FStoneBreakableSplineData Data, TSubclassOf<AStoneBreakableSplineActor> NewBreakableClass)
	{
		AStoneBreakableSplineActor Breakable = SpawnActor(NewBreakableClass, ActorLocation, bDeferredSpawn = true);
		Breakable.Spline = Data.Spline.Spline;
		Breakable.Speed = Data.Speed;
		FinishSpawningActor(Breakable);
	}
};