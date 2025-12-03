class USkylineBossVulcanoComponent : USceneComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineBossVulcanoProjectile> VulcanoProjectileClass;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem MuzzleVFX;

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	FVector MuzzleLocation;

	UPROPERTY(EditAnywhere)
	float MinRange = 8000.0;

	private int SpawnedVulcanoProjectiles = 0;

	UPROPERTY(EditAnywhere)
	float LaunchInterval = 0.1;

	float TargetAreaRadius = 8000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	FVector GetLaunchLocation() const
	{
		return WorldTransform.TransformPositionNoScale(MuzzleLocation);
	}

	void Fire(AGravityBikeFree TargetBike, FVector LaunchLocation, FVector TargetLocation)
	{
		if(!TargetBike.HasControl())
			return;

		CrumbFire(TargetBike, LaunchLocation, TargetLocation);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbFire(AGravityBikeFree TargetBike, FVector LaunchLocation, FVector TargetLocation)
	{
//		Niagara::SpawnOneShotNiagaraSystemAtLocation(MuzzleVFX, LaunchLocation, WorldRotation);
//		Niagara::SpawnOneShotNiagaraSystemAttached(MuzzleVFX, this).RelativeLocation = MuzzleLocation;

		auto VulcanoProjectile = SpawnActor(VulcanoProjectileClass, LaunchLocation, bDeferredSpawn = true);
		VulcanoProjectile.MakeNetworked(this, n"VulcanoProjectile", SpawnedVulcanoProjectiles);

		// Control projectile on the target bikes side, so that they get the least amount of latency
		VulcanoProjectile.SetActorControlSide(TargetBike);
		SpawnedVulcanoProjectiles++;

		FVector LaunchVelocity = VulcanoProjectile.GetLaunchDirection(WorldLocation, TargetLocation, VulcanoProjectile.VulcanoProjectileLaunchSpeed) * VulcanoProjectile.VulcanoProjectileLaunchSpeed;

		LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(LaunchLocation, TargetLocation, VulcanoProjectile.Gravity.Size(), 3000.0);
		VulcanoProjectile.Velocity = LaunchVelocity;
		VulcanoProjectile.ActorVelocity = LaunchVelocity;

		FinishSpawningActor(VulcanoProjectile);
	}

	FSkylineBossRocketBarrageTarget GetVulcanoTarget(FVector Origin)
	{
		FSkylineBossRocketBarrageTarget Target;

		Target.Location = (Origin + Math::GetRandomPointInCircle_XY() * TargetAreaRadius);
	
		auto Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		FVector Start = Target.Location + (FVector::UpVector * 1000.0);
		FVector End = Start - (FVector::UpVector * 20000.0);

		auto HitResult = Trace.QueryTraceSingle(Start, End);
		if (HitResult.bBlockingHit)
		{
			Target.Location = HitResult.Location;
			Target.bTargetOnGround = true;
		}

		return Target;
	}
};