class ASkylineBallBossMotorcycle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TiltRoot;

	UPROPERTY(DefaultComponent, Attach = TiltRoot)
	USceneComponent MotorcycleRoot;

	UPROPERTY(DefaultComponent, Attach = MotorcycleRoot)
	UDecalTrailComponent MotorcycleTrailComp;

	UPROPERTY(DefaultComponent, Attach = MotorcycleRoot)
	UCapsuleComponent CollisionComp;

	UPROPERTY(DefaultComponent, Attach = MotorcycleRoot)
	UNiagaraComponent VFXComp;

	UPROPERTY(DefaultComponent, Attach = MotorcycleRoot)
	USkylineBallBossTractorBeamComponent TractorBeamVFXComp;

	UPROPERTY()
	FHazeTimeLike WheeleTimeLike;
	default WheeleTimeLike.UseSmoothCurveZeroToOne();
	default WheeleTimeLike.Duration = 1.0;

	UPROPERTY()
	FHazeTimeLike AppearTimeLike;
	default AppearTimeLike.UseSmoothCurveZeroToOne();
	default AppearTimeLike.Duration = 2.0;

	UPROPERTY(EditAnywhere)
	float AppearDelay = 0.0;

	UPROPERTY()
	float Damage = 0.7;

	UPROPERTY()
	float StumbleDuration = 1.0;

	UPROPERTY()
	float DamageCooldown = 1.0;

	UPROPERTY()
	float Speed = 1000.0;
	float CurrentSpeed;

	UPROPERTY(EditInstanceOnly)
	bool bInverseCurve = false;

	bool bDisappear = false;
	bool bGoneOverLedge = false;
	bool bGoneOverGround = false;
	bool bAppeared = false;
	bool bAttacking = false;
	bool bPhaseChangeBound = false;

	TPerPlayer<float> LastTimeHitPlayer;

	FVector AppearLocation;
	FVector EstimatedLedgeLocation;
	FVector EstimatedGroundLocation;
	FVector TractorBeamPos;
	ASkylineBallBoss BallBoss;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WheeleTimeLike.BindUpdate(this, n"WheeleTimeLikeUpdate");
		AppearTimeLike.BindUpdate(this, n"AppearTimeLikeUpdate");
		AppearTimeLike.BindFinished(this, n"AppearTimeLikeEnd");
		MotorcycleTrailComp.Clear();
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bAttacking)
		{
			float Offset = Math::Sin(MotorcycleRoot.RelativeLocation.X * 0.002);

			if (bInverseCurve)
				Offset = -Offset;

			TiltRoot.SetRelativeLocation(FVector::RightVector * Offset * 100.0);
			TiltRoot.SetRelativeRotation(FRotator(0.0, 0.0, Offset * -15.0));
			SweepForPlayerImpact(DeltaSeconds);	

			FHazeFrameForceFeedback FrameFF;
			FrameFF.LeftMotor = 0.4;
			ForceFeedback::PlayWorldForceFeedbackForFrame(FrameFF, MotorcycleRoot.WorldLocation, 300.0, 1000.0);
		}
	}

	private void SweepForPlayerImpact(float DeltaSeconds)
	{
		FVector RelativeDelta = FVector::ForwardVector * CurrentSpeed * DeltaSeconds;
		FVector WorldDelta = MotorcycleRoot.WorldTransform.TransformVectorNoScale(RelativeDelta);

		if (WorldDelta.IsZero())
			return;

		// Get the local bounding box of the actor, ignoring scale, position and rotation
		FVector Extents;
		FVector Origin;
		GetActorLocalBounds(true, Origin, Extents);

		// Make the extents be roughly the size of the bonnet
		Extents *= FVector(1, 1, 1);

		// Override extents. They sucked
		Extents = FVector(150.0, 20.0, 30.0);

		// Transform to world space
		Origin = ActorTransform.TransformPosition(Origin);

		FVector End = Origin + WorldDelta;

		for(auto Player : Game::Players)
		{
			if (SkylineBallBossDevToggles::NoThrowsImpacts.IsEnabled())
				continue;

			auto MoveComp = UPlayerMovementComponent::Get(Player);

			// Sweep only against the player
			FHazeTraceSettings Trace = Trace::InitAgainstComponent(Player.CapsuleComponent);
			Trace.UseBoxShape(Extents, MotorcycleRoot.WorldRotation.Quaternion());

			//DebugDraw Extents
			//Debug::DrawDebugBox(Origin, Extents, MotorcycleRoot.WorldRotation);

			const FHitResult Hit = Trace.QueryTraceComponent(Origin, End);
			if(Hit.bBlockingHit)
			{
				if (Time::GetGameTimeSince(LastTimeHitPlayer[Player]) > DamageCooldown)
				{
					FVector StumbleDirection = (Player.ActorLocation - MotorcycleRoot.WorldLocation).GetSafeNormal() * FVector(1.0, 1.0, 0.0);
					Player.DamagePlayerHealth(Damage, FPlayerDeathDamageParams(StumbleDirection), BallBoss.ObjectSmallDamageEffect, BallBoss.ObjectSmallDeathEffect);

					Player.ApplyStumble(StumbleDirection * 500.0, StumbleDuration);

					LastTimeHitPlayer[Player] = Time::GameTimeSeconds;

					FSkylineBallBossMotorcycleImpactPlayerEventHandlerParams Params;
					Params.Player = Player;
					USkylineBallBossMotorcycleEventHandler::Trigger_ImpactPlayer(this, Params);
				}	
			}
		}

		MotorcycleRoot.AddRelativeLocation(RelativeDelta);
		FVector ToLedge = EstimatedLedgeLocation - ActorLocation;
		//Debug::DrawDebugLine(AppearLocation, EstimatedLedgeLocation, ColorDebug::Ruby, 10.0, 0.0, true);
		bool bGoingOverLedge = ToLedge.DotProduct(ActorForwardVector) < 0.0;
		if (bGoingOverLedge && !bGoneOverLedge)
		{
			bGoneOverLedge = true;
			USkylineBallBossMotorcycleEventHandler::Trigger_GoingOffEdge(this);
		}

		FVector ToGround = EstimatedGroundLocation - ActorLocation;
		bool bGoingOverGround = ToGround.DotProduct(ActorForwardVector) < 0.0;
		//Debug::DrawDebugLine(AppearLocation, EstimatedGroundLocation, ColorDebug::Blue, 10.0, 0.0, true);
		if (bGoingOverGround && !bGoneOverGround)
		{
			bGoneOverGround = true;
			USkylineBallBossMotorcycleEventHandler::Trigger_OnGround(this);
		}
	}

	void TryCahceBallBoss()
	{
		if (BallBoss == nullptr)
		{
			TListedActors<ASkylineBallBoss> BallBosses;
			if (BallBosses.Num() == 1)
				BallBoss = BallBosses[0];
		}
	}

	UFUNCTION()
	void MaybeDisappear(ESkylineBallBossPhase NewPhase)
	{
		if (bAppeared && !bAttacking)
		{
			TractorBeamVFXComp.TractorBeamLetGo();
			bDisappear = true;
			AppearTimeLike.Reverse();
			Timer::SetTimer(this, n"Disable", 3.0);
			USkylineBallBossMotorcycleEventHandler::Trigger_Disappear(this);
		}
	}

	UFUNCTION()
	void Appear()
	{
		if (AppearDelay > 0.0)
			Timer::SetTimer(this, n"DelayedAppear", AppearDelay);
		else
			DelayedAppear();
	}

	UFUNCTION()
	private void DelayedAppear()
	{
		TryCahceBallBoss();
		if (!bPhaseChangeBound)
		{
			bPhaseChangeBound = true;
			BallBoss.OnPhaseChanged.AddUFunction(this, n"MaybeDisappear");
		}
		bAppeared = true;
		MotorcycleRoot.SetRelativeRotation(FRotator(0.0));
		TiltRoot.SetRelativeLocation(FVector::ZeroVector);
		TiltRoot.SetRelativeRotation(FRotator::ZeroRotator);
		CurrentSpeed = 0.0;
		RemoveActorDisable(this);
		AppearTimeLike.PlayFromStart();
		TractorBeamVFXComp.Start();
		USkylineBallBossMotorcycleEventHandler::Trigger_AppearStart(this);
	}

	UFUNCTION()
	private void AppearTimeLikeUpdate(float CurrentValue)
	{
		MotorcycleRoot.SetRelativeLocation(FVector::UpVector * Math::Lerp(-1000.0, 0.0, CurrentValue));
	}

	UFUNCTION()
	private void AppearTimeLikeEnd()
	{
		AppearLocation = ActorLocation;
		EstimatedGroundLocation = ActorLocation + (ActorForwardVector * 600.0);
		EstimatedLedgeLocation = ActorLocation + (ActorForwardVector * 3000.0);
		if (!bDisappear)
			USkylineBallBossMotorcycleEventHandler::Trigger_AppearEnd(this);
	}

	UFUNCTION()
	void Activate()
	{
		VFXComp.Activate();
		WheeleTimeLike.PlayFromStart();
		bAttacking = true;
		Timer::SetTimer(this, n"TractorBeamLetGo", 0.75);
		Timer::SetTimer(this, n"Disable", 8.0);
		USkylineBallBossMotorcycleEventHandler::Trigger_Revving(this);
		USkylineBallBossMiscVOEventHandler::Trigger_WheeleMotorcycleThrow(BallBoss);
	}

	UFUNCTION()
	void Disable()
	{
		AddActorDisable(this);
		VFXComp.Deactivate();
		bAttacking = false;
		bAppeared = false;
		TractorBeamVFXComp.Stop();
	}

	UFUNCTION()
	private void TractorBeamLetGo()
	{
		TractorBeamVFXComp.TractorBeamLetGo();
		USkylineBallBossMotorcycleEventHandler::Trigger_Thrown(this);
	}

	UFUNCTION()
	private void WheeleTimeLikeUpdate(float CurrentValue)
	{
		MotorcycleRoot.SetRelativeRotation(FRotator(Math::Lerp(0.0, 45.0, CurrentValue), 0.0, 0.0));
		CurrentSpeed = WheeleTimeLike.Position * Speed;
	}
};