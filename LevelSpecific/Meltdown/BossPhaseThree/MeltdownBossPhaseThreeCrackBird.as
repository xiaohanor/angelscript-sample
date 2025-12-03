class AMeltdownBossPhaseThreeCrackBird : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent PortalMesh;

	UPROPERTY(DefaultComponent)
	USceneComponent ProjectileRoot;

	UPROPERTY(DefaultComponent)
	UHazeDecalComponent TelegraphDecal;

	FHazeTimeLike OpenPortal;
	default OpenPortal.Duration = 1.0;
	default OpenPortal.UseSmoothCurveZeroToOne();

	AHazePlayerCharacter TargetPlayer;

	FHazeAcceleratedQuat AccRotation;

	FVector TargetLocation;

	UPROPERTY()
	UNiagaraSystem BirdExplosionSystem;

	UPROPERTY()
	float Speed = 3000.0;
	UPROPERTY()
	float Duration = 2.0;
	UPROPERTY()
	float BirdRadius = 200.0;
	UPROPERTY()
	float Damage = 0.6;
	UPROPERTY()
	int Projectiles = 2;
	int ShotProjectiles = 0;

	UPROPERTY()
	FVector StartScale;
	UPROPERTY()
	FVector EndScale = FVector(5.0);

	bool bShot = false;
	float ShootDistance;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		OpenPortal.BindFinished(this, n"PortalFinished");
		OpenPortal.BindUpdate(this, n"PortalUpdate");

		TelegraphDecal.SetHiddenInGame(true);

		StartScale = PortalMesh.RelativeScale3D;
	}

	UFUNCTION(BlueprintCallable, DevFunction)
	void Launch(AHazePlayerCharacter PlayerToTrack = nullptr)
	{
		bShot = false;
		TargetPlayer = PlayerToTrack;
		OpenPortal.Play();
		RemoveActorDisable(this);

		ProjectileRoot.SetHiddenInGame(true, true);

		ProjectileRoot.RelativeLocation = FVector::ZeroVector;

		FQuat TargetDirection = FQuat::MakeFromZX(FVector::UpVector, (TargetPlayer.ActorLocation - ActorLocation));
		AccRotation.SnapTo(TargetDirection);
		SetActorRotation(TargetDirection);
	}

	UFUNCTION()
	private void PortalUpdate(float CurrentValue)
	{
		PortalMesh.SetRelativeScale3D(Math::Lerp(StartScale,EndScale,CurrentValue));
	}

	UFUNCTION()
	private void PortalFinished()
	{
		if(OpenPortal.IsReversed())
			AddActorDisable(this);

		StartAnimation();
		ProjectileRoot.SetHiddenInGame(false, true);
	}

	UFUNCTION(BlueprintEvent)
	void StartAnimation() {}

	UFUNCTION(BlueprintCallable)
	void EndAttack()
	{
		OpenPortal.Reverse();
	}

	UFUNCTION(BlueprintCallable)
	void StartShooting()
	{
		ShootDistance = ActorLocation.Distance(TargetLocation);

		bShot = true;
		TelegraphDecal.SetHiddenInGame(false);
		TelegraphDecal.SetWorldLocationAndRotation(TargetLocation, FRotator(90.0, 0.0, 0.0));
	}

	private void Explode()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(BirdExplosionSystem, ProjectileRoot.WorldLocation);
		ProjectileRoot.SetHiddenInGame(true, true);
		TelegraphDecal.SetHiddenInGame(true);

		bShot = false;

		ShotProjectiles++;

		if (ShotProjectiles < Projectiles)
		{
			//StartAnimation();
			ProjectileRoot.SetHiddenInGame(false, true);
			ProjectileRoot.SetRelativeLocation(FVector::ZeroVector);

			Timer::SetTimer(this, n"StartAnimation", 1.0);
			//Switch Player
			//TargetPlayer = TargetPlayer.OtherPlayer;
		}

		else
			EndAttack();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bShot)
		{
			FVector NewLocation = ProjectileRoot.RelativeLocation + FVector::ForwardVector * Speed * DeltaSeconds;
			ProjectileRoot.SetRelativeLocation(NewLocation);

			if (ProjectileRoot.RelativeLocation.X > ShootDistance)
				Explode();

			for (auto Player : Game::GetPlayers())
			{
				if (ProjectileRoot.WorldLocation.Distance(Player.ActorLocation) < BirdRadius)
				{
					Player.DamagePlayerHealth(Damage);
					Player.ApplyStumble(ProjectileRoot.ForwardVector * 500.0);
					Explode();
				}
			}
		}
		else
		{
			//Find impact location
			auto Trace = Trace::InitProfile(n"PlayerCharacter");
			auto HitResult = Trace.QueryTraceSingle(TargetPlayer.ActorLocation, TargetPlayer.ActorLocation - FVector::UpVector * 1000.0);

			if (HitResult.bBlockingHit)
				TargetLocation = HitResult.Location;

			else
				TargetLocation = TargetPlayer.ActorLocation;

			FQuat TargetDirection = (TargetLocation - ActorLocation).GetSafeNormal().ToOrientationQuat();

			AccRotation.AccelerateTo(TargetDirection, 1.0, DeltaSeconds);
			SetActorRotation(AccRotation.Value);
		}
	}
};