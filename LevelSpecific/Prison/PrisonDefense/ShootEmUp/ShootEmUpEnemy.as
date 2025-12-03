class AShootEmUpEnemy : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent EnemyRoot;

	UPROPERTY(DefaultComponent, Attach = EnemyRoot)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem DestroyEffect;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AShootEmUpEnemyProjectile> ProjectileClass;

	UPROPERTY(EditAnywhere)
	ASplineActor TargetSpline;
	float SplineDist = 0.0;
	float SplineSpeed = 1000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Timer::SetTimer(this, n"ShootProjectile", 0.75, true);
	}

	UFUNCTION()
	void ShootProjectile()
	{
		FVector Dir = ActorForwardVector;
		bool bDown = Math::RandBool();
		float Angle = Math::RandRange(0.0, 20.0);
		if (bDown)
			Angle *= -1;
		Dir = Dir.RotateAngleAxis(Angle, ActorRightVector);
		SpawnActor(ProjectileClass, ActorLocation, Dir.Rotation());
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SkelMesh.AddLocalRotation(FRotator(300.0 * DeltaTime, 0.0, 0.0));

		if (TargetSpline != nullptr)
		{
			SplineDist += SplineSpeed * DeltaTime;
			FVector Loc = TargetSpline.Spline.GetWorldLocationAtSplineDistance(SplineDist);
			SetActorLocation(Loc);
			if (SplineDist >= TargetSpline.Spline.SplineLength)
				SplineDist = 0.0;
		}
	}

	void Destroy()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(DestroyEffect, ActorLocation);
		if (TargetSpline != nullptr)
			SplineDist = 0.0;
		else
			DestroyActor();
	}
}