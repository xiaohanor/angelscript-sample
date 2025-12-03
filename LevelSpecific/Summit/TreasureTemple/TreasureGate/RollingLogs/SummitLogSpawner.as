class ASummitLogSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));

	UPROPERTY()
	TSubclassOf<ASummitRollingMetalLog> RollingLogMetalClass;
	UPROPERTY()
	TSubclassOf<ASummitRollingGoldenLog> RollingLogGoldClass;
	UPROPERTY()
	TSubclassOf<ASummitRollingGemLog> RollingLogGemClass;

	UPROPERTY()
	TSubclassOf<ASummitBoulder> BoulderClass;

	UPROPERTY(EditAnywhere)
	TArray<ASplineActor> SplineActors;

	UPROPERTY(EditAnywhere)
	AGemFloorBreaker GemBreaker;

	UFUNCTION(BlueprintEvent)
	void BP_SpawnObstacle(const TArray<AHazeActor> SpawnedObstacles) {};

	float LogSpeed = 2000.0;
	float BoulderSpeed = 2000.0;

	bool bSpawnLog;

	UPROPERTY(EditAnywhere)
	float SpawnRate = 2.2;
	UPROPERTY(EditAnywhere)
	float SpawnRateLog = 3.0;
	UPROPERTY(EditAnywhere)
	float SpawnRateAfterLog = 4.5;
	float SpawnTime;

	int Index = 0;
	int LogIndexCheck;
	int MaxLogIndex = 1;

	int AttackLogIndex;
	int SpawnedLogs = 0;

	bool bIsGem;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		//So that it starts with log spawn
		// bSpawnLog = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!HasControl())
			return;

		if (Time::GameTimeSeconds > SpawnTime)
		{
			SpawnTime = Time::GameTimeSeconds + SpawnRate;
			if (Network::IsGameNetworked())
			{
				NetRemoteSpawnObstacle();
				Timer::SetTimer(this, n"ControlSpawnObstacle", Network::PingOneWaySeconds, false);
			}
			else
				ControlSpawnObstacle();
		}
	}

	// Net function
	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetRemoteSpawnObstacle()
	{
		if(HasControl())
			return;

		SpawnObstacle();
	}

	UFUNCTION(NotBlueprintCallable)
	void ControlSpawnObstacle()
	{
		SpawnObstacle();
	}

	void SpawnObstacle()
	{
		if (bSpawnLog)
		{
			TArray<AHazeActor> SpawnedObstacles;

			for (int i = 0; i < SplineActors.Num(); i++)
			{
				if (i == AttackLogIndex)
				{
					if (bIsGem)
					{
						ASummitRollingGemLog Log = SpawnActor(RollingLogGemClass, SplineActors[i].ActorLocation, bDeferredSpawn = true);
						Log.Spline = SplineActors[i];
						Log.Speed = LogSpeed;
						Log.MakeNetworked(this, SpawnedLogs);
						SpawnedLogs++;
						FinishSpawningActor(Log);

						SpawnedObstacles.Add(Log);
					}
					else
					{
						ASummitRollingMetalLog Log = SpawnActor(RollingLogMetalClass, SplineActors[i].ActorLocation, bDeferredSpawn = true);
						Log.Spline = SplineActors[i];
						Log.Speed = LogSpeed;
						Log.MakeNetworked(this, SpawnedLogs);
						SpawnedLogs++;
						FinishSpawningActor(Log);

						SpawnedObstacles.Add(Log);
					}
				}
				else
				{
					ASummitRollingGoldenLog Log = SpawnActor(RollingLogGoldClass, SplineActors[i].ActorLocation, bDeferredSpawn = true);
					Log.Spline = SplineActors[i];
					Log.Speed = LogSpeed;
					Log.MakeNetworked(this, SpawnedLogs);
					SpawnedLogs++;
					FinishSpawningActor(Log);

					SpawnedObstacles.Add(Log);
				}
				
			}
			FGemFloorBreakerOnLogSpawnedParams Params;
			Params.SpawnLocation = SplineActors[1].ActorLocation; // Middle spline
			USummitLogSpawnerEventHandler::Trigger_OnLogSpawned(this, Params);
			BP_SpawnObstacle(SpawnedObstacles);
			
			bIsGem = !bIsGem;
			bSpawnLog = false;
		}
		else
		{
			ASummitBoulder Boulder = SpawnActor(BoulderClass, SplineActors[Index].ActorLocation, bDeferredSpawn = true);
			Boulder.Spline = SplineActors[Index];
			Boulder.Speed = BoulderSpeed;
			FinishSpawningActor(Boulder);
			LogIndexCheck++;
			Index++;

			if (LogIndexCheck > MaxLogIndex)
			{
				bSpawnLog = true;
				if(HasControl())
				{
					CrumbSetAttackLogIndex(Math::RandRange(0, 2));
				}
				LogIndexCheck = 0;
			}

			if (Index > SplineActors.Num() - 1)
				Index = 0;

			FGemFloorBreakerOnBoulderSpawnedParams Params;
			Params.SpawnLocation = Boulder.ActorLocation;
			USummitLogSpawnerEventHandler::Trigger_OnBoulderSpawned(this, Params);
		}

		if(GemBreaker != nullptr)
			GemBreaker.PlayThrowAnimation();
		
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbSetAttackLogIndex(int NewIndex)
	{
		AttackLogIndex = NewIndex;
	}

	UFUNCTION(CrumbFunction)
	void CrumbActivateLogSpawn()
	{
		SetActorTickEnabled(true);
	}

	UFUNCTION(CrumbFunction)
	void CrumbDeactivateLogSpawn()
	{
		SetActorTickEnabled(false);
	}
}