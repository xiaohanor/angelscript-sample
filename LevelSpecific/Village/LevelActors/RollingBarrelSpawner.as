event void FBarrelIsSpawned();

class ARollingBarrelSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ARollingBarrel> BarrelClass;

	UPROPERTY(EditInstanceOnly)
	AVillageOgre_BarrelThrower Thrower;

	UPROPERTY(EditInstanceOnly)
	AVillageOgre_BarrelLoader Loader;

	UPROPERTY(EditInstanceOnly)
	ASplineActor LeftSpline;

	UPROPERTY(EditInstanceOnly)
	ASplineActor MiddleSpline;

	UPROPERTY(EditInstanceOnly)
	ASplineActor RightSpline;

	ASplineActor TargetSpline;

	UPROPERTY()
	FBarrelIsSpawned BarrelIsSpawned;

	bool bActive = false;
	FTimerHandle SpawnBarrelTimerHandle;

	EVillageBarrelThrowSide CurrentSide;
	EVillageBarrelThrowSide CurrentBarrelSide;

	int CurrentSideIndex = 0;
	TArray<EVillageBarrelThrowSide> Sides;
	default Sides.Add(EVillageBarrelThrowSide::Left);
	default Sides.Add(EVillageBarrelThrowSide::Right);
	default Sides.Add(EVillageBarrelThrowSide::Mid);
	default Sides.Add(EVillageBarrelThrowSide::Left);
	default Sides.Add(EVillageBarrelThrowSide::Left);
	default Sides.Add(EVillageBarrelThrowSide::Right);
	default Sides.Add(EVillageBarrelThrowSide::Left);
	default Sides.Add(EVillageBarrelThrowSide::Mid);
	default Sides.Add(EVillageBarrelThrowSide::Mid);
	default Sides.Add(EVillageBarrelThrowSide::Right);
	default Sides.Add(EVillageBarrelThrowSide::Left);
	default Sides.Add(EVillageBarrelThrowSide::Right);
	default Sides.Add(EVillageBarrelThrowSide::Mid);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActivateSpawner();

		SpawnInitialBarrels();
	}

	UFUNCTION()
	void ActivateSpawner()
	{
		if (bActive)
			return;

		bActive = true;
		SpawnBarrel();
		SpawnBarrelTimerHandle = Timer::SetTimer(this, n"TriggerBarrelSpawning", 2.0, true);

		Loader.PlayLoadAnimation();
	}

	UFUNCTION()
	private void TriggerBarrelSpawning()
	{
		if (!Network::IsGameNetworked())
		{
			SpawnBarrel();
		}
		else
		{
			// Send a message to spawn on the remote side, but delay spawning
			// by a half ping on the control side so they sync up better
			if (HasControl())
			{
				NetSpawnBarrelRemote();
				Timer::SetTimer(this, n"SpawnBarrel", Network::PingOneWaySeconds);
			}
		}
	}

	UFUNCTION(NetFunction)
	private void NetSpawnBarrelRemote()
	{
		if (!HasControl())
			SpawnBarrel();
	}

	UFUNCTION()
	void DeactivateSpawner()
	{
		bActive = false;
		SpawnBarrelTimerHandle.ClearTimerAndInvalidateHandle();
	}

	UFUNCTION()
	private void SpawnBarrel()
	{
		SetTargetSpline();

		ARollingBarrel Barrel = SpawnActor(BarrelClass, ActorLocation, ActorRotation);
		Barrel.Spawn(TargetSpline, CurrentBarrelSide);

		Thrower.PlayAnimation(CurrentSide);

		BarrelIsSpawned.Broadcast();
	}

	void SetTargetSpline()
	{
		CurrentSide = Sides[CurrentSideIndex];

		int BarrelSideIndex = CurrentSideIndex + 1;
		if (BarrelSideIndex > Sides.Num() - 1)
			BarrelSideIndex = 0;
		CurrentBarrelSide = Sides[BarrelSideIndex];

		if (CurrentBarrelSide == EVillageBarrelThrowSide::Left)
			TargetSpline = LeftSpline;
		else if (CurrentBarrelSide == EVillageBarrelThrowSide::Mid)
			TargetSpline = MiddleSpline;
		else if (CurrentBarrelSide == EVillageBarrelThrowSide::Right)
			TargetSpline = RightSpline;

		CurrentSideIndex++;
		if (CurrentSideIndex >= Sides.Num())
			CurrentSideIndex = 0;
	}

	void SpawnInitialBarrels()
	{
		for (int i = 0; i <= 5; i++)
		{
			ARollingBarrel Barrel = SpawnActor(BarrelClass, ActorLocation, ActorRotation);
			SetTargetSpline();
			Barrel.StartRollingWithoutDrop(i * 800.0, TargetSpline);
		}
	}
}

enum EVillageBarrelThrowSide
{
	Left,
	Mid,
	Right
}