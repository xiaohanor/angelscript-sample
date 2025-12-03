class ASkylineBallBossDetonatorSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeDecalComponent DecalComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CarRoot;

	UPROPERTY(DefaultComponent, Attach = CarRoot)
	USceneComponent CarRollRoot;

	UPROPERTY(DefaultComponent, Attach = CarRoot)
	UHazeRawVelocityTrackerComponent VelocityTrackerComp;

	UPROPERTY(DefaultComponent, Attach = CarRollRoot)
	UStaticMeshComponent CarMesh;

	UPROPERTY(DefaultComponent, Attach = CarMesh)
	USkylineBallBossTractorBeamComponent TractorBeamVFXComp;

	UPROPERTY()
	UNiagaraSystem ExplosionVFXSystem;

	UPROPERTY()
	TSubclassOf<ASkylineBallBossThrowableDetonator> ThrowableDetonatorClass;

	UPROPERTY()
	float Damage = 0.6;

	UPROPERTY()
	float DamageRadius = 150.0;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueueComp;

	FHazeAcceleratedQuat AcceleratedQuat;

	FHazeTimeLike SpawnDecalTimeLike;
	default SpawnDecalTimeLike.UseSmoothCurveZeroToOne();
	default SpawnDecalTimeLike.Duration = 1.0;

	int SpawnedObjects = 0;
	ASkylineBallBoss BallBoss;

	bool bRotateAligningBoss = false;
	bool bSentDisintegrate = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		SpawnDecalTimeLike.BindUpdate(this, n"SpawnDecalTimeLikeUpdate");
		//FallingCarTimeLike.BindUpdate(this, n"FallingCarTimeLikeUpdate");
		//FallingCarTimeLike.BindFinished(this, n"FallingCarTimeLikeFinished");
		AddActorDisable(this);

		TListedActors<ASkylineBallBoss> BallBosses;
		BallBoss = BallBosses.Single;
		USkylineBallBossDetonatorSpawnerEventHandler::Trigger_OnSpawned(this);
		
		TractorBeamVFXComp.SetupTractorBeamMaterial(CarMesh);
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bSentDisintegrate)
			return;

		{
			FVector ForwardVector = VelocityTrackerComp.GetLastFrameDeltaTranslation();
			FRotator TargetRotation = FRotator::MakeFromXZ(ForwardVector, -ActorForwardVector);
			AcceleratedQuat.AccelerateTo(TargetRotation.Quaternion(), 1.0, DeltaSeconds);
			CarRoot.SetWorldRotation(AcceleratedQuat.Value);
			CarRollRoot.AddRelativeRotation(FRotator(0.0, 0.0, 360.0 * DeltaSeconds));
		}

		if (BallBoss.DisintegrationRadius > KINDA_SMALL_NUMBER)
			Disintegrate();
	}

	UFUNCTION()
	void Activate()
	{
		if (bSentDisintegrate)
			return;
		RemoveActorDisable(this);
		//FallingCarTimeLike.PlayFromStart();
		SpawnDecalTimeLike.PlayFromStart();

		TractorBeamVFXComp.Start();
		ActionQueueComp.Duration(1.0, this, n"RiseUpdate");
		ActionQueueComp.Event(this, n"TractorBeamLetGo");
		ActionQueueComp.Duration(2.0, this, n"ArchUpdate");
		ActionQueueComp.Event(this, n"StartTelegraphing");
		ActionQueueComp.Duration(2.0, this, n"FallUpdate");
		ActionQueueComp.Event(this, n"FallFinished");
	}

	UFUNCTION()
	private void TractorBeamLetGo()
	{
		TractorBeamVFXComp.TractorBeamLetGo();
	}

	UFUNCTION()
	private void RiseUpdate(float Alpha)
	{
		FVector RelativeLocation = FVector::UpVector * (Math::Lerp(-5000.0, 1000.0, Alpha));
		RelativeLocation -= FVector::ForwardVector * 6000.0;

		CarRoot.SetRelativeLocation(RelativeLocation);
	}

	UFUNCTION()
	private void ArchUpdate(float Alpha)
	{
		float CurrentValue = Curve::SmoothCurveZeroToOne.GetFloatValue(Alpha);

		FVector RelativeLocation = FVector::ForwardVector * (Math::Lerp(-6000.0, 0.0, CurrentValue));
		RelativeLocation += FVector::UpVector * (Math::Lerp(1000.0, 5000.0, CurrentValue) + Math::Sin(CurrentValue * PI) * 2000.0);

		CarRoot.SetRelativeLocation(RelativeLocation);
	}

	UFUNCTION()
	private void StartTelegraphing()
	{
		FSkylineBallBossMeteorEventHandlerParams Params;
		Params.TargetLocation = ActorLocation;
		USkylineBallBossMiscVOEventHandler::Trigger_MeteorCarTelegraph(BallBoss, Params);
	}

	UFUNCTION()
	private void FallUpdate(float Alpha)
	{
		FVector RelativeLocation = FVector::UpVector * (Math::Lerp(5000.0, 0.0, Alpha));

		CarRoot.SetRelativeLocation(RelativeLocation);
	}
	
	UFUNCTION()
	private void FallFinished()
	{
		if (HasControl())
			CrumbSpawnThrowableDetonator();

		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFXSystem, 
													ActorLocation + FVector::UpVector * 200.0, 
													FRotator());
		USkylineBallBossDetonatorSpawnerEventHandler::Trigger_OnImpact(this);
		BP_Exploded();
		AddActorDisable(this);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSpawnThrowableDetonator()
	{
		AActor SpawnedActor = SpawnActor(ThrowableDetonatorClass, ActorLocation + FVector::UpVector * 40.0, FRotator(90.0, 0.0, Math::RandRange(0.0, 360.0)), NAME_None, true);
		SpawnedActor.SetActorControlSide(Game::Zoe);
		SpawnedActor.MakeNetworked(this, SpawnedObjects);
		SpawnedObjects++;
		FinishSpawningActor(SpawnedActor);
		for (auto Player : Game::Players)
		{
			if (!Player.HasControl())
				continue;
			if (Player.ActorLocation.Distance(ActorLocation) < DamageRadius)
			{
				FVector DeathDir = (Player.ActorCenterLocation - ActorLocation).GetSafeNormal();
				Player.DamagePlayerHealth(Damage, FPlayerDeathDamageParams(DeathDir), BallBoss.ExplosionDamageEffect, BallBoss.ExplosionDeathEffect);
			}
		}
	}

	void Disintegrate()
	{
		if (HasControl())
		{
			bSentDisintegrate = true;
			SetActorEnableCollision(false);
			SetActorHiddenInGame(true);
			ActionQueueComp.Empty();

			CrumbActuallyDisintegrate();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbActuallyDisintegrate()
	{
		bSentDisintegrate = true;
		SetActorEnableCollision(false);
		SetActorHiddenInGame(true);
		ActionQueueComp.Empty();
		AddActorDisable(this);
		SetAutoDestroyWhenFinished(true);
	}

	UFUNCTION()
	private void SpawnDecalTimeLikeUpdate(float CurrentValue)
	{
		DecalComp.SetWorldScale3D(FVector(Math::Lerp(SMALL_NUMBER, 1.0, CurrentValue)));
	}

	UFUNCTION(BlueprintEvent)
	void BP_Exploded(){}
};