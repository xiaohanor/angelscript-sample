event void FArenaBombExplodedEvent(AArenaBomb Bomb);

UCLASS(Abstract)
class AArenaBomb : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BombRoot;

	UPROPERTY(DefaultComponent, Attach = BombRoot)
	UHazeSkeletalMeshComponentBase BombSkelMeshComp;

	UPROPERTY(DefaultComponent, Attach = BombRoot)
	UNiagaraComponent ThrusterEffectComp;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ExplodeEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> ExplodeCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ExplodeForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AHazeActor> TelegraphDecalClass;
	AHazeActor TelegraphDecalActor;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> ExplosionDeathEffect;
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> ExplosionDamageEffect;

	UPROPERTY(NotEditable)
	AHazePlayerCharacter TargetPlayer = nullptr;

	bool bLaunched = false;

	float ExplodeDelay = 3.5;
	float ExplosionRadius = 250.0;

	UPROPERTY(NotEditable)
	FVector TargetLocation = FVector::ZeroVector;

	FArenaBombExplodedEvent OnExploded;

	FHazeRuntimeSpline RuntimeSpline;

	bool bActive = false;

	float SplineDist = 0.0;
	float Speed = 4000.0;

	bool bExploded = false;

	void LaunchBomb(AActor BossActor, AHazePlayerCharacter Player, bool bDirectHit)
	{
		bool bValidHit = false;
		TargetPlayer = Player;

		TargetLocation = Player.ActorLocation + (FVector::UpVector * 500.0);
		float VelocityModifier = Math::GetMappedRangeValueClamped(FVector2D(0.0, 500.0), FVector2D(150.0, 500.0), Player.ActorVelocity.Size());
		if (bDirectHit)
			VelocityModifier = 0.0;

		TArray<FVector> TargetPoints;
		FVector InitialAngle = Player.ActorRightVector.RotateAngleAxis(-22.5, FVector::UpVector);
		for (int i = 0; i < 4; i++)
		{
			FVector Angle = InitialAngle.RotateAngleAxis(-22.5 * i, FVector::UpVector);
			FVector Loc = TargetLocation + (Angle * VelocityModifier);
			TargetPoints.Add(Loc);
		}

		TargetPoints.Shuffle();

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnorePlayers();
		Trace.IgnoreActor(this);
		Trace.IgnoreActor(BossActor);
		Trace.UseLine();

		for (int i = 0; i < 4; i++)
		{
			FHitResult Hit = Trace.QueryTraceSingle(TargetPoints[i], TargetPoints[i] - FVector(0.0, 0.0, 1000.0));
			if (Hit.bBlockingHit)
			{
				bValidHit = true;
				TargetLocation = Hit.Location;
				break;
			}
		}

		if (bValidHit)
		{
			bLaunched = true;

			UArenaBossBombEffectEventHandler::Trigger_BombLaunched(this);

			if (IsActorDisabled())
				RemoveActorDisable(this);
		}
		else
		{
			AddActorDisable(this);
			OnExploded.Broadcast(this);
			return;
		}

		FVector StartLoc = ActorLocation;
		FVector StartDir = ActorForwardVector;

		RuntimeSpline.AddPoint(StartLoc);

		RuntimeSpline.AddPoint(StartLoc + (StartDir * 200.0));

		FVector DirToTarget = (TargetLocation - StartLoc).GetSafeNormal();
		FVector MidPoint = StartLoc + (DirToTarget * 1200.0);
		MidPoint.Z = StartLoc.Z + 900.0;
		RuntimeSpline.AddPoint(MidPoint);

		FVector DirToOrigin = (StartLoc - TargetLocation).GetSafeNormal();
		FVector MidPoint2 = TargetLocation + (DirToOrigin * 1500.0);
		MidPoint2.Z = StartLoc.Z + 200.0;
		RuntimeSpline.AddPoint(MidPoint2);

		RuntimeSpline.AddPoint(TargetLocation);
		RuntimeSpline.SetCustomCurvature(1.0);

		TelegraphDecalActor = SpawnActor(TelegraphDecalClass, TargetLocation);
		TelegraphDecalActor.SetActorScale3D(FVector(1.4));

		bActive = true;
	}

	UFUNCTION(BlueprintEvent)
	void BP_LaunchBomb() {}

	void Explode()
	{
		bExploded = true;
		SetActorTickEnabled(false);

		if (TelegraphDecalActor != nullptr)
			TelegraphDecalActor.DestroyActor();

		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplodeEffect, ActorLocation);

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnoreActor(this);
		Trace.UseSphereShape(ExplosionRadius);

		FOverlapResultArray Overlaps = Trace.QueryOverlaps(ActorLocation);
		for (FOverlapResult Result : Overlaps)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Result.Actor);
			if (Player != nullptr && !Player.IsPlayerInvulnerable())
			{
				FVector DirToPlayer = (Player.ActorLocation - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
				if (DirToPlayer.Equals(FVector::ZeroVector))
					DirToPlayer = FVector::BackwardVector;
				FKnockdown Knockdown;
				Knockdown.Move = DirToPlayer * 300.0;
				Knockdown.Duration = 1.0;
				Player.ApplyKnockdown(Knockdown);
				
				Player.DamagePlayerHealth(0.5, FPlayerDeathDamageParams(DirToPlayer), ExplosionDamageEffect, ExplosionDeathEffect);
				Player.AddDamageInvulnerability(this, 1.0);
			}
		}

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayWorldCameraShake(ExplodeCamShake, this, ActorLocation, 600.0, 1200.0);

		ForceFeedback::PlayWorldForceFeedback(ExplodeForceFeedback, ActorLocation, true, this, 350.0, 150.0);

		UArenaBossBombEffectEventHandler::Trigger_BombExploded(this);

		BP_Destroy();

		BombSkelMeshComp.SetHiddenInGame(true);
		ThrusterEffectComp.Deactivate();

		OnExploded.Broadcast(this);
		
		Timer::SetTimer(this, n"DelayedDestroy", 1.0);

		//UArenaBossBombEffectEventHandler::Trigger_BombExploded(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Destroy() {}

	UFUNCTION()
	private void DelayedDestroy()
	{
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bExploded)
			return;

		if (!bActive)
			return;

		SplineDist += Speed * DeltaTime;
		FVector Loc = RuntimeSpline.GetLocationAtDistance(SplineDist);
		SetActorLocation(Loc);

		FRotator Rot = RuntimeSpline.GetRotationAtDistance(SplineDist);
		SetActorRotation(Rot);
		
		if (Loc.Equals(TargetLocation, 5.0))
			Explode();
	}
}