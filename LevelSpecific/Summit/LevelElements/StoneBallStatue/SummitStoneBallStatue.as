class ASummitStoneBallStatue : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent ActivatorRoot;

	UPROPERTY(DefaultComponent)
	USceneComponent StoneSpawnRoot;

	UPROPERTY(DefaultComponent)
	USceneComponent StoneSpawnThroatRoot;

	UPROPERTY(DefaultComponent)
	USceneComponent StoneExitRoot;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TSubclassOf<ASummitRollingActivator> ActivatorClass;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASummitRollingActivator Activator;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TSubclassOf<ASummitStoneBall> StoneBallClass;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float StoneBallEnterSpeed = 2500.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	int MaxBallsToSpawn = 3;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bExplodeOldestWhenOverLimit = false;

	UHazeActorNetworkedSpawnPoolComponent SpawnPoolComp;

	TArray<ASummitStoneBall> TrackedBalls;

	int BallsSpawned = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);

		if(Activator != nullptr)
			Activator.OnActivated.AddUFunction(this, n"OnActivatorActivated");

		SpawnPoolComp = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(StoneBallClass, Game::Zoe);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnActivatorActivated(FSummitRollingActivatorActivationParams Params)
	{			
		if(!HasControl())
			return;

		if(BallsSpawned >= MaxBallsToSpawn)
		{
			if (!bExplodeOldestWhenOverLimit)
				return;

			TrackedBalls[0].Explode();
		}

		FHazeActorSpawnParameters SpawnParams;
		SpawnParams.Location = StoneSpawnRoot.WorldLocation;
		SpawnParams.Rotation = FRotator::ZeroRotator;
		auto StoneBallActor = SpawnPoolComp.SpawnControl(SpawnParams);
		auto StoneBall = Cast<ASummitStoneBall>(StoneBallActor);
		StoneBall.CrumbResetPostRespawn(this);
		
		if (bExplodeOldestWhenOverLimit)
			TrackBall(StoneBall);

		FSummitStoneBallStatueOnBallSpawnedParams EventParams;
		EventParams.BallsRemaining = MaxBallsToSpawn - BallsSpawned;
		USummitStoneBallStatueEventHandler::Trigger_OnBallSpawned(this, EventParams);

		BallsSpawned++;
	}

	private void TrackBall(ASummitStoneBall StoneBall)
	{
		TrackedBalls.Add(StoneBall);
		StoneBall.OnExploded.AddUFunction(this, n"UnTrackBall");
	}

	UFUNCTION()
	private void UnTrackBall(ASummitStoneBall StoneBall)
	{
		StoneBall.OnExploded.Unbind(this, n"UnTrackBall");
		TrackedBalls.Remove(StoneBall);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		if(ActivatorClass == nullptr)
			return;	

		Debug::DrawDebugCylinder(ActivatorRoot.WorldLocation, ActivatorRoot.WorldLocation + ActivatorRoot.ForwardVector * 350, 150, 24, FLinearColor::Red, 10, 0);

		auto EnterSpline = GetEnterSpline();
		FDebugDrawRuntimeSplineParams DrawParams;
		DrawParams.Duration = 0.0;
		DrawParams.LineType = EDebugDrawRuntimeSplineLineType::Lines;
		DrawParams.bDrawInForeground = true;
		DrawParams.MovingPointSpeed = StoneBallEnterSpeed / EnterSpline.Length;
		EnterSpline.DrawDebugSpline(DrawParams);
	}
#endif

	UFUNCTION(CallInEditor, Category = "Setup")
	void SpawnActivator()
	{
		if(ActivatorClass == nullptr)
			return;
		
		if (Activator != nullptr)
			Activator.DestroyActor();

		Activator = SpawnActor(ActivatorClass, ActivatorRoot.WorldLocation, ActivatorRoot.WorldRotation);
		Activator.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);
	}

	FHazeRuntimeSpline GetEnterSpline() const
	{
		FHazeRuntimeSpline EnterSpline;
		EnterSpline.AddPointWithUpDirection(StoneSpawnRoot.WorldLocation, StoneSpawnRoot.UpVector);
		EnterSpline.AddPointWithUpDirection(StoneSpawnThroatRoot.WorldLocation, StoneSpawnThroatRoot.UpVector);
		EnterSpline.AddPointWithUpDirection(StoneExitRoot.WorldLocation, StoneExitRoot.UpVector);

		return EnterSpline;
	}
};