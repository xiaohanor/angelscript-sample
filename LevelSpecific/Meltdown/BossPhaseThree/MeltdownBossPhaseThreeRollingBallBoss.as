class AMeltdownBossPhaseThreeRollingBallBoss : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent PortalMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsCircleTranslateComponent CircleTranslateComp;

	UPROPERTY(DefaultComponent, Attach = CircleTranslateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = CircleTranslateComp)
	USceneComponent RollRoot;

	UPROPERTY(DefaultComponent, Attach = RollRoot)
	UHazeRawVelocityTrackerComponent VelocityTrackerComp;

	UPROPERTY(DefaultComponent, Attach = RollRoot)
	UNiagaraComponent LaserImpactVFXComp;

	UPROPERTY(DefaultComponent, Attach = RollRoot)
	UStaticMeshComponent LaserMeshComp;

	UPROPERTY(DefaultComponent, Attach = RollRoot)
	UHazeCapsuleCollisionComponent LaserCollisionComp;

	UPROPERTY()
	UNiagaraSystem ExplosionVFXSystem;

	UPROPERTY()
	FHazeTimeLike BounceTimeLike;

	UPROPERTY()
	FHazeTimeLike LerpToMiddleTimeLike;


	FHazeTimeLike PortalSpawnTimeLike;
	default PortalSpawnTimeLike.UseSmoothCurveZeroToOne();
	default PortalSpawnTimeLike.Duration = 1.0;

	AHazePlayerCharacter TargetPlayer;

	FHazeAcceleratedVector AcceleratedTargetLocation;

	UPROPERTY()
	float ForceStrength = 3000.0;

	UPROPERTY()
	float DamageCooldown = 1.0;

	float Radius;
	float ActorZ;

	bool bTrackPlayer = false;

	TPerPlayer<float> LastTimeHit;

	FVector RollRootRelativeLocation;

	FVector RollRootLastFrameRelativeLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LaserCollisionComp.OnComponentBeginOverlap.AddUFunction(this, n"LaserBeginOverlap");
		PortalSpawnTimeLike.BindUpdate(this, n"PortalSpawnTimeLikeUpdate");
		PortalSpawnTimeLike.BindFinished(this, n"PortalSpawnTimeLikeFinished");
		BounceTimeLike.BindUpdate(this, n"BounceTimeLikeUpdate");
		LerpToMiddleTimeLike.BindUpdate(this, n"LerpToMiddleTimeLikeUpdate");
		LerpToMiddleTimeLike.BindFinished(this, n"LerpToMiddleTimeLikeFinished");

		TargetPlayer = Game::Mio;
		ActorZ = ActorLocation.Z;

		AcceleratedTargetLocation.SnapTo(ActorLocation);

		Radius = RollRoot.RelativeLocation.Z;

		RollRootRelativeLocation = RollRoot.RelativeLocation;

		AddActorDisable(this);
		RollRoot.SetHiddenInGame(true, true);
	}
	

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bTrackPlayer)
		{
			//CALCULATE MOVEMENT
			AcceleratedTargetLocation.AccelerateTo(FVector(TargetPlayer.ActorLocation.X, TargetPlayer.ActorLocation.Y, ActorZ), 3.0, DeltaSeconds);
			ForceComp.Force = (AcceleratedTargetLocation.Value - CircleTranslateComp.WorldLocation).VectorPlaneProject(FVector::UpVector).GetSafeNormal() * ForceStrength;
		}

		
	
		//DEBUG MOVEMENT
		//Debug::DrawDebugArrow(ForceComp.WorldLocation, ForceComp.WorldLocation + ForceComp.Force);


		//CALCULATE ROLL
		//FVector AngularVelocity = CircleTranslateComp.GetVelocity().CrossProduct(FVector::UpVector);
		FVector AngularVelocity = VelocityTrackerComp.LastFrameTranslationVelocity.CrossProduct(FVector::UpVector);


		// if (LerpToMiddleTimeLike.IsPlaying())
		// {
		// 	AngularVelocity = ((RollRoot.RelativeLocation - RollRootLastFrameRelativeLocation) / DeltaSeconds).CrossProduct(FVector::UpVector);
		// 	RollRootLastFrameRelativeLocation = RollRoot.RelativeLocation;
		// }


		float RotationSpeed = (AngularVelocity.Size() / Radius);
		RotationSpeed = Math::Clamp(RotationSpeed, -20.0, 20.0);

		const FQuat DeltaQuat = FQuat(AngularVelocity.GetSafeNormal(), RotationSpeed * DeltaSeconds * -1);
		RollRoot.AddWorldRotation(DeltaQuat);


		//CALCULATE PLAYER HIT
		for (auto Player : Game::GetPlayers())
		{
			if (Player.ActorCenterLocation.Distance(RollRoot.WorldLocation) < Radius + 70.0 && LastTimeHit[Player] + DamageCooldown < Time::GameTimeSeconds)
			{
				LastTimeHit[Player] = Time::GameTimeSeconds;
				Player.DamagePlayerHealth(0.6);
				Player.ApplyStumble(CircleTranslateComp.GetVelocity() * 0.5);
				//Player.ApplyKnockdown(CircleTranslateComp.GetVelocity() * 0.5, 2.5);
				CircleTranslateComp.ApplyImpulse(CircleTranslateComp.WorldLocation, -CircleTranslateComp.GetVelocity() * 2);

				Timer::ClearTimer(this, n"SwitchPlayer");
				SwitchPlayer();
			}
		}


		//CALCULATE LASER IMPACT

		auto Trace = Trace::InitChannel(ECollisionChannel::ECC_WorldDynamic);
		Trace.IgnorePlayers();
		Trace.IgnoreActor(this);

		auto HitResult = Trace.QueryTraceSingle(RollRoot.WorldLocation, RollRoot.WorldLocation + RollRoot.ForwardVector * 3000.0);

		if (HitResult.bBlockingHit)
		{
			LaserImpactVFXComp.SetWorldLocation(HitResult.ImpactPoint);
			LaserImpactVFXComp.SetWorldRotation(FRotator::MakeFromXZ(RollRoot.ForwardVector, HitResult.ImpactNormal));
			LaserMeshComp.SetRelativeScale3D(FVector(0.75, 0.75, HitResult.Distance * 0.00083));

			if (!LaserImpactVFXComp.IsActive())
			{
				LaserImpactVFXComp.Activate(true);
			}
		}
		else if (LaserImpactVFXComp.IsActive())
		{
			LaserImpactVFXComp.Deactivate();
			LaserMeshComp.SetRelativeScale3D(FVector(0.75, 0.75, 2.5));
		}
	}

	UFUNCTION()
	void StartAttack()
	{
		PortalSpawnTimeLike.PlayFromStart();
		RemoveActorDisable(this);
	}

	UFUNCTION()
	void DestroyBallBoss()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFXSystem, RollRoot.WorldLocation);
		AddActorDisable(this);
	}

	UFUNCTION()
	private void PortalSpawnTimeLikeUpdate(float CurrentValue)
	{
		PortalMeshComp.SetRelativeScale3D(FVector(CurrentValue * 15.0));
	}

	UFUNCTION()
	private void PortalSpawnTimeLikeFinished()
	{
		if (!PortalSpawnTimeLike.IsReversed())
		{
			Timer::SetTimer(this, n"DespawnPortal", 2.0);

			BounceTimeLike.PlayFromStart();
			LerpToMiddleTimeLike.PlayFromStart();
			RollRoot.SetHiddenInGame(false, true);
		}
	}


	UFUNCTION()
	private void BounceTimeLikeUpdate(float CurrentValue)
	{
		CircleTranslateComp.SetRelativeLocation(Math::Lerp(FVector::UpVector *  PortalMeshComp.RelativeLocation.Z, FVector::ZeroVector, CurrentValue));
	}

	UFUNCTION()
	private void LerpToMiddleTimeLikeUpdate(float CurrentValue)
	{
		RollRoot.SetRelativeLocation(Math::Lerp(PortalMeshComp.RelativeLocation, RollRootRelativeLocation, CurrentValue)
									 * FVector(1.0, 1.0, 0.0) + FVector::UpVector * RollRootRelativeLocation.Z);
	}

	UFUNCTION()
	private void LerpToMiddleTimeLikeFinished()
	{
		bTrackPlayer = true;
		SwitchPlayer();
	}

	UFUNCTION()
	private void DespawnPortal()
	{
		PortalSpawnTimeLike.Reverse();
	}

	UFUNCTION()
	private void LaserBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                               UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                               const FHitResult&in SweepResult)
	{
		auto HitPlayer = Cast<AHazePlayerCharacter>(OtherActor);

		if (HitPlayer != nullptr)
			HitPlayer.DamagePlayerHealth(0.01);

	}

	UFUNCTION()
	private void SwitchPlayer()
	{
		TargetPlayer = TargetPlayer.OtherPlayer;
		Timer::SetTimer(this, n"SwitchPlayer", 5.0);
	}
};	