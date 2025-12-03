class ASoftSplitLaserTurret : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UStaticMeshComponent ScifiTelegraph;
	default ScifiTelegraph.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UStaticMeshComponent FantasyTelegraph;
	default FantasyTelegraph.CollisionEnabled = ECollisionEnabled::NoCollision;
	

	UPROPERTY(EditAnywhere, Category = "Turret")
	bool bEnabled = true;

	UPROPERTY(EditAnywhere, Category = "Turret")
	bool bShouldSpawn;

	UPROPERTY(EditAnywhere, Category = "Turret")
	EHazeSelectPlayer TrackTargets = EHazeSelectPlayer::Both;

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
	float FireCooldown = 2.0;

	UPROPERTY(EditAnywhere, Category = "Turret")
	float TelegraphDuration = 3.0;

	UPROPERTY(EditAnywhere, Category = "Turret")
	float TrackingDuration = 3.0;

	UPROPERTY(EditAnywhere, Category = "Beam")
	float BeamDuration = 1.0;

	UPROPERTY(EditAnywhere, Category = "Beam")
	UNiagaraSystem ScifiBeam;

	UPROPERTY(EditAnywhere, Category = "Beam")
	UNiagaraSystem FantasyBeam;

	AHazePlayerCharacter TargetPlayer;
	float CooldownTimer = 0.0;
	float TrackTimer = 0.0;
	bool bStartedTelegraph = false;

	float BeamTimer = 0.0;
	TArray<UNiagaraComponent> BeamComponents;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

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
					Fire();

					CooldownTimer = FireCooldown;
					TargetPlayer = nullptr;
					bStartedTelegraph = false;
				}
			}
		}

		BeamTimer -= DeltaSeconds;
		if (BeamTimer <= 0.0)
		{
			for (auto Beam : BeamComponents)
				Beam.DestroyComponent(Beam);
			BeamComponents.Reset();
		}
		else
		{
			UpdateAndKillPlayersInBeam();
		}
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

	void TraceBeam(FVector& OutBeamStart, FVector& OutBeamEnd)
	{
		OutBeamStart = ActorLocation;
		OutBeamEnd = ActorLocation + ActorForwardVector * BeamMaxLength;

		auto Manager = ASoftSplitManager::GetSoftSplitManger();
		EHazeWorldLinkLevel StartSplit = Manager.GetVisibleSoftSplitAtLocation(OutBeamStart);

		// TODO: Check for blockages in both worlds
		FVector PlaneOrigin;
		FVector PlaneNormal;
		Manager.GetWorldSplitPlane(StartSplit, PlaneOrigin, PlaneNormal);

		FHazeTraceSettings Trace;
		Trace.TraceWithChannel(ECollisionChannel::WeaponTraceEnemy);
		Trace.IgnorePlayers();
		Trace.IgnoreActor(this);

		FVector Intersection;
		if (Math::IsLineSegmentIntersectingPlane(OutBeamStart, OutBeamEnd, PlaneNormal, PlaneOrigin, Intersection))
		{
			// Trace to the split plane in the start world
			FHitResult Hit = Trace.QueryTraceSingle(
				Manager.Position_Convert(OutBeamStart, GetBaseSoftSplit(), StartSplit),
				Intersection,
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
				Manager.Position_Convert(Intersection, StartSplit, OtherSplit),
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

		TraceBeam(BeamStart, BeamEnd);

		float BeamLength = BeamEnd.Distance(BeamStart);
		ScifiTelegraph.RelativeLocation = FVector(BeamLength * 0.5, ScifiTelegraph.RelativeLocation.Y, ScifiTelegraph.RelativeLocation.Z);
		FantasyTelegraph.RelativeLocation = FVector(BeamLength * 0.5, FantasyTelegraph.RelativeLocation.Y, FantasyTelegraph.RelativeLocation.Z);

		ScifiTelegraph.RelativeScale3D = FVector(BeamLength / 100.0, BeamWidth / 100.0, ScifiTelegraph.RelativeScale3D.Z);
		FantasyTelegraph.RelativeScale3D = FVector(BeamLength / 100.0, BeamWidth / 100.0, ScifiTelegraph.RelativeScale3D.Z);

		ScifiTelegraph.SetScalarParameterValueOnMaterials(n"Pct", TelegraphPct);
		FantasyTelegraph.SetScalarParameterValueOnMaterials(n"Pct", TelegraphPct);
	}

	void Fire()
	{
		ScifiTelegraph.SetHiddenInGame(true);
		FantasyTelegraph.SetHiddenInGame(true);

		FVector BeamStart;
		FVector BeamEnd;

		TraceBeam(BeamStart, BeamEnd);

		auto Manager = ASoftSplitManager::GetSoftSplitManger();

		if (ScifiBeam != nullptr)
		{
			auto Beam = Niagara::SpawnLoopingNiagaraSystemAttached(
				ScifiBeam, ScifiRoot
			);
			Beam.SetFloatParameter(n"BeamWidth", BeamWidth);
			BeamComponents.Add(Beam);
		}

		if (FantasyBeam != nullptr)
		{
			auto Beam = Niagara::SpawnLoopingNiagaraSystemAttached(
				FantasyBeam, FantasyRoot
			);
			Beam.SetFloatParameter(n"BeamWidth", BeamWidth);
			BeamComponents.Add(Beam);
		}

		BeamTimer = BeamDuration;
		UpdateAndKillPlayersInBeam();
	}

	void UpdateAndKillPlayersInBeam()
	{
		auto Manager = ASoftSplitManager::GetSoftSplitManger();

		FVector BeamStart;
		FVector BeamEnd;

		TraceBeam(BeamStart, BeamEnd);

		for (auto Beam : BeamComponents)
		{
			if (Beam.AttachParent == FantasyRoot)
			{
				Beam.SetVectorParameter(n"BeamStart", Manager.Position_Convert(BeamStart, GetBaseSoftSplit(), EHazeWorldLinkLevel::Fantasy));
				Beam.SetVectorParameter(n"BeamEnd", Manager.Position_Convert(BeamEnd, GetBaseSoftSplit(), EHazeWorldLinkLevel::Fantasy));
			}
			else
			{
				Beam.SetVectorParameter(n"BeamStart", Manager.Position_Convert(BeamStart, GetBaseSoftSplit(), EHazeWorldLinkLevel::SciFi));
				Beam.SetVectorParameter(n"BeamEnd", Manager.Position_Convert(BeamEnd, GetBaseSoftSplit(), EHazeWorldLinkLevel::SciFi));
			}
		}

		// Check for players to kill
		for (AHazePlayerCharacter Player : Game::Players)
		{
			FVector PlayerBeamStart = Manager.Position_Convert(BeamStart, GetBaseSoftSplit(), Manager.GetSplitForPlayer(Player));
			FVector PlayerBeamEnd = Manager.Position_Convert(BeamEnd, GetBaseSoftSplit(), Manager.GetSplitForPlayer(Player));

			FVector PointOnBeam = Math::ClosestPointOnLine(PlayerBeamStart, PlayerBeamEnd, Player.ActorLocation);
			if (PointOnBeam.Distance(Player.ActorLocation) < BeamWidth)
			{
				Player.KillPlayer();
			}
		}
	}
};