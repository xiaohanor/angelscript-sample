class ASkylineBallBossFinalLaser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LaserMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent TelegraphLaserMeshComp;

	FHazeAcceleratedVector AccTargetLocation;

	FVector TargetLocation;

	ASkylineBallBoss BallBoss;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY()
	FRuntimeFloatCurve AttackFloatCurve;

	UPROPERTY()
	UNiagaraSystem ImpactVFX;

	float TargetDuration = 2.0;

	bool bTargetingZoe = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BallBoss = Cast<ASkylineBallBoss>(AttachmentRootActor);
		BallBoss.OnPhaseChanged.AddUFunction(this, n"HandlePhaseChanged");

		AddActorDisable(this);
	}

	UFUNCTION()
	private void HandlePhaseChanged(ESkylineBallBossPhase NewPhase)
	{
		if (NewPhase == ESkylineBallBossPhase::TopMioInKillWeakpoint)
			Timer::SetTimer(this, n"Activate", 1.0);

		if (NewPhase == ESkylineBallBossPhase::TopSmallBoss)
			DisableActor();
	}

	UFUNCTION()
	private void Activate()
	{
		RemoveActorDisable(this);

		AccTargetLocation.SnapTo(ActorLocation + BallBoss.ActorForwardVector * 5000.0);

		BallBoss.bHasSnapRotation = true;

		QueueComp.SetLooping(true);
		QueueComp.Event(this, n"EndAttack");
		QueueComp.Duration(1.0, this, n"LockInTargetUpdate");
		QueueComp.Idle(1.0);
		QueueComp.Event(this, n"StopTargeting");
		QueueComp.Duration(0.5, this, n"AnticipationUpdate");
		QueueComp.Event(this, n"StartAttack");
		QueueComp.Duration(0.3, this, n"AttackUpdate");
	}

	UFUNCTION()
	private void LockInTargetUpdate(float Alpha)
	{
		TargetDuration = Math::Lerp(2.0, 0.0, Alpha);
	}

	UFUNCTION()
	private void StopTargeting()
	{
		bTargetingZoe = false;
	}

	UFUNCTION()
	private void AnticipationUpdate(float Alpha)
	{
		float CurrentValue = AttackFloatCurve.GetFloatValue(Alpha);

		float XYScale = Math::Lerp(0.05, 0.1, CurrentValue);

		TelegraphLaserMeshComp.SetRelativeScale3D(FVector(XYScale, XYScale, 5.0));
	}

	UFUNCTION()
	private void StartAttack()
	{
		TelegraphLaserMeshComp.SetHiddenInGame(true);
		LaserMeshComp.SetHiddenInGame(false);

		auto ImpactTrace = Trace::InitProfile(n"PlayerCharacter");
		ImpactTrace.IgnoreActor(BallBoss, true);

		auto ImpactHitResult = ImpactTrace.QueryTraceSingle(ActorLocation, ActorLocation + ActorForwardVector * 10000.0);

		if (ImpactHitResult.bBlockingHit)
			Niagara::SpawnOneShotNiagaraSystemAtLocation(ImpactVFX, ImpactHitResult.ImpactPoint);

		// Sweep only against the player
		FHazeTraceSettings PlayerTrace = Trace::InitAgainstComponent(Game::Zoe.CapsuleComponent);
		PlayerTrace.UseSphereShape(50.0);

		const FHitResult PlayerHitResult = PlayerTrace.QueryTraceComponent(ActorLocation, ActorLocation + ActorForwardVector * 10000.0);
		
		if (PlayerHitResult.bBlockingHit)
			Game::Zoe.DamagePlayerHealth(0.5, FPlayerDeathDamageParams(LaserMeshComp.UpVector, 2.0), BallBoss.LaserHeavyDamageEffect, BallBoss.LaserHeavyDeathEffect);

		BP_Blast();
	}

	UFUNCTION()
	private void AttackUpdate(float Alpha)
	{
		float CurrentValue = AttackFloatCurve.GetFloatValue(Alpha);

		float XYScale = CurrentValue;

		LaserMeshComp.SetRelativeScale3D(FVector(XYScale, XYScale, 5.0));
	}

	UFUNCTION()
	private void EndAttack()
	{
		TelegraphLaserMeshComp.SetHiddenInGame(false);
		LaserMeshComp.SetHiddenInGame(true);
		bTargetingZoe = true;

		USkylineBallBossBigLaserEventHandler::Trigger_FinalLaserActivated(this);
	}

	private void DisableActor()
	{
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bTargetingZoe)
			TargetLocation = Game::Zoe.ActorCenterLocation;

		AccTargetLocation.AccelerateTo(TargetLocation, TargetDuration, DeltaSeconds);
		SetActorRotation((AccTargetLocation.Value - ActorLocation).Rotation());
		BallBoss.SnapTargetLocation = AccTargetLocation.Value;
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Blast(){}
};