class ASkylineBallBossSurfaceAttacker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent ProjectileSpawnRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent RingMeshComp;

	UPROPERTY(DefaultComponent, Attach = ProjectileSpawnRoot)
	USceneComponent ExtrudeRoot;

	UPROPERTY(DefaultComponent, Attach = ExtrudeRoot)
	UStaticMeshComponent TurretMeshComp;

	UPROPERTY(DefaultComponent, Attach = ExtrudeRoot)
	UStaticMeshComponent TurretMeshHatComp;

	UPROPERTY(Category = Shockwave)
	FHazeTimeLike ShockwaveTimeLike;
	default ShockwaveTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY(Category = Shockwave)
	float ShockwaveExtrudeAmount = 100.0;

	UPROPERTY(EditAnywhere, Category = Shockwave)
	float ShockwaveInterval = 3.0;

	UPROPERTY(EditInstanceOnly, Category = Shockwave)
	float ShockwaveStartOffset = 0.0;

	UPROPERTY(EditInstanceOnly)
	bool bExtrudeProjectile = false;

	UPROPERTY(Category = Projectile)
	FHazeTimeLike ProjectileExtrudeTimeLike;
	default ProjectileExtrudeTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY(Category = Projectile)
	float ProjectileExtrudeAmount = 150.0;

	UPROPERTY(Category = Projectile)
	float RotationPerProjectile = 20.0;
	float RotationOfFset;

	UPROPERTY(Category = Projectile)
	float ProjectileInterval = 0.3;

	UPROPERTY(EditInstanceOnly, Category = Projectile)
	float ProjectileStartOffset = 4.0;

	UPROPERTY(Category = Shockwave)
	TSubclassOf<ASkylineBallBossShockwave> ShockwaveClass;

	UPROPERTY(Category = Projectile)
	TSubclassOf<ASkylineBallBossSurfaceAttackerProjectile> ProjectileClass;

	ASkylineBallBoss BallBoss;

	ASkylineBallBossChargeLaser ChargeLaser;

	bool bShooting = false;

	bool bKnockingOffPlayer = false;

	bool bHasFallenOff = false;
	const float ExtrudeDuration = 0.5;
	FHazeAcceleratedFloat AccExtrudeOffset;
	FVector OGExtrude;
	float GravityForce = 0.0;
	FVector FallOffDirection;
	FVector FallOffRightVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ShockwaveTimeLike.BindUpdate(this, n"ShockwaveTimeLikeUpdate");
		ShockwaveTimeLike.BindFinished(this, n"ShockwaveTimeLikeFinished");
		ProjectileExtrudeTimeLike.BindUpdate(this, n"ProjectileExtrudeTimeLikeUpdate");
		ProjectileExtrudeTimeLike.BindFinished(this, n"ProjectileExtrudeTimeLikeFinished");

		BallBoss = Cast<ASkylineBallBoss>(AttachmentRootActor);
		BallBoss.OnPhaseChanged.AddUFunction(this, n"HandlePhaseChanged");

		ChargeLaser = Cast<ASkylineBallBossChargeLaser>(AttachParentActor);
		ChargeLaser.OnBecomeWeak.AddUFunction(this, n"HandleFallOff");
		OGExtrude = TurretMeshHatComp.RelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bShooting)
		{
			ProjectileSpawnRoot.AddRelativeRotation(FRotator(0.0, (RotationPerProjectile / ProjectileInterval) * DeltaSeconds, 0.0));
		}
		if (bHasFallenOff)
		{
			GravityForce += DeltaSeconds * 2000.0;

			FVector DeltaWorldOffset = (FallOffDirection * 1000.0 + FVector::DownVector * GravityForce) * DeltaSeconds;
			FQuat DeltaRotation = FQuat(FallOffRightVector, Math::DegreesToRadians(50.0 * DeltaSeconds));
			MeshRoot.AddWorldRotation(DeltaRotation);
			MeshRoot.AddWorldOffset(DeltaWorldOffset);
		}
	}
	
	UFUNCTION()
	private void HandlePhaseChanged(ESkylineBallBossPhase NewPhase)
	{
		if (NewPhase == ESkylineBallBossPhase::TopMioOn1)
		{
			StartSpawningShockwaves();
		}

		if (NewPhase == ESkylineBallBossPhase::TopAlignMioToStage)
		{
			Deactivate();
		}

		if (NewPhase == ESkylineBallBossPhase::TopMioOn2)
		{
			if (bExtrudeProjectile)
			{
				if (ProjectileStartOffset <= 0.0)
					ProjectileExtrude();
				else
					Timer::SetTimer(this, n"ProjectileExtrude", ProjectileStartOffset);
			}
				
			else
				StartSpawningShockwaves();
		}

		if (NewPhase == ESkylineBallBossPhase::TopMioOnEyeBroken)
		{
			Deactivate();
		}

		if (NewPhase == ESkylineBallBossPhase::TopShieldShockwave)
		{
			bKnockingOffPlayer = true;
			Timer::SetTimer(this, n"SpawnShockwave", 1.0);
		}

		if (NewPhase == ESkylineBallBossPhase::TopMioIn)
		{
			//StartSpawningShockwavesInside();
		}
	}

	UFUNCTION()
	void HandleFallOff()
	{
		if (bHasFallenOff)
			return;

		// Timer::ClearTimer(this, n"SpawnShockwaveInside");

		DetachFromActor(EDetachmentRule::KeepWorld);
		FallOffDirection = ActorUpVector;
		if (FallOffDirection.GetSafeNormal().DotProduct(FVector::UpVector) >= 1.0 - KINDA_SMALL_NUMBER)
			FallOffRightVector = FRotator::MakeFromXZ(FallOffDirection, FVector::RightVector).RightVector;
		else
			FallOffRightVector = FRotator::MakeFromXZ(FallOffDirection, FVector::UpVector).RightVector;
		bHasFallenOff = true;

		BP_FallOff();
	}

	UFUNCTION()
	void ParentChargeLaserDestroyed()
	{
		AddActorDisable(this);
		AddActorVisualsBlock(this);
	}

	private void Deactivate()
	{
		Timer::ClearTimer(this, n"SpawnShockwave");
		Timer::ClearTimer(this, n"CallSpawnProjectile");
		ProjectileExtrudeTimeLike.Reverse();
		ShockwaveTimeLike.Reverse();
	}

	private void StartSpawningShockwaves()
	{
		if (ShockwaveStartOffset <= 0.0)
			SpawnShockwave();
		else
			Timer::SetTimer(this, n"SpawnShockwave", ShockwaveStartOffset);
	}

	// private void StartSpawningShockwavesInside()
	// {
	// 	if (ShockwaveStartOffset <= 0.0)
	// 		SpawnShockwave();
	// 	else
	// 		Timer::SetTimer(this, n"SpawnShockwaveInside", ShockwaveStartOffset);
	// }

	UFUNCTION()
	private void SpawnShockwave()
	{
		ShockwaveTimeLike.PlayFromStart();
	}

	UFUNCTION()
	private void ShockwaveTimeLikeUpdate(float CurrentValue)
	{
		ExtrudeRoot.SetRelativeLocation(FVector::UpVector * Math::Lerp(0.0, ShockwaveExtrudeAmount, CurrentValue));
	}

	UFUNCTION()
	private void ShockwaveTimeLikeFinished()
	{
		if (ShockwaveTimeLike.IsReversed())
			return;

		if (bKnockingOffPlayer)
		{
			bKnockingOffPlayer = false;
			return;
		}

		FVector Location = ActorLocation + ActorUpVector * 1000.0;
		FRotator Rotation = FRotator::MakeFromX(ActorUpVector);
		ASkylineBallBossShockwave SpawnedShockwave = SpawnActor(ShockwaveClass, Location, Rotation, bDeferredSpawn = true);
		SpawnedShockwave.BallBoss = BallBoss;
		FinishSpawningActor(SpawnedShockwave);
		SpawnedShockwave.AttachToComponent(BallBoss.FakeRootComp, NAME_None, EAttachmentRule::KeepWorld);

		BP_ShockwaveSlam(Location);

		Timer::SetTimer(this, n"SpawnShockwave", ShockwaveInterval);
	}

	// UFUNCTION()
	// private void SpawnShockwaveInside()
	// {
	// 	FVector Location = ActorLocation + ActorUpVector * 900.0;
	// 	FRotator Rotation = FRotator::MakeFromX(ActorUpVector);
	// 	auto SpawnedShockwave = SpawnActor(ShockwaveClass, Location, Rotation, bDeferredSpawn = true);
	// 	SpawnedShockwave.BallBoss = BallBoss;
	// 	SpawnedShockwave.BallBossRadius = 880.0;
	// 	FinishSpawningActor(SpawnedShockwave);
	// 	SpawnedShockwave.AttachToComponent(BallBoss.FakeRootComp, NAME_None, EAttachmentRule::KeepWorld);

	// 	BP_ShockwaveSlam(Location);

	// 	Timer::SetTimer(this, n"SpawnShockwaveInside", ShockwaveInterval);
	// }

	UFUNCTION(BlueprintEvent)
	void BP_ShockwaveSlam(FVector Location){}

	UFUNCTION()
	void ProjectileExtrude()
	{
		if (IsActorDisabled())
			return;
		TurretMeshComp.SetHiddenInGame(false);
		ProjectileExtrudeTimeLike.Play();
	}

	UFUNCTION()
	void RemoveProjectileExtrude()
	{
		ProjectileExtrudeTimeLike.Reverse();
	}

	UFUNCTION()
	private void ProjectileExtrudeTimeLikeUpdate(float CurrentValue)
	{
		ExtrudeRoot.SetRelativeLocation(FVector::UpVector * Math::Lerp(0.0, ProjectileExtrudeAmount, CurrentValue));
	}

	UFUNCTION()
	private void ProjectileExtrudeTimeLikeFinished()
	{
		if (ProjectileExtrudeTimeLike.IsReversed())
		{
			bShooting = false;
			TurretMeshComp.SetHiddenInGame(true);
		}
		else
		{
			bShooting = true;
			Timer::SetTimer(this, n"CallSpawnProjectile", ProjectileInterval, true);
		}
	}

	UFUNCTION()
	private void CallSpawnProjectile()
	{
		SpawnProjectile();
	}

	UFUNCTION()
	void SpawnProjectile()
	{
		FRotator Rotation = ProjectileSpawnRoot.WorldRotation;

		auto SpawnedProjectile = SpawnActor(ProjectileClass, ActorLocation, Rotation, bDeferredSpawn = true);
		FinishSpawningActor(SpawnedProjectile);
		SpawnedProjectile.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);

		USkylineBallBossSurfaceAttackerEventHandler::Trigger_OnProjectileFire(this);

		BP_SpawnProjectile();
	}

	UFUNCTION(BlueprintEvent)
	void BP_SpawnProjectile(){}

	UFUNCTION(BlueprintEvent)
	void BP_FallOff(){}
};

class USkylineBallBossSurfaceAttackerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnProjectileFire() 
	{
		// PrintToScreen("OnProjectileFire", 5.0);
	}

}