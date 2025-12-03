class ASpaceWalkCometTrajectory : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MissileSpawnPoint;

	UPROPERTY(EditAnywhere)
	TArray<TSubclassOf<ASpaceWalkCometActor>> CometClasses;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	UPROPERTY(EditAnywhere)
	float CometSpeed;

	UPROPERTY(EditAnywhere)
	float FireRate = 2;

	float TimeToFire;
	int SpawnCounter = 0;

	UPROPERTY(EditAnywhere)
	bool bCanFire;

	UPROPERTY()
	FVector CometSpawnLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TimeToFire = Time::GameTimeSeconds + FireRate;
	}

	UFUNCTION(BlueprintCallable)
	void InstantlyLaunch()
	{
		if (HasControl())
			NetSpawnComet(CometClasses[Math::RandRange(0, CometClasses.Num()-1)], Math::RandomRotator(false));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bCanFire != true)
			return;

		if(TimeToFire > Time::GameTimeSeconds)
				return;

		TimeToFire = Time::GameTimeSeconds + FireRate;

		if (HasControl())
			NetSpawnComet(CometClasses[Math::RandRange(0, CometClasses.Num()-1)], Math::RandomRotator(false));
	}

	UFUNCTION(NetFunction)
	void NetSpawnComet(TSubclassOf<ASpaceWalkCometActor> CometClass, FRotator Rotation)
	{
		ASpaceWalkCometActor Comet = SpawnActor(CometClass, ActorLocation, Rotation, bDeferredSpawn = true);
		Comet.MakeNetworked(this, SpawnCounter);
		Comet.SplineComp = SplineActor.Spline;
		Comet.Speed = CometSpeed;
		SpawnCounter += 1;
		FinishSpawningActor(Comet);
	}

	UFUNCTION(CrumbFunction)
	void CrumbShootMissile()
	{
	//	CometSpawnLocation = MissileSpawnPoint.WorldLocation;
	//	ASpaceWalkCometActor CometSpawned = SpawnActor(Comet, CometSpawnLocation, ActorRotation, bDeferredSpawn = true);
	//	CometSpawned.SplineComp = SplineActor.Spline;
	//	FinishSpawningActor(CometSpawned);
	//	CometSpawned.Speed = CometSpeed;
	}
};