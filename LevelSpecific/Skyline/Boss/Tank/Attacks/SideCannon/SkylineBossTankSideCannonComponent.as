class USkylineBossTankSideCannonComponent : USceneComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineBossProjectile> ProjetileClass;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem MuzzleVFX;

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	FVector MuzzleLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void Fire(FVector TargetLocation)
	{
		FVector LaunchLocation = WorldTransform.TransformPositionNoScale(MuzzleLocation);

		Niagara::SpawnOneShotNiagaraSystemAttached(MuzzleVFX, this).RelativeLocation = MuzzleLocation;

		auto Projectile = SpawnActor(ProjetileClass, LaunchLocation, bDeferredSpawn = true);

		Projectile.Velocity = ForwardVector * 5000.0;
		Projectile.ActorsToIgnore.Add(Owner);

//		FVector	LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(LaunchLocation, TargetLocation, MortarBall.Gravity, 3000.0);

//		Projectile.ActorVelocity = LaunchVelocity;
		FinishSpawningActor(Projectile);
	}
};