UCLASS(Abstract)
class ABounceBubbleSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SpawnerRoot;

	UPROPERTY(DefaultComponent, Attach = SpawnerRoot)
	USceneComponent SpawnLocationComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ABounceBubble> BubbleClass;

	UPROPERTY(EditInstanceOnly)
	ASplineActor TargetSpline;

	UPROPERTY(EditAnywhere)
	float SpawnDelay = 4.0;

	UPROPERTY(EditAnywhere)
	float Speed = 400.0;

	uint BubbleCount = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (HasControl())
			Timer::SetTimer(this, n"CrumbTimerSpawnBubble", SpawnDelay, true);

		PopulateSpline();
	}

	// Called on begin play so net safe
	void PopulateSpline()
	{
		for (int i = 0; i <= TargetSpline.Spline.SplineLength/(SpawnDelay * Speed); i++)
		{
			float DistanceAlongSpline = (SpawnDelay * Speed) * i;
			SpawnBubble(DistanceAlongSpline);
		}
	}

	void SpawnBubble(float DistanceAlongSpline)
	{
		BubbleCount++;

		ABounceBubble Bubble = SpawnActor(BubbleClass, SpawnLocationComp.WorldLocation, ActorRotation);
		Bubble.SpawnBubble(Speed, DistanceAlongSpline, TargetSpline, this);
		Bubble.MakeNetworked(this, BubbleCount);
	}

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	void CrumbTimerSpawnBubble()
	{
		SpawnBubble(0);
	}
}