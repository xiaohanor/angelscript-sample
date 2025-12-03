class AMeltdownBossPhaseThreeSmashPortal : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent ProjectileRoot;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent PortalMesh;

	UPROPERTY(DefaultComponent)
	USceneComponent TelegraphRoot;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = TelegraphRoot)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(EditAnywhere, Category = "Missile Projectile")
	float Radius = 200;

	UPROPERTY(EditAnywhere, Category = "Missile Projectile")
	float Speed = 200;

	UPROPERTY(EditAnywhere, Category = "Missile Projectile")
	float HitDuration = 0.5;

	UPROPERTY(EditAnywhere, Category = "Missile Projectile")
	float RestoreDuration = 0.5;

	UPROPERTY(EditAnywhere, Category = "Tracking")
	float TrackingAccelerationDuration = 5;

	bool bIsTelegraphing = false;
	bool bHasFired = false;
	bool bHasHit = false;

	float FireTimer = 0.0;
	float FireCountdown = 0.0;
	float HitTimer = 0.0;
	
	AHazePlayerCharacter TrackPlayer;
	float TrackTimer = 0.0;

	bool bAutoDestroy = false;

	FVector DefaultOffset;
	FHazeAcceleratedVector TrackedLocation;

	FHazeTimeLike Stomp;
	default Stomp.Duration = 0.5;
	default Stomp.UseSmoothCurveZeroToOne();

	FHazeTimeLike Portal;
	default Portal.Duration = 1;
	default Portal.UseSmoothCurveZeroToOne();

	FVector StartLocation;
	FVector EndLocation;

	FVector StartScale;

	UPROPERTY()
	FVector EndScale;

	UFUNCTION()
	void StartAttack(float TelegraphTime = 2.0, AHazePlayerCharacter PlayerToTrack = nullptr, float TrackDuration = 0.0)
	{
		FireCountdown = TelegraphTime;
		TrackPlayer = PlayerToTrack;
		TrackTimer = TrackDuration;
		StartTelegraph();
		Portal.Play();
		ProjectileRoot.SetHiddenInGame(true, true);
	}

	UFUNCTION(DevFunction)
	void StartTelegraph()
	{
		RemoveActorDisable(this);
		bIsTelegraphing = true;
		bHasFired = false;
		bHasHit = false;

		ProjectileRoot.RelativeLocation = DefaultOffset;

		TrackedLocation.SnapTo(ActorLocation);
	}

	UFUNCTION(DevFunction)
	void StartFiring()
	{
		RemoveActorDisable(this);
		bIsTelegraphing = false;
		bHasFired = true;
		bHasHit = false;

	//	ProjectileRoot.SetHiddenInGame(false, true);
		
	//	ProjectileRoot.RelativeLocation = DefaultOffset;
	}

	UFUNCTION(DevFunction)
	void HitImpact()
	{
		RemoveActorDisable(this);
		bIsTelegraphing = false;
		bHasFired = false;
		bHasHit = true;
		HitTimer = HitDuration + RestoreDuration;
		OnHitShake();
	}

	UFUNCTION(BlueprintEvent)
	void OnHitShake()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		DefaultOffset = ProjectileRoot.RelativeLocation;

		Stomp.BindFinished(this, n"OnFinished");
		Stomp.BindUpdate(this, n"OnUpdate");

		Portal.BindFinished(this, n"PortalOpen");
		Portal.BindUpdate(this, n"PortalOpening");

		StartLocation = ProjectileRoot.RelativeLocation;
		EndLocation = TelegraphRoot.RelativeLocation;

		StartScale = FVector(0.1,0.1,0.1);
	}

	UFUNCTION()
	private void PortalOpening(float CurrentValue)
	{
		PortalMesh.SetRelativeScale3D(Math::Lerp(StartScale,EndScale,CurrentValue));
	}

	UFUNCTION()
	private void PortalOpen()
	{
		if(Portal.IsReversed())
		AddActorDisable(this);
		
		ProjectileRoot.SetHiddenInGame(false, true);
	}

	UFUNCTION()
	private void OnUpdate(float CurrentValue)
	{
		ProjectileRoot.SetRelativeLocation(Math::Lerp(StartLocation,EndLocation,CurrentValue));
	}

	UFUNCTION()
	private void OnFinished()
	{
			if(Stomp.IsReversed())
			{
			Portal.Reverse();
			ProjectileRoot.SetHiddenInGame(true, true);
			return;
			}

			HitImpact();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bHasHit)
		{
			HitTimer -= DeltaSeconds;
			if (HitTimer <= 0.0)
			{
				Stomp.Reverse();
			}
		}
		else if (bHasFired)
		{
			Stomp.Play();
			TelegraphRoot.SetHiddenInGame(true, true);
		}
		else if (bIsTelegraphing)
		{
			if (TrackTimer > 0)
			{
				TrackTimer -= DeltaSeconds;
				UpdatePlayerTracking(DeltaSeconds);
			}

			if (FireCountdown > 0.0)
			{
				FireCountdown -= DeltaSeconds;
				if (FireCountdown <= 0.0)
					StartFiring();
			}
		}
	}

		void UpdatePlayerTracking(float DeltaTime)
	{
		if (TrackPlayer == nullptr)
			return;

		FVector TargetLocation = TrackPlayer.ActorLocation;
		TargetLocation.Z = ActorLocation.Z;

		if (TrackingAccelerationDuration <= 0.0)
		{
			TrackedLocation.SnapTo(TargetLocation);
		}
		else
		{
			TrackedLocation.AccelerateTo(TargetLocation, TrackingAccelerationDuration, DeltaTime);
		}

		SetActorLocation(TrackedLocation.Value);
	}
};