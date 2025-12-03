event void TundraRiverSphereLauncherProjectileEvent();

class ATundra_River_SphereLauncher_Projectile : AHazeActor
{
	TundraRiverSphereLauncherProjectileEvent SpawnFinishedEvent;
	
	UPROPERTY()
	TundraRiverSphereLauncherProjectileEvent OnSphereAboutToLaunch;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USphereComponent Collision;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent ScalingScene;

	UPROPERTY(DefaultComponent, Attach = "ScalingScene")
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = "Mesh")
	USceneComponent InternalScaleScene;

	UPROPERTY(DefaultComponent, Attach = "InternalScaleScene")
	UStaticMeshComponent InternalMesh;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UTundraTreeGuardianRangedInteractionTargetableComponent TargetComp;
	default TargetComp.InteractionType = ETundraTreeGuardianRangedInteractionType::Shoot;
	default TargetComp.AutoAimMaxAngle = 360;
	default TargetComp.MinimumDistance = 300;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPos;

	FVector StartLocation;
	float Height;
	bool bHasBeenLaunched = false;
	bool bIsMovingUp = false;
	FVector Velocity;
	float LaunchSpeed = 20000;
	float LifeTime;
	float MaxLifeTime = 5;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditInstanceOnly)
	float DotProdForGuaranteedHit = 0.7;

	UPROPERTY()
	FHazeTimeLike SpawnAnimation;
	default SpawnAnimation.Duration = 4;
	default SpawnAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default SpawnAnimation.Curve.AddDefaultKey(4, 1.0);

	UPROPERTY()
	FHazeTimeLike MoveAnimation;
	default MoveAnimation.Duration = 3;
	default MoveAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default MoveAnimation.Curve.AddDefaultKey(1.0, 1.0);
	default MoveAnimation.Curve.AddDefaultKey(3.0, 1.0);

	UPROPERTY()
	FHazeTimeLike ActivationScaleAnimation;
	default ActivationScaleAnimation.Duration = 0.5;
	default ActivationScaleAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default ActivationScaleAnimation.Curve.AddDefaultKey(0.5, 1.0);

	UPROPERTY()
	FHazeTimeLike PulseAnimation;
	default PulseAnimation.Duration = 6;
	default PulseAnimation.Curve.AddDefaultKey(0.0, 1.0);
	default PulseAnimation.Curve.AddDefaultKey(6.0, 1.0);
	default PulseAnimation.bLoop = true;

	float CurrentTimeDilation = 1;
	float TargetTimeDilation = 1;
	float TimeDilationInterpSpeed = 0.7;
	float MoveAnimationTargetPlayRate = 1;
	float MoveAnimationCurrentPlayRate = 1;
	float MoveAnimationPlayRateInterpSpeed = 8;
	bool bTargetCompEnabled = false;

	bool bProjectileActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);

		TargetComp.OnCommitInteract.AddUFunction(this, n"HandleGrappleCommit");
		TargetComp.Disable(this);
		TargetComp.OnShootInteractLaunch.AddUFunction(this, n"Launch");
		Disable();
		SpawnAnimation.BindUpdate(this, n"TL_SpawnAnimationUpdate");
		SpawnAnimation.BindFinished(this, n"TL_SpawnAnimationFinished");
		MoveAnimation.BindUpdate(this, n"TL_MoveAnimationUpdate");
		MoveAnimation.BindFinished(this, n"TL_MoveAnimationFinished");
		ActivationScaleAnimation.BindUpdate(this, n"TL_ActivationScaleAnimationUpdate");
		ActivationScaleAnimation.BindFinished(this, n"TL_ActivationScaleAnimationFinished");
		PulseAnimation.BindUpdate(this, n"TL_PulseAnimationUpdate");
	}

	UFUNCTION()
	private void TL_PulseAnimationUpdate(float CurrentValue)
	{
		InternalScaleScene.SetRelativeScale3D(FVector(CurrentValue, CurrentValue, CurrentValue));
	}

	UFUNCTION()
	private void TL_ActivationScaleAnimationFinished()
	{
		SpawnFinishedEvent.Broadcast();
		PulseAnimation.PlayFromStart();
	}

	UFUNCTION()
	private void TL_ActivationScaleAnimationUpdate(float CurrentValue)
	{
		InternalScaleScene.SetRelativeScale3D(FVector(CurrentValue, CurrentValue, CurrentValue));
	}

	UFUNCTION()
	private void HandleGrappleCommit()
	{
		MoveAnimationTargetPlayRate = 0;
		bIsMovingUp = false;
	}

	UFUNCTION()
	private void Launch(UTundraTreeGuardianRangedShootTargetable Targetable, FVector FallbackDirection)
	{
		Velocity = FallbackDirection * LaunchSpeed;
		if(Targetable != nullptr)
		{
			FVector SphereToTargetVector = (Targetable.WorldLocation - ActorLocation).GetSafeNormal();
			Velocity = SphereToTargetVector * LaunchSpeed;
		}

		bHasBeenLaunched = true;
		TargetComp.Disable(this);
		LifeTime = MaxLifeTime;
	}

	UFUNCTION()
	void Disable()
	{
		bProjectileActive = false;
		TargetComp.Disable(this);
		SetActorHiddenInGame(true);
		bHasBeenLaunched = false;
		bIsMovingUp = false;
		UTundra_River_SphereLauncher_Projectile_EffectHandler::Trigger_Break(this);
		InternalScaleScene.SetRelativeScale3D(FVector(0.001, 0.001, 0.001));
		MoveAnimation.Stop();
	}

	UFUNCTION()
	private void TL_MoveAnimationFinished()
	{
		if(bIsMovingUp)
		{
			Disable();
		}
	}

	UFUNCTION()
	private void TL_MoveAnimationUpdate(float CurrentValue)
	{
		if(bIsMovingUp)
		{
			PrintToScreen("CurrentValue: " + CurrentValue);
			FVector Location = StartLocation + FVector(0.0, 0.0, Height * CurrentValue);
			SetActorLocation(Location);
		}

		if(CurrentValue > 1 && !bTargetCompEnabled)
		{
			TargetComp.Enable(this);
			bTargetCompEnabled = true;
		}
	}

	UFUNCTION()
	private void TL_SpawnAnimationFinished()
	{
		ActivationScaleAnimation.PlayFromStart();
	}

	UFUNCTION()
	private void TL_SpawnAnimationUpdate(float CurrentValue)
	{
		ScalingScene.SetRelativeScale3D(FVector(CurrentValue, CurrentValue, CurrentValue));
	}

	UFUNCTION()
	void StartMoving()
	{
		bProjectileActive = true;
		bTargetCompEnabled = false;
		MoveAnimation.SetPlayRate(1);
		MoveAnimationTargetPlayRate = 1;
		MoveAnimationCurrentPlayRate = 1;
		MoveAnimation.PlayFromStart();
		bIsMovingUp = true;
		PulseAnimation.Stop();
		OnSphereAboutToLaunch.Broadcast();
	}

	UFUNCTION()
	ATundra_River_SphereLauncher_Projectile Spawn(FVector SpawnLocation, float InHeight, bool bInstantSpawn)
	{
		bHasBeenLaunched = false;
		Height = InHeight;
		StartLocation = SpawnLocation;
		SetActorLocation(StartLocation);
		SetActorHiddenInGame(false);
		InternalScaleScene.SetRelativeScale3D(FVector(0.001,0.001,0.001));
		
		if (bInstantSpawn)
		{
			ScalingScene.SetRelativeScale3D(FVector::OneVector);
			ActivationScaleAnimation.PlayFromStart();
		}
		else
			SpawnAnimation.PlayFromStart();
		return this;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!HasControl())
		{
			auto Position = SyncedActorPos.GetPosition();
			ActorLocation = Position.WorldLocation;
			ActorRotation = Position.WorldRotation;
			return;
		}

		if(bHasBeenLaunched)
		{
			LifeTime -= DeltaTime;
			if(LifeTime <= 0)
			{
				Disable();
			}

			FVector Delta = Velocity * DeltaTime;

			FHazeTraceSettings Trace = Trace::InitAgainstComponent(Game::Mio.CapsuleComponent);
			FHitResult Hit = Trace.QueryTraceComponent(ActorLocation, ActorLocation + Delta);
			if(Hit.bBlockingHit)
			{
				CrumbHitTarget(Hit.Actor);
			}
			else
			{
				Trace = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
				Trace.IgnoreActor(Game::Zoe);
				Trace.IgnoreActor(this);
				Trace.UseSphereShape(Collision);
				Hit = Trace.QueryTraceSingle(ActorLocation, ActorLocation + Delta);

				if(Hit.bBlockingHit)
				{
					CrumbHitTarget(Hit.Actor);
				}
			}

			ActorLocation += Delta;
		}
		else if(bIsMovingUp)
		{
			if(UTundraPlayerTreeGuardianComponent::Get(Game::GetZoe()).CurrentlyFoundRangedInteractionTargetable == TargetComp)
			{
				TargetTimeDilation = 0.3;
			}
			else
			{
				TargetTimeDilation = 1;
			}
		}

		else
		{
			TargetTimeDilation = 1;
		}

		if(TargetTimeDilation != CurrentTimeDilation)
		{
			CurrentTimeDilation = Math::FInterpConstantTo(CurrentTimeDilation, TargetTimeDilation, Time::UndilatedWorldDeltaSeconds, TimeDilationInterpSpeed);
			//Time::SetWorldTimeDilation(CurrentTimeDilation);
		}

		MoveAnimationCurrentPlayRate = Math::FInterpConstantTo(MoveAnimationCurrentPlayRate, MoveAnimationTargetPlayRate, DeltaTime, MoveAnimationPlayRateInterpSpeed);
		MoveAnimation.SetPlayRate(MoveAnimationCurrentPlayRate);
	}

	UFUNCTION(CrumbFunction)
	void CrumbHitTarget(AActor HitActor)
	{
		Disable();
		auto HitResponseComp = UTundraTreeGuardianRangedShootTargetable::Get(HitActor);
		if(HitResponseComp != nullptr)
		{
			HitResponseComp.OnHit.Broadcast();
		}

		auto HitPlayer = Cast<AHazePlayerCharacter>(HitActor);
		if(HitPlayer != nullptr)
			HitPlayer.KillPlayer();
		
		UTundra_River_SphereLauncher_Projectile_EffectHandler::Trigger_HitTarget(this);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 15000, 25000, 1.0, 1);
	}
};