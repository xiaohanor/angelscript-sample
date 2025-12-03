class ASummitExplodyFruitWallCrack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USummitDarkCaveSaveComponent SaveComp;

	UPROPERTY(DefaultComponent)
	USceneComponent LeftExplodeMoveRoot;

	UPROPERTY(DefaultComponent)
	USceneComponent RightExplodeMoveRoot;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent WallCrackMesh;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent DestructionSystem;
	default DestructionSystem.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	USummitExplodyFruitResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent)
	USummitStoneBallResponseComponent BallResponseComp;

	UPROPERTY(DefaultComponent)
	USummitBallNonBounceComponent NonBounceComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	UForceFeedbackEffect Rumble;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<ARespawnPointVolume> RespawnVolumes;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float FullyExplodedMoveAmount = 100.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	int ExplosionsUntilFullyBlownUp = 1;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float BallFuseMultiplierDistance = 2000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float BallFuseMultiplier = 1.0;

	UPROPERTY(EditInstanceOnly)
	AHazeLevelSequenceActor BreakSequence;

	FVector LeftStartRelativeLocation;
	FVector RightStartRelativeLocation;

	float TimesExploded = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnFruitExplode.AddUFunction(this, n"OnFruitExploded");
		BallResponseComp.OnStoneBallExploded.AddUFunction(this, n"OnBallExploded");
		
		LeftStartRelativeLocation = LeftExplodeMoveRoot.RelativeLocation;
		RightStartRelativeLocation = RightExplodeMoveRoot.RelativeLocation;

		for (ARespawnPointVolume Volume : RespawnVolumes)
		{
			Volume.DisableRespawnPointVolume(this);
		}

		SaveComp.OnSummitDarkCaveActivateSave.AddUFunction(this, n"OnSummitDarkCaveActivateSave");
	}

	UFUNCTION()
	void EnableRespawns()
	{
		for (ARespawnPointVolume Volume : RespawnVolumes)
		{
			Volume.EnableRespawnPointVolume(this);
		}
	}

	UFUNCTION()
	private void OnBallExploded(FSummitStoneBallExplosionParams Params)
	{
		GetExplodedOn();
	}

	UFUNCTION()
	private void OnSummitDarkCaveActivateSave()
	{
		AddActorDisable(this);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnFruitExploded(FSummitExplodyFruitExplosionParams Params)
	{
		GetExplodedOn();
	}

	private void GetExplodedOn()
	{
		BreakSequence.PlayLevelSequenceSimple();

		TimesExploded++;
		EnableRespawns();

		if(TimesExploded >= ExplosionsUntilFullyBlownUp)
		{
			
			for (AHazePlayerCharacter Player : Game::Players)
			{
				Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 3000, 20000);
				float Alpha = Math::Saturate(1 - (Player.ActorLocation - ActorLocation).Size() / 25000);
				Player.PlayForceFeedback(Rumble, false, true, this, Alpha);
			}

			WallCrackMesh.SetHiddenInGame(true);
			WallCrackMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			DestructionSystem.Activate();
			USummitExplodyFruitWallEventHandler::Trigger_OnWallExploded(this);
		}

		float AlphaToFullyExploded = TimesExploded / ExplosionsUntilFullyBlownUp; 
		float ExplodeMoveAmount = AlphaToFullyExploded * FullyExplodedMoveAmount;
		LeftExplodeMoveRoot.RelativeLocation = LeftStartRelativeLocation - ActorRightVector * ExplodeMoveAmount;
		RightExplodeMoveRoot.RelativeLocation = RightStartRelativeLocation + ActorRightVector * ExplodeMoveAmount;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugSphere(ActorLocation, BallFuseMultiplierDistance, 24, FLinearColor::LucBlue, 10);	
	}
#endif
};