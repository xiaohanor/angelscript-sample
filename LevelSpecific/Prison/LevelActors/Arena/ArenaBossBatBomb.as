UCLASS(Abstract)
class AArenaBossBatBomb : AHazeActor
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

	UPROPERTY(NotEditable)
	AHazePlayerCharacter TargetPlayer = nullptr;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AHazeActor> TelegraphDecalClass;
	AHazeActor TelegraphDecalActor;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> ExplosionDeathEffect;
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> ExplosionDamageEffect;

	bool bLaunched = false;

	float ExplodeDelay = 3.5;
	float ExplosionRadius = 250.0;
	bool bExploded = false;

	FArenaBombExplodedEvent OnExploded;

	FHazeRuntimeSpline RuntimeSpline;
	float SplineDist = 0.0;

	bool bActive = false;

	float Speed = 6000.0;
	float MinSpeed = 5500.0;
	float MaxSpeed = 6500.0;

	FVector TargetLocation;

	UPROPERTY(EditAnywhere)
	UPrimitiveComponent TargetPrimitiveComp;

	void LaunchedFromSocket()
	{
		UArenaBossBatBombEffectEventHandler::Trigger_Launch(this);
	}

	void LaunchBomb(AActor BossActor, AHazePlayerCharacter Player, bool bDirectHit)
	{
		bool bValidHit = false;
		TargetPlayer = Player;

		FVector TargetLoc = Player.ActorLocation + (FVector::UpVector * 500.0);
		float VelocityModifier = Math::GetMappedRangeValueClamped(FVector2D(0.0, 500.0), FVector2D(200.0, 400.0), Player.ActorVelocity.Size());
		float RandomOffset = Math::RandRange(0.0, 200.0);
		if (bDirectHit)
		{
			VelocityModifier = 0.0;
			RandomOffset = 0.0;
		}

		Speed = Math::RandRange(MinSpeed, MaxSpeed);

		TArray<FVector> TargetPoints;
		for (int i = 0; i < 8; i++)
		{
			FVector Angle = Player.ActorRightVector.RotateAngleAxis(Math::RandRange(-40.0, -50.0) * i, FVector::UpVector);
			FVector Loc = TargetLoc + (Angle  * (VelocityModifier + RandomOffset));
			TargetPoints.Add(Loc);
		}

		TargetPoints.Shuffle();

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnorePlayers();
		Trace.IgnoreActor(this);
		Trace.IgnoreActor(BossActor);
		Trace.UseLine();

		for (int i = 0; i < 8; i++)
		{
			FHitResult Hit = Trace.QueryTraceSingle(TargetPoints[i], TargetPoints[i] - FVector(0.0, 0.0, 1000.0));
			if (Hit.bBlockingHit)
			{
				bValidHit = true;
				TargetLoc = Hit.Location;
				if (Hit.Component != nullptr)
					TargetPrimitiveComp = Hit.Component;
				break;
			}
		}

		DetachFromActor(EDetachmentRule::KeepWorld);

		if (bValidHit)
		{
			bLaunched = true;
			BP_LaunchBomb();

			UArenaBossBatBombEffectEventHandler::Trigger_BatImpact(this);

			if (IsActorDisabled())
				RemoveActorDisable(this);
		}
		else
		{
			AddActorDisable(this);
			return;
		}

		TargetLocation = TargetLoc;

		RuntimeSpline.AddPoint(ActorLocation);

		FVector DirToTarget = (TargetLoc - ActorLocation).GetSafeNormal();
		FVector MidPoint = ActorLocation + (DirToTarget * 1200.0);
		MidPoint.Z = ActorLocation.Z + 400.0;
		RuntimeSpline.AddPoint(MidPoint);

		FVector DirToOrigin = (ActorLocation - TargetLoc).GetSafeNormal();
		FVector MidPoint2 = TargetLoc + (DirToOrigin * 2500.0);
		MidPoint2.Z = ActorLocation.Z + -200.0;
		RuntimeSpline.AddPoint(MidPoint2);

		RuntimeSpline.AddPoint(TargetLoc);
		RuntimeSpline.SetCustomCurvature(1.0);

		float DecalDelay = Math::GetMappedRangeValueClamped(FVector2D(MinSpeed, MaxSpeed), FVector2D(0.3, 0.01), Speed);
		Timer::SetTimer(this, n"ShowDelayedDecal", DecalDelay, false);

		bActive = true;
	}

	UFUNCTION()
	private void ShowDelayedDecal()
	{
		TelegraphDecalActor = SpawnActor(TelegraphDecalClass, TargetLocation);
		TelegraphDecalActor.SetActorScale3D(FVector(1.2));
	}

	UFUNCTION(BlueprintEvent)
	void BP_LaunchBomb() {}

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
			Destroy();

		// RuntimeSpline.DrawDebugSpline();
	}

	void Destroy()
	{
		bExploded = true;
		SetActorTickEnabled(false);

		if (TelegraphDecalActor != nullptr)
			TelegraphDecalActor.DestroyActor();

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

		UArenaBossBatBombEffectEventHandler::Trigger_Explode(this);

		BombSkelMeshComp.SetHiddenInGame(true);
		ThrusterEffectComp.Deactivate();

		Timer::SetTimer(this, n"DelayedDestroy", 1.0);
		BP_Destroy();
	}

	UFUNCTION()
	private void DelayedDestroy()
	{
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Destroy() {}
}

class UArenaBossBatBombEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void Launch() {}
	UFUNCTION(BlueprintEvent)
	void BatImpact() {}
	UFUNCTION(BlueprintEvent)
	void Explode() {}
}