class AJetpackCombatZoneRocket : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	UNiagaraSystem ExplodeEffect;

	bool bSelfMoving = false;
	float Lifetime = 0;
	float MaxLifetime = 5;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bSelfMoving)
			return;

		FHitResult Hit;
		SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaSeconds, Hit));
		if(Hit.bBlockingHit)
			Explode();

		Lifetime += DeltaSeconds;
		if(Lifetime > MaxLifetime)
			Explode();
	}

	void Explode()
	{
		for(AHazePlayerCharacter Player: Game::Players)
		{
			if(Player.ActorLocation.IsWithinDist(ActorLocation, 250))
			{
				Player.DamagePlayerHealth(0.2);
				FStumble Stumble;
				Stumble.Duration = 1;
				Stumble.Move = (Player.ActorLocation - ActorLocation).GetSafeNormal() * 500;
				Player.ApplyStumble(Stumble);
			}
		}

		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplodeEffect, ActorLocation);
		Game::Mio.PlayCameraShake(CameraShake, this, 0.5);
		Game::Zoe.PlayCameraShake(CameraShake, this, 0.5);
		DestroyActor();
	}
}