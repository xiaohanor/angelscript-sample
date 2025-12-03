class ASkylineBallBossThrowableMotorcycle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MotorcycleRoot;

	UPROPERTY(DefaultComponent, Attach = MotorcycleRoot)
	UHazeRawVelocityTrackerComponent VelocityTrackerComp;

	UPROPERTY(DefaultComponent, Attach = MotorcycleRoot)
	USkylineBallBossTractorBeamComponent TractorBeamVFXComp;

	UPROPERTY()
	TSubclassOf<ASkylineBallBossThrowableMotorcycleAOE> AOEClass;

	UPROPERTY()
	UNiagaraSystem ExplosionVFX;

	UPROPERTY()
	TSubclassOf<AHazeActor> TelegraphActorClass;
	AHazeActor TelegraphActor;

	UPROPERTY()
	FHazeTimeLike ThrowTimeLike;
	default ThrowTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY()
	float ThrowSpeed = 3000.0;

	UPROPERTY()
	float Lifetime = 5.0;

	bool bTargeting = true;

	FHazeTimeLike SpawnTimeLike;
	default SpawnTimeLike.UseLinearCurveZeroToOne();

	ASkylineBallBossThrowableMotorcycleManager Manager;

	ASkylineBallBoss BallBoss;

	AHazePlayerCharacter TargetedPlayer;

	FVector TargetLocation;
	bool bTargetIsGrounded = false;

	FVector Velocity;
	bool bFlying = false;

	bool bRotateAligningBoss = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnTimeLike.BindUpdate(this, n"SpawnTimeLikeUpdate");
		SpawnTimeLike.BindFinished(this, n"SpawnTimeLikeFinished");
		ThrowTimeLike.BindUpdate(this, n"ThrowTimeLikeUpdate");
		ThrowTimeLike.BindFinished(this, n"ThrowTimeLikeFinished");

		SpawnTimeLike.Play();

		//Timer::SetTimer(this, n"EnableTractorBeam", SpawnTimeLike.Duration * 0.5);
		EnableTractorBeam();
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bTargeting)
		{
			SetActorRotation((TargetedPlayer.ActorLocation - ActorLocation).GetSafeNormal().Rotation());
		}

		if (bFlying)
		{
			MotorcycleRoot.AddWorldOffset(Velocity * DeltaSeconds);
		}
	}

	UFUNCTION()
	private void SpawnTimeLikeUpdate(float CurrentValue)
	{
		FVector Location = Math::Lerp(FVector::DownVector * Manager.DownwardSpawnOffset, 
										Manager.TargetLocationComp.RelativeLocation, CurrentValue);

		SetActorRelativeLocation(Location);
	}

	UFUNCTION()
	private void SpawnTimeLikeFinished()
	{
		AttachToComponent(Manager.RotatingRoot, NAME_None, EAttachmentRule::KeepWorld);
	}

	void Activate()
	{
		bTargeting = false;

		DetachFromActor(EDetachmentRule::KeepWorld);
		FindTargetLocation();
		BossStartRotateAlign();

		ThrowTimeLike.Play();

		Timer::SetTimer(this, n"Explode", Lifetime);
		Timer::SetTimer(this, n"DisableTractorBeam", 1.0);

		USkylineBallBossMiscVOEventHandler::Trigger_ExplodingMotorcycleThrow(BallBoss);
		USkylineBallBossThrowableMotorcycleEventHandler::Trigger_BikeThrow(this);
	}

	void Ignite()
	{
		USkylineBallBossThrowableMotorcycleEventHandler::Trigger_BikeIgnite(this);
		BP_Ignite();
	}

	private void FindTargetLocation()
	{
		auto Trace = Trace::InitProfile(n"PlayerCharacter");
		auto HitResult = Trace.QueryTraceSingle(TargetedPlayer.ActorLocation, TargetedPlayer.ActorLocation - FVector::UpVector * 1000.0);

		if (HitResult.bBlockingHit)
		{
			TargetLocation = HitResult.Location;
			bTargetIsGrounded = true;

			TelegraphActor = SpawnActor(TelegraphActorClass, TargetLocation);
		}
		else
		{
			TargetLocation = TargetedPlayer.ActorLocation;
		}
	}

	UFUNCTION()
	private void ThrowTimeLikeUpdate(float CurrentValue)
	{
		MotorcycleRoot.SetWorldLocation(Math::Lerp(ActorLocation, TargetLocation, CurrentValue));
	}

	UFUNCTION()
	private void ThrowTimeLikeFinished()
	{
		if (bTargetIsGrounded)
		{
			auto SpawnedAOE = SpawnActor(AOEClass, TargetLocation, bDeferredSpawn = true);

			float LifeTime = (Manager.Motorcycles.Num() * Manager.ThrowInterval * 1.1) + 2.0;

			PrintToScreen("LifeTime = " + LifeTime, 3.0);

			SpawnedAOE.Lifetime = LifeTime;
			FinishSpawningActor(SpawnedAOE);

			SpawnedAOE.AddActorLocalRotation(FRotator(0.0, Math::RandRange(0.0, 360.0), 0.0));

			Explode();
		}

		else
		{
			Velocity = VelocityTrackerComp.LastFrameTranslationVelocity;
			bFlying = true;
		}
	}

	UFUNCTION()
	private void EnableTractorBeam()
	{
		TractorBeamVFXComp.Start();
	}

	UFUNCTION()
	private void DisableTractorBeam()
	{
		TractorBeamVFXComp.TractorBeamLetGo();
		BossStopRotateAlign();
	}

	UFUNCTION()
	private void Explode()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFX, MotorcycleRoot.WorldLocation);
		USkylineBallBossThrowableMotorcycleEventHandler::Trigger_BikeExplosion(this);
		if (TelegraphActor != nullptr)
			TelegraphActor.DestroyActor();
		TelegraphActor = nullptr;
		DestroyActor();
	}

	private void BossStartRotateAlign()
	{
		if (!bRotateAligningBoss)
		{
			bRotateAligningBoss = true;
			bool bCarIsRightToBoss = BallBoss.ActorRightVector.DotProduct(ActorLocation - BallBoss.ActorLocation) > 0.0;
			FBallBossAlignRotationData AlignData;
			AlignData.BallLocalDirection = bCarIsRightToBoss ? FVector::RightVector : -FVector::RightVector;
			AlignData.OverrideTargetComp = MotorcycleRoot;
			AlignData.bContinuousUpdate = true;
			AlignData.bSnapOverTime = true;
			BallBoss.AddRotationTarget(AlignData);
		}
	}

	private void BossStopRotateAlign()
	{
		if (bRotateAligningBoss)
		{
			bRotateAligningBoss = false;
			BallBoss.RemoveRotationTarget(MotorcycleRoot);
		}
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Ignite() {}
};

class USkylineBallBossThrowableMotorcycleEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BikeIgnite()
	{
		//PrintToScreen("Smash", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BikeThrow()
	{
		//PrintToScreen("BikeThrow", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BikeExplosion()
	{
		//PrintToScreen("BikeExplosion", 5.0);
	}

};