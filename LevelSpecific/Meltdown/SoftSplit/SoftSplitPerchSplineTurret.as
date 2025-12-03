event void FOnSoftSplitPerchSplineSuccess();

class ASoftSplitPerchSplineTurretManager : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY()
	FOnSoftSplitPerchSplineSuccess OnSuccess;

	float AllowHitUntilGameTime = 0;
	int NumSuccess = 0;
	int NumFail = 0;
	bool bReceiversOpen = false;
	bool bCompleted = false;
	bool bFiring = false;

	bool CanHitPerch() const
	{
		if (NumSuccess > 0)
			return true;
		if (NumFail > 0)
			return false;
		if (Time::GameTimeSeconds <= AllowHitUntilGameTime)
			return true;
		return false;
	}

	UFUNCTION()
	void OnFire()
	{
		NumFail = 0;
		NumSuccess = 0;
		bFiring = true;
	}

	UFUNCTION()
	void OnOpen(float OpenDuration)
	{
		AllowHitUntilGameTime = Time::GameTimeSeconds + OpenDuration;

		bReceiversOpen = true;
		for (auto Receiver : TListedActors<ASoftSplitPerchSplineTurretReceiver>())
			Receiver.Open();
	}

	void Success()
	{
		NumSuccess += 1;
		if (NumSuccess >= 3)
		{
			OnSuccess.Broadcast();
			bFiring = false;
			bCompleted = true;
		}
	}

	void Fail()
	{
		NumFail += 1;
		if (NumFail >= 3)
		{
			bFiring = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bReceiversOpen && Time::GameTimeSeconds > AllowHitUntilGameTime && Game::Zoe.HasControl() && !bCompleted && NumSuccess == 0)
			CrumbCloseReceivers();
	}

	UFUNCTION(CrumbFunction)
	void CrumbCloseReceivers()
	{
		bReceiversOpen = false;
		for (auto Receiver : TListedActors<ASoftSplitPerchSplineTurretReceiver>())
			Receiver.Close();
	}
}

class ASoftSplitPerchSplineTurret : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UStaticMeshComponent ScifiTelegraph;
	default ScifiTelegraph.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UStaticMeshComponent FantasyTelegraph;
	default FantasyTelegraph.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> TurretShake;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect TurretFF;

	UPROPERTY(EditAnywhere, Category = "Turret")
	bool bEnabled = false;

	UPROPERTY(EditAnywhere, Category = "Turret")
	EHazeSelectPlayer TrackTargets = EHazeSelectPlayer::Mio;

	UPROPERTY(EditAnywhere, Category = "Turret")
	EHazeSelectPlayer KillTargets = EHazeSelectPlayer::Mio;

	UPROPERTY(EditAnywhere, Category = "Turret")
	float TrackMaxDistance = 2000.0;

	UPROPERTY(EditAnywhere, Category = "Turret")
	float TrackMaxHeightDifference = 200.0;

	UPROPERTY(EditAnywhere, Category = "Turret")
	float BeamWidth = 100.0;

	UPROPERTY(EditAnywhere, Category = "Turret")
	float BeamMaxLength = 5000.0;

	UPROPERTY(EditAnywhere, Category = "Turret")
	float TrackRotationSpeed = 100.0;

	UPROPERTY(EditAnywhere, Category = "Turret")
	float FireCooldown = 4.0;

	UPROPERTY(EditAnywhere, Category = "Turret")
	float TelegraphDuration = 3.0;

	UPROPERTY(EditAnywhere, Category = "Turret")
	float TrackingDuration = 2.0;

	UPROPERTY(EditAnywhere, Category = "Beam")
	TSubclassOf<ASoftSplitTurretSpawnedPerchProjectile> SpawnedProjectile;

	AHazePlayerCharacter TargetPlayer;
	float CooldownTimer = 0.0;
	float TrackTimer = 0.0;
	bool bStartedTelegraph = false;
	int ProjectileSpawnCounter = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		SetActorControlSide(Game::Zoe);

		ScifiTelegraph.SetHiddenInGame(true);
		FantasyTelegraph.SetHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (CooldownTimer > 0.0)
		{
			CooldownTimer = Math::Max(0.0, CooldownTimer - DeltaSeconds);
		}
		else if (bEnabled)
		{
			if (!bStartedTelegraph)
			{
				UpdateTarget();
				UpdateTracking(DeltaSeconds);

				if (TargetPlayer != nullptr || TrackTargets == EHazeSelectPlayer::None)
				{
					bStartedTelegraph = true;
					TrackTimer = 0.0;
					StartTelegraph();
					UpdateTelegraph(DeltaSeconds);
				}
			}
			else
			{
				TrackTimer += DeltaSeconds;
				if (TrackTimer < TrackingDuration)
				{
					UpdateTracking(DeltaSeconds);
					UpdateTelegraph(TrackTimer / TelegraphDuration);
				}
				else if (TrackTimer > TelegraphDuration)
				{
					if (HasControl())
						CrumbFire();

					CooldownTimer = FireCooldown;
					TargetPlayer = nullptr;
					bStartedTelegraph = false;
				}
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbFire()
	{
		FireFX();

		Game::Mio.PlayCameraShake(TurretShake,this, Scale = 0.5);

		Game::Mio.PlayForceFeedback(TurretFF, false, false, this);

		ScifiTelegraph.SetHiddenInGame(true);
		FantasyTelegraph.SetHiddenInGame(true);

		FVector BeamStart;
		FVector BeamEnd;

		FVector BeamIntersection;
		bool bHadIntersection;

		EHazeWorldLinkLevel BeamStartLevel;

		TraceBeam(BeamStart, BeamEnd, BeamIntersection, bHadIntersection, BeamStartLevel);

		auto Manager = ASoftSplitManager::GetSoftSplitManger();

		auto Projectile = SpawnActor(SpawnedProjectile, ActorLocation, ActorRotation, bDeferredSpawn = true);
		Projectile.MakeNetworked(this, ProjectileSpawnCounter);
		Projectile.Turret = this;
		ProjectileSpawnCounter++;
		FinishSpawningActor(Projectile);

		USoftSplitPerchSplineTurretEffectHandler::Trigger_FireProjectile(this);
	}

	void UpdateTarget()
	{
		auto Manager = ASoftSplitManager::GetSoftSplitManger();

		float ClosestDist = MAX_flt;
		AHazePlayerCharacter Target = nullptr;
		for (int i = 0; i < 2; ++i)
		{
			EHazeWorldLinkLevel Split = EHazeWorldLinkLevel(i+1);

			AHazePlayerCharacter Player = Manager.GetPlayerForSplit(Split);
			if (Player.IsPlayerDead())
				continue;
			if (!Player.IsSelectedBy(TrackTargets))
				continue;

			FVector PlayerLocation = Manager.Position_Convert(Player.ActorLocation, Split, GetBaseSoftSplit());
			float Dist = PlayerLocation.Distance(ActorLocation);
			if (Dist > TrackMaxDistance)
				continue;
			if (Math::Abs(PlayerLocation.Z - ActorLocation.Z) > TrackMaxHeightDifference)
				continue;

			if (Dist < ClosestDist)
			{
				ClosestDist = Dist;
				TargetPlayer = Player;
			}
		}
	}

	void UpdateTracking(float DeltaTime)
	{
		if (TargetPlayer == nullptr)
			return;

		auto Manager = ASoftSplitManager::GetSoftSplitManger();
		FVector PlayerPositionInOurSpace = Manager.Position_Convert(TargetPlayer.ActorLocation, Manager.GetSplitForPlayer(TargetPlayer), GetBaseSoftSplit());

		FQuat WantedRotation = FQuat::MakeFromZX(ActorUpVector, PlayerPositionInOurSpace - ActorLocation);
		SetActorRotation(Math::QInterpConstantTo(ActorQuat, WantedRotation, DeltaTime, Math::DegreesToRadians(TrackRotationSpeed)));
	}

	void StartTelegraph()
	{
		ScifiTelegraph.SetHiddenInGame(false);
		FantasyTelegraph.SetHiddenInGame(false);
	}

	void TraceBeam(FVector& OutBeamStart, FVector& OutBeamEnd, FVector& OutBeamIntersection, bool& OutHadIntersection, EHazeWorldLinkLevel& OutBeamStartLevel)
	{
		OutBeamStart = ActorLocation;
		OutBeamEnd = ActorLocation + ActorForwardVector * BeamMaxLength;

		auto Manager = ASoftSplitManager::GetSoftSplitManger();

		EHazeWorldLinkLevel StartSplit = Manager.GetVisibleSoftSplitAtLocation(OutBeamStart);
		OutBeamStartLevel = StartSplit;

		// TODO: Check for blockages in both worlds
		FVector PlaneOrigin;
		FVector PlaneNormal;
		Manager.GetWorldSplitPlane(StartSplit, PlaneOrigin, PlaneNormal);

		FHazeTraceSettings Trace;
		Trace.TraceWithChannel(ECollisionChannel::WeaponTraceEnemy);
		Trace.IgnorePlayers();
		Trace.IgnoreActor(this);

		if (Math::IsLineSegmentIntersectingPlane(OutBeamStart, OutBeamEnd, PlaneNormal, PlaneOrigin, OutBeamIntersection))
		{
			OutHadIntersection = true;

			// Trace to the split plane in the start world
			FHitResult Hit = Trace.QueryTraceSingle(
				Manager.Position_Convert(OutBeamStart, GetBaseSoftSplit(), StartSplit),
				OutBeamIntersection,
			);

			if (Hit.bBlockingHit)
			{
				// We hit something in the start world
				OutBeamEnd = Manager.Position_Convert(Hit.ImpactPoint, StartSplit, GetBaseSoftSplit());
				return;
			}

			// Trace from the split plane in the other world
			auto OtherSplit = Manager.GetOtherSplit(StartSplit);
			Hit = Trace.QueryTraceSingle(
				Manager.Position_Convert(OutBeamIntersection, StartSplit, OtherSplit),
				Manager.Position_Convert(OutBeamEnd, GetBaseSoftSplit(), OtherSplit),
			);

			if (Hit.bBlockingHit)
			{
				// We hit something in the start world
				OutBeamEnd = Manager.Position_Convert(Hit.ImpactPoint, OtherSplit, GetBaseSoftSplit());
				return;
			}
		}
		else
		{
			OutHadIntersection = false;

			// We don't cross the split plane, so only one trace
			FHitResult Hit = Trace.QueryTraceSingle(
				Manager.Position_Convert(OutBeamStart, GetBaseSoftSplit(), StartSplit),
				Manager.Position_Convert(OutBeamEnd, GetBaseSoftSplit(), StartSplit),
			);

			if (Hit.bBlockingHit)
			{
				OutBeamEnd = Manager.Position_Convert(Hit.ImpactPoint, StartSplit, GetBaseSoftSplit());
			}
		}
	}

	void UpdateTelegraph(float TelegraphPct)
	{
		FVector BeamStart;
		FVector BeamEnd;

		FVector BeamIntersection;
		bool bHadIntersection;

		EHazeWorldLinkLevel BeamStartLevel;

		TraceBeam(BeamStart, BeamEnd, BeamIntersection, bHadIntersection, BeamStartLevel);

		float BeamLength = BeamEnd.Distance(BeamStart);
		ScifiTelegraph.RelativeLocation = FVector(BeamLength * 0.5, ScifiTelegraph.RelativeLocation.Y, ScifiTelegraph.RelativeLocation.Z);
		FantasyTelegraph.RelativeLocation = FVector(BeamLength * 0.5, FantasyTelegraph.RelativeLocation.Y, FantasyTelegraph.RelativeLocation.Z);

		ScifiTelegraph.RelativeScale3D = FVector(BeamLength / 100.0, BeamWidth / 100.0, ScifiTelegraph.RelativeScale3D.Z);
		FantasyTelegraph.RelativeScale3D = FVector(BeamLength / 100.0, BeamWidth / 100.0, ScifiTelegraph.RelativeScale3D.Z);

		ScifiTelegraph.SetScalarParameterValueOnMaterials(n"Pct", TelegraphPct);
		FantasyTelegraph.SetScalarParameterValueOnMaterials(n"Pct", TelegraphPct);
	}

	UFUNCTION()
	void Fire()
	{
		if (HasControl())
			CrumbFire();
	}

	UFUNCTION(BlueprintEvent)
	void FireFX()
	{
	}
};



class ASoftSplitTurretSpawnedPerchProjectile : AWorldLinkDoubleActor
{
	UPROPERTY(EditAnywhere, Category = "Beam")
	TSubclassOf<ASoftSplitTurretSpawnedPerchSpline> SpawnedPerchSpline;

	UPROPERTY(EditAnywhere, Category = "Turret Perch Projectile")
	float MaxLifetime = 10.0;
	UPROPERTY(EditAnywhere, Category = "Turret Perch Projectile")
	float Speed = 1500.0;
	UPROPERTY(EditAnywhere, Category = "Turret Perch Projectile")
	float TraceRadius = 100.0;

	float Timer = 0.0;
	ASoftSplitPerchSplineTurret Turret;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> FailShake;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect FailFF;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect SucessFF;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		SetActorControlSide(Game::Zoe);
		USoftSplitPerchSplineProjectileEffectHandler::Trigger_Fired(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Timer += DeltaSeconds;
		if (Timer >= MaxLifetime)
		{
			if (HasControl())
				CrumbExpired();
		}
		else
		{
			auto Manager = ASoftSplitManager::GetSoftSplitManger();

			FHazeTraceSettings Trace;
			Trace.TraceWithChannel(ECollisionChannel::WeaponTraceEnemy);
			Trace.UseLine();
			Trace.IgnoreActor(this);
			Trace.IgnorePlayers();

			FVector TargetLocation;
			TargetLocation = ActorLocation + ActorForwardVector * Speed * DeltaSeconds;

			for (auto Player : Game::Players)
			{
				FVector LocationOfPlayer = Manager.Position_Convert(Player.ActorLocation, Manager.GetSplitForPlayer(Player), GetBaseSoftSplit());
				if (LocationOfPlayer.Distance(ActorLocation) < TraceRadius)
					Player.KillPlayer();
			}

			EHazeWorldLinkLevel VisibleInSplit = Manager.GetVisibleSoftSplitAtLocation(ActorLocation);

			FHitResult Hit = Trace.QueryTraceSingle(
				Manager.Position_Convert(ActorLocation, GetBaseSoftSplit(), VisibleInSplit),
				Manager.Position_Convert(TargetLocation, GetBaseSoftSplit(), VisibleInSplit),
			);

			if (Hit.bBlockingHit)
			{
				ActorLocation = Manager.Position_Convert(Hit.ImpactPoint, VisibleInSplit, GetBaseSoftSplit());

				ASoftSplitPerchSplineTurretManager TurretManager = TListedActors<ASoftSplitPerchSplineTurretManager>().GetSingle();
				if (HasControl())
				{
					if (TurretManager.CanHitPerch() && Manager.GetVisibleSoftSplitAtLocation(ActorLocation) == EHazeWorldLinkLevel::Fantasy)
						CrumbSpawnPerch(Cast<AHazeActor>(Hit.Actor), ActorLocation, ActorRotation);
					else
						CrumbFailPerch(Cast<AHazeActor>(Hit.Actor), ActorLocation);
				}

			}
			else
			{
				ActorLocation = TargetLocation;
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbFailPerch(AHazeActor HitActor, FVector AtLocation)
	{
		ASoftSplitPerchSplineTurretManager TurretManager = TListedActors<ASoftSplitPerchSplineTurretManager>().GetSingle();
		TurretManager.Fail();

		FSoftSplitPerchSplineHit Hit;
		Hit.HitLocation_Scifi = GetLocationBasedOnActorLocation(EHazeWorldLinkLevel::SciFi, AtLocation);
		Hit.HitLocation_Fantasy = GetLocationBasedOnActorLocation(EHazeWorldLinkLevel::Fantasy, AtLocation);

		USoftSplitPerchSplineReceiverEffectHandler::Trigger_PerchSplineHitFail(HitActor, Hit);
		USoftSplitPerchSplineProjectileEffectHandler::Trigger_HitFail(this, Hit);

		Game::Zoe.PlayForceFeedback(FailFF,false,false,this);
		Game::Zoe.PlayCameraShake(FailShake,this, 0.2);

		DestroyActor();
	}

	UFUNCTION(CrumbFunction)
	void CrumbSpawnPerch(AHazeActor HitActor, FVector AtLocation, FRotator AtRotation)
	{
		auto Manager = ASoftSplitManager::GetSoftSplitManger();
		auto Perch = SpawnActor(SpawnedPerchSpline, Manager.Position_ScifiToFantasy(AtLocation), AtRotation, bDeferredSpawn = true);
		Perch.MakeNetworked(this, n"SpawnedPerch");
		FinishSpawningActor(Perch);

		ASoftSplitPerchSplineTurretManager TurretManager = TListedActors<ASoftSplitPerchSplineTurretManager>().GetSingle();
		TurretManager.Success();

		FSoftSplitPerchSplineHit Hit;
		Hit.HitLocation_Scifi = GetLocationBasedOnActorLocation(EHazeWorldLinkLevel::SciFi, AtLocation);
		Hit.HitLocation_Fantasy = GetLocationBasedOnActorLocation(EHazeWorldLinkLevel::Fantasy, AtLocation);
		USoftSplitPerchSplineReceiverEffectHandler::Trigger_PerchSplineHitSuccess(HitActor, Hit);
		USoftSplitPerchSplineProjectileEffectHandler::Trigger_HitSuccess(this, Hit);

		Game::Zoe.PlayForceFeedback(FailFF,false,false,this);

		DestroyActor();
	}

	UFUNCTION(CrumbFunction)
	void CrumbExpired()
	{
		ASoftSplitPerchSplineTurretManager TurretManager = TListedActors<ASoftSplitPerchSplineTurretManager>().GetSingle();
		TurretManager.Fail();

		DestroyActor();
	}
};

class ASoftSplitTurretSpawnedPerchSpline : APerchSpline
{
}

class ASoftSplitPerchSplineTurretReceiver : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	UPROPERTY(DefaultComponent, Attach = Mesh)
	UStaticMeshComponent Mouth;		
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect MouthOpenFF;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect MouthCloseFF;

	FRotator StartRotation;
	FRotator EndRotation = FRotator(-60,360, 720);

	UPROPERTY()
	FHazeTimeLike OpenMouth;
	default OpenMouth.Duration = 0.5;
	default OpenMouth.UseSmoothCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OpenMouth.BindUpdate(this, n"MouthOpening");

		StartRotation = Mouth.RelativeRotation;
	}

	UFUNCTION()
	private void MouthOpening(float CurrentValue)
	{
		Mouth.SetRelativeRotation(Math::LerpShortestPath(StartRotation, EndRotation,CurrentValue));
	}

	void Open()
	{
		USoftSplitPerchSplineReceiverEffectHandler::Trigger_Opened(this);
		Game::Zoe.PlayForceFeedback(MouthOpenFF,false,false,this);
		BP_Open();
	}
	
	void Close()
	{
		USoftSplitPerchSplineReceiverEffectHandler::Trigger_Closed(this);
		Game::Zoe.PlayForceFeedback(MouthCloseFF,false,false,this);
		BP_Close();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Open()
	{
	}
	
	UFUNCTION(BlueprintEvent)
	void BP_Close()
	{
	}
}