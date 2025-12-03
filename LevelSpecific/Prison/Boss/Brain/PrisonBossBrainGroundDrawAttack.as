UCLASS(Abstract)
class APrisonBossBrainGroundDrawAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent EmitterRoot;

	UPROPERTY(DefaultComponent, Attach = EmitterRoot)
	UNiagaraComponent LaserComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TargetRoot;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem TrailSystem;

	FHazeRuntimeSpline RuntimeSpline;

	UPROPERTY(NotEditable)
	UNiagaraComponent TrailComp;

	UPROPERTY(BlueprintReadOnly)
	EPrisonBossDrawAttackType AttackType;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	bool bBeamActive = false;

	float SplineDist = 0.0;

	float MinSpawnDistance = 2600.0;
	float MaxSpawnDistance = 4200.0;

	bool bShapeCompleted = false;
	float ShapeLifeTime = 0.0;

	bool bBeamExtended = false;
	bool bBeamRetracting = false;
	FVector RetractDirection;
	float RetractDistance = 0.0;
	UPROPERTY(BlueprintReadOnly)
	FVector BeamTargetLoc;

	float DrawSpeed;

	void Activate(ASplineActor Spline, AActor Mid, EPrisonBossDrawAttackType Type, bool bStaticLocation = false)
	{
		DrawSpeed = Math::RandRange(PrisonBoss::DrawAttackSpeedRange.X, PrisonBoss::DrawAttackSpeedRange.Y);

		AttackType = Type;

		FVector SpawnLoc = Game::Mio.ActorCenterLocation;
		SpawnLoc += Game::Mio.ActorHorizontalVelocity.GetSafeNormal() * 600.0;

		FVector DirFromMidToSpawnPoint = (SpawnLoc - Mid.ActorLocation).GetSafeNormal().ConstrainToPlane(FVector::UpVector);
		float Dist = Mid.ActorLocation.Distance(SpawnLoc);
		SpawnLoc = Mid.ActorLocation + (DirFromMidToSpawnPoint * Math::Clamp(Dist, MinSpawnDistance, MaxSpawnDistance));

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_WorldStatic);
		Trace.IgnorePlayers();
		Trace.UseLine();

		FHitResult DownHit = Trace.QueryTraceSingle(SpawnLoc, SpawnLoc - (FVector::UpVector * 400.0));
		if (!DownHit.bBlockingHit)
		{
			DestroyActor();
			return;
		}

		SpawnLoc.Z = Math::Max(Mid.ActorLocation.Z - 20.0, DownHit.ImpactPoint.Z);

		if (Type == EPrisonBossDrawAttackType::Line)
		{
			if (!bStaticLocation)
			{
				float RotOffset = Math::RandRange(-10.0, 10.0);
				Spline.SetActorRotation(DirFromMidToSpawnPoint.Rotation() + FRotator(0.0, RotOffset, 0.0));
			}

			SpawnLoc = Mid.ActorLocation + (DirFromMidToSpawnPoint * 2450.0);
			if (bStaticLocation)
				SpawnLoc = Spline.ActorLocation;

			for (FHazeSplinePoint SplinePoint : Spline.Spline.SplinePoints)
			{
				FTransform Transform = FTransform(Spline.ActorRotation, SpawnLoc);
				FVector Loc = Transform.TransformPosition(SplinePoint.RelativeLocation);
				RuntimeSpline.AddPoint(Loc);
			}
		}

		else
		{
			for (FHazeSplinePoint SplinePoint : Spline.Spline.SplinePoints)
			{
				FTransform Transform = FTransform(FRotator::ZeroRotator, SpawnLoc);
				FVector Loc = Transform.TransformPosition(SplinePoint.RelativeLocation);
				RuntimeSpline.AddPoint(Loc);
			}

			RuntimeSpline.AddPoint(RuntimeSpline.GetLocationAtDistance(0.0));
			RuntimeSpline.AddPoint(RuntimeSpline.GetLocation(0.05));
		}

		SplineDist = 0.0;
		
		TargetRoot.DetachFromParent(true, false);
		TargetRoot.SetWorldLocation(RuntimeSpline.GetLocationAtDistance(0.0));

		TrailComp = Niagara::SpawnLoopingNiagaraSystemAttached(TrailSystem, TargetRoot);
		TrailComp.Activate(true);

		BeamTargetLoc = EmitterRoot.WorldLocation;
		bBeamActive = true;

		UPrisonBossBrainGroundDrawAttackEffectEventHandler::Trigger_ActivateBeam(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bBeamRetracting)
		{
			LaserComp.SetVectorParameter(n"BeamStart", EmitterRoot.WorldLocation);
			RetractDistance = Math::Clamp(RetractDistance - (12000.0 * DeltaTime), 0.0, BIG_NUMBER);
			LaserComp.SetVectorParameter(n"BeamEnd", EmitterRoot.WorldLocation + (RetractDirection * RetractDistance));
			if (Math::IsNearlyEqual(RetractDistance, 0.0))
			{
				bBeamRetracting = false;
				LaserComp.DeactivateImmediate();

				UPrisonBossBrainGroundDrawAttackEffectEventHandler::Trigger_BeamFullyRetracted(this);
			}
				
		}
		else if (bBeamActive)
		{
			if (bBeamExtended)
			{
				SplineDist += DrawSpeed * DeltaTime;
				
				FVector TargetLoc = RuntimeSpline.GetLocationAtDistance(SplineDist);
				TargetRoot.SetWorldLocation(TargetLoc);

				LaserComp.SetVectorParameter(n"BeamStart", EmitterRoot.WorldLocation);
				LaserComp.SetVectorParameter(n"BeamEnd", TrailComp.WorldLocation);
				LaserComp.SetFloatParameter(n"Width", 100.0);

				if (SplineDist >= RuntimeSpline.Length)
				{
					bBeamActive = false;
					bShapeCompleted = true;
					RetractDirection = (TargetLoc - EmitterRoot.WorldLocation).GetSafeNormal();
					RetractDistance = EmitterRoot.WorldLocation.Distance(BeamTargetLoc);
					bBeamRetracting = true;

					UPrisonBossBrainGroundDrawAttackEffectEventHandler::Trigger_ShapeCompleted(this);
				}
			}
			else
			{
				LaserComp.SetVectorParameter(n"BeamStart", EmitterRoot.WorldLocation);
				BeamTargetLoc = Math::VInterpConstantTo(BeamTargetLoc, TrailComp.WorldLocation, DeltaTime, 8000.0);
				LaserComp.SetVectorParameter(n"BeamEnd", BeamTargetLoc);
				if (BeamTargetLoc.Equals(TrailComp.WorldLocation))
				{
					bBeamExtended = true;
					UPrisonBossBrainGroundDrawAttackEffectEventHandler::Trigger_StartDrawing(this);
				}
			}
		}

		if (bShapeCompleted)
		{
			ShapeLifeTime += DeltaTime;
			if (ShapeLifeTime >= PrisonBoss::DrawAttackLifeTime)
				Dissipate();
		}

		FVector PlayerLoc = Game::Mio.ActorLocation;
		float MaxProximityDist = Math::Clamp(RuntimeSpline.GetClosestSplineDistanceToLocation(PlayerLoc), 0.0, SplineDist);
		FVector ClosestLoc = RuntimeSpline.GetLocationAtDistance(MaxProximityDist);

		if (ClosestLoc.Distance(PlayerLoc) < PrisonBoss::DrawAttackDamageDistance)
		{
			FVector SplineDir = RuntimeSpline.GetDirectionAtDistance(MaxProximityDist);
			Game::Mio.DamagePlayerHealth(PrisonBoss::DrawAttackDamage, FPlayerDeathDamageParams(SplineDir), DamageEffect, DeathEffect);
		}
	}

	void Dissipate()
	{
		SetActorTickEnabled(false);
		Timer::SetTimer(this, n"DelayedDissipate", 0.25);

		BP_Dissipate();

		UPrisonBossBrainGroundDrawAttackEffectEventHandler::Trigger_Dissipate(this);
	}

	UFUNCTION()
	private void DelayedDissipate()
	{
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Dissipate() {}
}

UCLASS(Abstract)
class APrisonBossBrainGroundDrawAttackManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;
	default BillboardComp.RelativeLocation = FVector(2.0);

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<APrisonBossBrainGroundDrawAttack> AttackClass;

	UPROPERTY(EditInstanceOnly)
	AActor GroundRefActor;

	UPROPERTY(EditInstanceOnly)
	ASplineActor Spline;

	UPROPERTY(EditInstanceOnly)
	ASplineActor LineSpline;

	FTimerHandle SpawnAttackTimerHandle;

	EPrisonBossDrawAttackType CurrentAttackType;
	
	bool bDrawing = false;

	UFUNCTION()
	void StartDrawing(EPrisonBossDrawAttackType Type)
	{
		bDrawing = true;
		CurrentAttackType = Type;
		Draw();
	}

	UFUNCTION()
	void StopDrawing()
	{
		bDrawing = false;
		SpawnAttackTimerHandle.ClearTimerAndInvalidateHandle();
	}

	UFUNCTION(NotBlueprintCallable)
	void Draw()
	{
		if (!bDrawing)
			return;

		APrisonBossBrainGroundDrawAttack Attack = SpawnActor(AttackClass, ActorLocation);
		Attack.AttachToActor(this);
		
		ASplineActor TargetSpline;
		if (CurrentAttackType == EPrisonBossDrawAttackType::Circle)
			TargetSpline = Spline;
		else if (CurrentAttackType == EPrisonBossDrawAttackType::Line)
			TargetSpline = LineSpline;

		Attack.Activate(TargetSpline, GroundRefActor, CurrentAttackType);

		SpawnAttackTimerHandle = Timer::SetTimer(this, n"Draw", Math::RandRange(PrisonBoss::DrawAttackIntervalRange.X, PrisonBoss::DrawAttackIntervalRange.Y));
	}

	UFUNCTION()
	void FizzleOutActiveAttacks()
	{
		TArray<APrisonBossBrainGroundDrawAttack> DrawAttacks = TListedActors<APrisonBossBrainGroundDrawAttack>().Array;
		for (APrisonBossBrainGroundDrawAttack DrawAttack : DrawAttacks)
		{
			DrawAttack.Dissipate();
		}

		StopDrawing();
	}

	UFUNCTION()
	void BreakPlatform(ASplineActor Spline1, ASplineActor Spline2)
	{
		APrisonBossBrainGroundDrawAttack Attack1 = SpawnActor(AttackClass, ActorLocation);
		Attack1.AttachToActor(this);
		Attack1.Activate(Spline1, GroundRefActor, EPrisonBossDrawAttackType::Line, true);

		APrisonBossBrainGroundDrawAttack Attack2 = SpawnActor(AttackClass, ActorLocation);
		Attack2.AttachToActor(this);
		Attack2.Activate(Spline2, GroundRefActor, EPrisonBossDrawAttackType::Line, true);
	}
}

enum EPrisonBossDrawAttackType
{
	Circle,
	Line
}