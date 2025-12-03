class AGameShowArenaTurret : AGameShowArenaDynamicObstacleBase
{
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent TurretRoot;

	UPROPERTY(DefaultComponent, Attach = TurretRoot)
	UStaticMeshComponent TurretBase;

	UPROPERTY(DefaultComponent, Attach = TurretRoot)
	UStaticMeshComponent Turret;

	UPROPERTY(DefaultComponent, Attach = TurretRoot)
	UStaticMeshComponent LaserMesh;

	UPROPERTY(DefaultComponent, Attach = Turret)
	USceneComponent ShootLocation;

	UPROPERTY(DefaultComponent, Attach = Turret)
	UNiagaraComponent ChargeVFX;
	default ChargeVFX.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent ProjectileTrailVFX;
	default ProjectileTrailVFX.bAutoActivate = false;

	UPROPERTY(EditInstanceOnly)
	TArray<AGameShowArenaTurretProjectile> Projectiles;

	AGameShowArenaTurretProjectile CurrentProjectile;

	TArray<FRotator> MeshRootRotations;
	TArray<FRotator> TurretRootRotations;
	FRotator TargetMeshRootRotation;
	FRotator TargetTurretRootRotation;

	int RotationIndex = 0;

	bool bShouldTickRotationTimer = false;
	float RotationTimer = 0;
	float RotationTimerDuration = 0.5;

	bool bShouldTickShootDelayTimer = false;
	float ShootDelayTimer = 0;
	float ShootDelay = 0.5;

	FHazeAcceleratedVector AccRelativeLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MeshRootRotations.Add(FRotator(0, 28.8, 0));
		MeshRootRotations.Add(FRotator(0, -28.8, 0));
		MeshRootRotations.Add(FRotator(0, 38, 0));
		MeshRootRotations.Add(FRotator(0, -38, 0));

		TurretRootRotations.Add(FRotator(0, -90, 15));
		TurretRootRotations.Add(FRotator(0, -90, 15));
		TurretRootRotations.Add(FRotator(0, -90, 19));
		TurretRootRotations.Add(FRotator(0, -90, 19));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bShouldTickRotationTimer)
		{
			AccRelativeLocation.AccelerateTo(FVector::ZeroVector, 1, DeltaSeconds);
			MeshRoot.SetRelativeLocation(AccRelativeLocation.Value);
		}
		if (bShouldTickRotationTimer)
		{
			RotationTimer += DeltaSeconds;
			float Alpha = Math::Saturate(RotationTimer / RotationTimerDuration);
			MeshRoot.SetRelativeRotation(FQuat::Slerp(MeshRoot.RelativeRotation.Quaternion(), TargetMeshRootRotation.Quaternion(), Alpha));
			FRotator NewRotation = MeshRoot.WorldTransform.InverseTransformRotation(FRotator::MakeFromYZ(CurrentProjectile.MeshRoot.WorldLocation - TurretRoot.WorldLocation, FVector::UpVector));
			TurretRoot.SetRelativeRotation(FQuat::Slerp(TurretRoot.RelativeRotation.Quaternion(), NewRotation.Quaternion(), Alpha));
			SetLaserScale();

			if (Alpha >= 1)
			{
				bShouldTickRotationTimer = false;
				ShootDelayTimer = 0;
				bShouldTickShootDelayTimer = true;
				CurrentProjectile.ActivateProjectile(ShootLocation.WorldLocation);
			}
		}

		if (bShouldTickShootDelayTimer)
		{
			ShootDelayTimer += DeltaSeconds;

			if (ShootDelayTimer >= ShootDelay)
			{
				bShouldTickShootDelayTimer = false;
				StartShooting();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		MeshRoot.SetRelativeRotation(FRotator(0, 28.125, 0));
		MeshRoot.SetRelativeLocation(FVector::UpVector * 1000);
		AccRelativeLocation.SnapTo(MeshRoot.RelativeLocation);
		Timer::SetTimer(this, n"StartShooting", 1);
	}

	UFUNCTION()
	void StartShooting()
	{
		RotationIndex++;
		TargetMeshRootRotation = MeshRootRotations[(RotationIndex + 1) % MeshRootRotations.Num()];
		TargetTurretRootRotation = TurretRootRotations[(RotationIndex + 1) % TurretRootRotations.Num()];
		RotationTimer = 0;
		bShouldTickRotationTimer = true;
		CurrentProjectile = Projectiles[(RotationIndex + 1) % MeshRootRotations.Num()];
	}

	UFUNCTION()
	void DeactivateTurret()
	{
		SetActorHiddenInGame(true);
		SetActorTickEnabled(false);
	}

	void SetLaserScale()
	{
		FVector LaserScale = LaserMesh.GetWorldScale();
		LaserScale.X = Math::Abs((CurrentProjectile.ActorLocation - LaserMesh.WorldLocation).Size());
		LaserMesh.SetWorldScale3D(LaserScale);
	}
};