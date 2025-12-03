class ASummitStoneBeastCritterAOEManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent BillboardComp;
	default BillboardComp.SpriteName = "SkullAndBones";
	default BillboardComp.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditAnywhere)
	TArray<AHazeActorIntervalSpawner> Spawners;

	UPROPERTY(EditAnywhere)
	ASummitStoneBeastCritterAOESpline SpawnBoundary;

	UPROPERTY(EditAnywhere)
	float BetweenSpawnDuration = 2.0;
	UPROPERTY(EditAnywhere)
	float StartDelayDuration = 0.75;
	float NextSpawnTime;

	int ActiveOnes;

	AHazePlayerCharacter PlayerTarget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);

		//TESTING
		// ActivateAOESpawning(Game::Mio);

		for (AHazeActorIntervalSpawner Spawner : Spawners)
			Spawner.OnDepleted.AddUFunction(this, n"OnDepleted");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds < NextSpawnTime)
			return;

		for (AHazeActorIntervalSpawner Spawner : Spawners)
		{
			if (!Spawner.SpawnerComp.IsSpawnerActive())
			{
				RunSpawn(Spawner);
				break;
			}
			else
			{
				if (Spawner.IsDepleted())
				{
					Spawner.SpawnerComp.ResetSpawnPatterns();
					RunSpawn(Spawner);
					break;
				}
			}
		}	
	}

	UFUNCTION()
	private void OnDepleted(AHazeActor LastActor)
	{
		ActiveOnes--;
		NextSpawnTime = Time::GameTimeSeconds + BetweenSpawnDuration;
	}

	UFUNCTION()
	void ActivateAOESpawning(AHazePlayerCharacter Target)
	{
		PlayerTarget = Target;
		NextSpawnTime = Time::GameTimeSeconds + StartDelayDuration;
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void DeactivateAOESpawning()
	{
		SetActorTickEnabled(false);
		for (auto Spawner : Spawners)
		{
			Spawner.SpawnerComp.KillSpawnedAI();
			Spawner.DeactivateSpawner();
			Spawner.AddActorDisable(this);
		}
	}

	void RunSpawn(AHazeActorIntervalSpawner Spawner)
	{
		ActiveOnes++;

		//If still not reached max, set next spawn time
		if (ActiveOnes < Spawners.Num())
		{
			NextSpawnTime = Time::GameTimeSeconds + BetweenSpawnDuration;
		}

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.IgnoreActor(Game::Mio);
		TraceSettings.IgnoreActor(Game::Zoe);
		TraceSettings.UseLine();
		FHitResult Hit = TraceSettings.QueryTraceSingle(PlayerTarget.ActorCenterLocation, PlayerTarget.ActorCenterLocation - FVector::UpVector * 800.0);
		if (Hit.bBlockingHit)
		{
			Spawner.ActorLocation = Hit.ImpactPoint;
		}
		else
		{
			Spawner.ActorLocation = PlayerTarget.ActorLocation;
		}

		Spawner.ActorLocation = SpawnBoundary.GetClosestSpawnLocationToDesiredLocation(Spawner.ActorLocation); 

		//Debug::DrawDebugSphere(Spawner.ActorLocation, 200, 12, FLinearColor::Green, 5, 5);

		Spawner.ActorRotation = FRotator(0.0, PlayerTarget.ActorRotation.Yaw, 0.0);
		// Spawner.ActorLocation -= FVector::UpVector * 10.0;
		// Debug::DrawDebugSphere(Spawner.ActorLocation, 200.0, 12, FLinearColor::Blue, 2.5, 8.0);
		Spawner.ActivateSpawner();

		PlayerTarget = PlayerTarget.OtherPlayer;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		for (AHazeActorIntervalSpawner Spawner : Spawners)
			Debug::DrawDebugLine(ActorLocation, Spawner.ActorLocation, FLinearColor::Red, 15.0);
	}
#endif
};