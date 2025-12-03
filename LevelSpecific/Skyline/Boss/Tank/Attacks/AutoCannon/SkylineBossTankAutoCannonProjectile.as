UCLASS(Abstract)
class ASkylineBossTankAutoCannonProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	float Speed = 15000.0;

	UPROPERTY(EditAnywhere)
	float Damage = 0.1;

	UPROPERTY(EditAnywhere)
	float DamageRadius = 300.0;

	UPROPERTY(EditAnywhere)
	float ProjectileLifeSpan = 3.0;
	float ExpireTime = 0.0;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	AActor Instigator;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ExpireTime = Time::GameTimeSeconds + ProjectileLifeSpan;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > ExpireTime)
			DestroyActor();

		FVector DeltaMove = ActorForwardVector * Speed * DeltaSeconds;
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnoreActor(Instigator);
		FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, ActorLocation + DeltaMove);
		AddActorWorldOffset(DeltaMove);

		if (Hit.bBlockingHit)
		{
			// PrintToScreen("HIT!", 1.0);
			// Niagara::SpawnOneShotNiagaraSystemAtLocation(HitEffect, Hit.Location, ActorRotation);

			auto ResponseComp = USkylineBossTankAutoCannonProjectileResponseComponent::Get(Hit.Actor);
			if (ResponseComp != nullptr)
			{
				ResponseComp.OnProjectileImpact.Broadcast(Hit, ActorForwardVector * Speed);

				if (ResponseComp.bProjectileStopping)
					return;
			}

			FSkylineBossTankAutoCannonProjectileOnImpactEventData EventData;
			EventData.ImpactPoint = Hit.ImpactPoint;
			EventData.Normal = Hit.Normal;
			EventData.TraceStart = ActorLocation;
			EventData.Actor = Cast<AHazeActor>(Hit.Actor);

			USkylineBossTankAutoCannonProjectileEventHandler::Trigger_OnImpact(this, EventData);

			// Audio on weapon user
			USkylineBossTankAutoCannonProjectileEventHandler::Trigger_OnImpact(Cast<AHazeActor>(Instigator), EventData);

//			Debug::DrawDebugSphere(ActorLocation, DamageRadius, 24, FLinearColor::Red, 5.0, 1.0);

			for (auto Player : Game::Players)
			{
				if(!Player.HasControl())
					continue;

				if (ActorLocation.Distance(Player.ActorLocation) < DamageRadius)
				{
					FPlayerDeathDamageParams Params;
//					Params.ImpactDirection = (ActorLocation - Player.ActorLocation).SafeNormal;
					Params.ImpactDirection = DeltaMove.SafeNormal;
//					Debug::DrawDebugLine(Player.ActorLocation, Player.ActorLocation + Params.ImpactDirection * 500.0, FLinearColor::Red, 20.0, 2.0);
					Player.DamagePlayerHealth(Damage, DeathParams = Params, DamageEffect = DamageEffect, DeathEffect = DeathEffect);
				}
			}

			DestroyActor();
		}
	}
};