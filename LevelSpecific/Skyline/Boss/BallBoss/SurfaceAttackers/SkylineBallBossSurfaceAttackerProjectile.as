class ASkylineBallBossSurfaceAttackerProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotateRoot;

	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	USceneComponent ProjectileRoot;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY()
	float RotationSpeed = 30.0;

	UPROPERTY()
	float Radius = 50.0;

	UPROPERTY()
	float Damage = 0.4;

	UPROPERTY()
	FSoundDefReference ExplosionSoundDef;

	UPROPERTY()
	UNiagaraSystem ExplosionVFX;

	FHazeTimeLike ScaleDownTimeLike;
	default ScaleDownTimeLike.UseLinearCurveZeroToOne();
	default ScaleDownTimeLike.Duration = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ScaleDownTimeLike.BindUpdate(this, n"ScaleDownTimeLikeUpdate");
		ScaleDownTimeLike.BindFinished(this, n"ScaleDownTimeLikeFinished");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		RotateRoot.SetRelativeRotation(FRotator(GameTimeSinceCreation * RotationSpeed + 5.0, 0.0, 0.0));
		
		if (GameTimeSinceCreation > 150.0 / RotationSpeed)
			ScaleDownTimeLike.Play();

		
		for (auto Player : Game::GetPlayers())
		{
			FVector ClosestShapeLocation;
			Player.CapsuleComponent.GetClosestPointOnCollision(ProjectileRoot.WorldLocation, ClosestShapeLocation);
			float DistanceToPlayer = ClosestShapeLocation.Distance(ProjectileRoot.WorldLocation);

			if (DistanceToPlayer <= Radius)
			{
				FVector DeathDir = (Player.ActorCenterLocation - ProjectileRoot.WorldLocation).GetSafeNormal();
				Player.DamagePlayerHealth(Damage, FPlayerDeathDamageParams(DeathDir), DamageEffect, DeathEffect);
				Explode();
			}
		}
	}

	private void Explode()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFX, ProjectileRoot.WorldLocation);
		
		if(ExplosionSoundDef.IsValid())
			ExplosionSoundDef.SpawnSoundDefOneshot(ProjectileRoot, ProjectileRoot.WorldTransform);

		DestroyActor();
	}

	UFUNCTION()
	private void ScaleDownTimeLikeUpdate(float CurrentValue)
	{
		ProjectileRoot.SetRelativeScale3D(FVector(Math::Lerp(1.0, 0.0001, CurrentValue)));
	}

	UFUNCTION()
	private void ScaleDownTimeLikeFinished()
	{
		DestroyActor();
	}
};