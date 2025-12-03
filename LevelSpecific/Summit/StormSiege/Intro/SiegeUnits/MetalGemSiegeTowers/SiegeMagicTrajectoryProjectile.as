class ASiegeMagicTrajectoryProjectile : ASiegeBaseProjectile
{
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ProjectileComp;

	FVector Velocity;
	float Gravity = 1400.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(ActorLocation, TargetLocation, Gravity, Speed);
		FSiegeMagicTrajectoryProjectileFireParams FireParams;
		FireParams.Location = ActorLocation;
		USiegeMagicTrajectoryProjectileEffectHandler::Trigger_Fire(this, FireParams);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActorLocation += Velocity * DeltaSeconds;
		Velocity -= FVector(0.0, 0.0, Gravity * DeltaSeconds);

		FSiegeProjectileImpact Params = HitTarget();

		if (Params.bHitTarget)
		{
			FSiegeMagicTrajectoryProjectileImpactParams ImpactParams;
			ImpactParams.Location = ActorLocation;
			ImpactParams.Normal = Params.Normal;
			USiegeMagicTrajectoryProjectileEffectHandler::Trigger_Impact(this, ImpactParams);

			//Replace with object pooling later if necessary
			DestroyActor();
		}
	}
};