class ASkylineBallBossSmallBossTurretProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	float FlyingSpeed = 1000.0;

	UPROPERTY()
	float LifeTime = 3.0;

	UPROPERTY()
	float Radius = 50.0;

	UPROPERTY()
	float Damage = 0.4;

	UPROPERTY()
	UNiagaraSystem ExplosionVFX;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorLocalOffset(FVector::ForwardVector * FlyingSpeed * DeltaSeconds);

		if (GetGameTimeSinceCreation() > LifeTime)
			DestroyActor();

		for (auto Player : Game::GetPlayers())
		{
			FVector ClosestShapeLocation;

			Player.CapsuleComponent.GetClosestPointOnCollision(ActorLocation, ClosestShapeLocation);

			float DistanceToPlayer = ClosestShapeLocation.Distance(ActorLocation);

			if (DistanceToPlayer < Radius)
				Explode(Player);
		}
	}

	private void Explode(AHazePlayerCharacter Player)
	{
		Player.DamagePlayerHealth(Damage);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFX, ActorLocation);
		DestroyActor();
	}
};