class AGemFloorBreaker : ASummitNightQueenGem
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent OverlapBox;
	default OverlapBox.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	default OverlapBox.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent, Attach = SkelMesh)
	USceneComponent MagicWaveSpawnPosition;

	// UPROPERTY(DefaultComponent, Attach = "SkelMesh", AttachSocket = "Head")
    // USummitMeltPartComponent MeshMetalMask;

	// UPROPERTY(DefaultComponent, Attach = "SkelMesh", AttachSocket = "Head")
    // USummitMeltPartComponent CrystalMetalMask;

	float DesiredGravity = 5000.0;
	float Gravity;

	UPROPERTY(EditAnywhere, Category = "References")
	AActor MagicWaveSpawnPoint;

	UPROPERTY(EditAnywhere, Category = "References")
	AActor MagicWavePoint;

	UPROPERTY(EditAnywhere, Category = "References")
	AActor HoverPoint;

	UPROPERTY(EditAnywhere, Category = "References")
	AActor HidePoint;

	UPROPERTY(EditAnywhere, Category = "References")
	AActor BreakPoint;

	UPROPERTY(EditAnywhere, Category = "References")
	ASummitLogSpawner LogSpawner;

	UPROPERTY(EditAnywhere, Category = "References")
	AGiantBreakableObject BreakableWall;

	UPROPERTY(EditAnywhere, Category = "Setup")
	ASummitMetalGemMover HallwayBlockLocation;

	UPROPERTY(EditAnywhere, Category = "Setup")
	ASummitMetalGemMover BridgeBlockLocation;

	UPROPERTY()
	UAnimSequence ThrowAnim;
	UPROPERTY()
	UAnimSequence Idle;
	UPROPERTY()
	UAnimSequence ChargeAnim;
	UPROPERTY()
	UAnimSequence RoarAnim;

	//TArray<ABreakableIndividualFloor> LightningStrikePoints;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> FloorImpactCameraShake;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> MagicAttackCameraShake;

	UPROPERTY()
	UNiagaraSystem MagicWaveUnleashedSystem;


	bool bGoToPoint;
	bool bGoToMagicPoint;
	bool bGoToHover;
	bool bGoToHide;
	bool bStartBreak;
	bool bHaveBroken;
	bool bStartingMagicWave;

	bool bRemovePOI;
	float PoiRemoveTime;
	float PoiRemoveDuration = 1.0;

	FHazeAcceleratedVector AccelVector;
	TPerPlayer<UCameraPointOfInterest> POI;

	TPerPlayer<bool> bPoiSet;

	FRotator StartingRotation;

	FVector MagicWaveLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OverlapBox.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");

		PlayIdleAnimation();
		StartingRotation = ActorRotation;

		for(auto Player : Game::Players)
		{
			auto PlayerPoi = Player.CreatePointOfInterest();
			PlayerPoi.FocusTarget.SetFocusToActor(this);
			POI[Player] = PlayerPoi;
		}

		MagicWaveLocation = MagicWaveSpawnPosition.GetWorldLocation();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds) override
	{
		Super::Tick(DeltaSeconds);

		if (bGoToMagicPoint)
		{
			if ((ActorLocation - MagicWavePoint.ActorLocation).Size() < 5.0)
			{
				if (!bStartingMagicWave)
				{
					bStartingMagicWave = true;
					ActorRotation = StartingRotation;
					PlayIdleAnimation();
				}
			}
			else
			{
				ActorLocation = Math::VInterpConstantTo(ActorLocation, MagicWavePoint.ActorLocation, DeltaSeconds, 6000.0);
				FVector Direction = (MagicWavePoint.ActorLocation - ActorLocation).GetSafeNormal();
				Direction = Direction.ConstrainToPlane(FVector::UpVector);
				ActorRotation = Direction.Rotation() + FRotator(0.0, 0.0, 0.0);
			}
		}

		if (bGoToHover)
		{
			ActorLocation = Math::VInterpConstantTo(ActorLocation, HoverPoint.ActorLocation, DeltaSeconds, 2050.0);
			FVector Direction = (HoverPoint.ActorLocation - ActorLocation).GetSafeNormal();
			Direction = Direction.ConstrainToPlane(FVector::UpVector);
			ActorRotation = Direction.Rotation() + FRotator(0.0, 0, 0.0);

			if ((ActorLocation - HoverPoint.ActorLocation).Size() < 5.0)
			{
				bGoToHide = true;
				bGoToHover = false;
			}
		}

		if (bGoToHide)
		{
			ActorLocation = Math::VInterpConstantTo(ActorLocation, HidePoint.ActorLocation, DeltaSeconds, 2250.0);
			ActorRotation = StartingRotation;

			if ((ActorLocation - HidePoint.ActorLocation).Size() < 5.0)
			{
				bGoToHide = false;
				// PlayIdleAnimation();
			}
		}		

		if (bStartBreak)
		{
			ActorLocation = Math::VInterpConstantTo(ActorLocation, BreakPoint.ActorLocation, DeltaSeconds, 4000.0);
			for(auto Player : Game::Players)
			{
				if ((ActorLocation - BreakPoint.ActorLocation).Size() < 5.0)
				{
					Player.ClearPointOfInterestByInstigator(this);
					bStartBreak = false;				
				}
				else
				{
					if (bPoiSet[Player])
						return;

					POI[Player].FocusTarget.WorldOffset = FVector(0.0, 0.0, -1250.0);
					POI[Player].Apply(this, 1.5);
					bPoiSet[Player] = true;
				}
			}
		}
	}

	void HitBreakableFloor()
	{
		Gravity = 0.0;
	}

	UFUNCTION()
	void ActivateFleeToMagicWavePoint()
	{
		bGoToMagicPoint = true;
		PlayRunChargeAnimation();
		HallwayBlockLocation.ActivateBarrierMove();
	}

	UFUNCTION()
	void ActivateFleeToHoverPoint()
	{
		// Print("ActivateFleeToHoverPoint");
		bGoToMagicPoint = false;
		bGoToHover = true;
		BridgeBlockLocation.ActivateBarrierMove();
		// PlayRunChargeAnimation();
		PlayRunChargeSecondAnimation();
	}

	UFUNCTION()
	void ActivateGemFloorBreaker()
	{
		if (bHaveBroken)
			return;

		bHaveBroken = true;
		bStartBreak = true;
	}
	
	UFUNCTION()
	void ActivateLightningStrike()
	{
		// for (ABreakableIndividualFloor Floor : LightningStrikePoints)
		// {
		// 	Floor.ActivateLightningStrike();
		// }
	}

	UFUNCTION()
	void ActivateDoubleInteractBlocker()
	{

	}

	UFUNCTION()
	void BreakWall()
	{
		// BreakableWall.OnBreakGiantObject(FVector(1.0, 0.0, 0.0), 25000.0);
	}

	void PlayIdleAnimation()
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = Idle;
		Params.BlendTime = 0.5;
		Params.bLoop = true;
		SkelMesh.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);	
	}

	void PlayThrowAnimation()
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = ThrowAnim;
		Params.BlendTime = 0.25;
		FHazeAnimationDelegate EndThrowAnimation;
		// EndThrowAnimation.BindUFunction(this, n"EndThrowAnimation");
		SkelMesh.PlaySlotAnimation(FHazeAnimationDelegate(), EndThrowAnimation, Params);
		Timer::SetTimer(this, n"EndThrowAnimation", 0.5, false);
	}

	void PlayRunChargeAnimation()
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = ChargeAnim;
		Params.BlendTime = 0.5;
		Params.bLoop = true;
		SkelMesh.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);			
	}

	void PlayRunChargeSecondAnimation()
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = ChargeAnim;
		Params.BlendTime = 0.5;
		Params.bLoop = true;
		SkelMesh.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);			
	}

	void PlayMagicUnleash()
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = ThrowAnim;
		Params.BlendTime = 0.25;
		FHazeAnimationDelegate EndThrowAnimation;
		Game::Mio.PlayWorldCameraShake(MagicAttackCameraShake, this, ActorLocation, 4000.0, 13000);
		Game::Zoe.PlayWorldCameraShake(MagicAttackCameraShake, this, ActorLocation, 4000.0, 13000);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(MagicWaveUnleashedSystem, MagicWaveSpawnPosition.GetWorldLocation());
		SkelMesh.PlaySlotAnimation(FHazeAnimationDelegate(), EndThrowAnimation, Params);
		Timer::SetTimer(this, n"EndThrowAnimation", 0.5, false);
	}

	UFUNCTION()
	void PlayRoarAnimation()
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = RoarAnim;
		Params.BlendTime = 0.5;
		Params.bLoop = false;
		SkelMesh.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);	
	}

	UFUNCTION()
	private void EndThrowAnimation()
	{
		PlayIdleAnimation();
	}

	void ThrowBoulder()
	{
		UGemFloorBreakerEventHandler::Trigger_OnBoulderSpawned(this, FGemFloorBreakerOnMagicWaveSpawnedParams(ActorLocation));
	}

	void ThrowLog()
	{
		UGemFloorBreakerEventHandler::Trigger_OnLogSpawned(this, FGemFloorBreakerOnMagicWaveSpawnedParams(ActorLocation));
	}

	void RaiseBarriers()
	{
		UGemFloorBreakerEventHandler::Trigger_OnRaiseBarriers(this, FGemFloorBreakerOnMagicWaveSpawnedParams(ActorLocation));
	}

	void MagicWave()
	{
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		ATreasureBreakableFloor BreakableFloor = Cast<ATreasureBreakableFloor>(OtherActor);

		if (BreakableFloor != nullptr)
		{
			HitBreakableFloor();
			BreakableFloor.BreakFloor();
			bGoToPoint = true;
			AccelVector.SnapTo(ActorLocation);

			for(auto Player : Game::Players)
			{
				Player.PlayCameraShake(FloorImpactCameraShake, this);
			
				// POI[Player].FocusTarget.WorldOffset = FVector(0.0, 0.0, -1550.0);
				// POI[Player].Apply(this, 1.5);
			}
	
			PoiRemoveTime = Time::GameTimeSeconds + PoiRemoveDuration;
		}
	}
}