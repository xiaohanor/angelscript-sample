struct FSpikeHomingTargetParams
{
	AActor HomingTarget;
	FVector HomingPointOffset;
	float HomingCorrection = 1.0;
}

class AAdultDragonSpikeProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent EffectComp;

	FVector Direction;
	float Speed;
	AActor OwningPlayer;
	AActor OtherPlayer;
	float Radius = 350.0;
	float LifeTime = 15.0;
	AHazePlayerCharacter PlayerInstigator;

	FSpikeHomingTargetParams HomingParams;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (HomingParams.HomingTarget != nullptr)
		{
			FVector DesiredDirection = ((HomingParams.HomingTarget.ActorLocation + HomingParams.HomingPointOffset) - ActorLocation).GetSafeNormal();
			// Direction = Math::VInterpConstantTo(Direction, DesiredDirection, DeltaSeconds, HomingParams.HomingCorrection).GetSafeNormal();
			Direction = DesiredDirection;
		}

		ActorLocation += Direction * Speed * DeltaSeconds;
		ActorRotation = Direction.Rotation();

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
		TraceSettings.UseLine();
		TraceSettings.IgnoreActor(this);
		TraceSettings.IgnoreActor(OwningPlayer);
		TraceSettings.IgnoreActor(OtherPlayer);
		TraceSettings.IgnoreActor(Game::Mio);
		TraceSettings.IgnoreActor(Game::Zoe);

		FHitResult Hit = TraceSettings.QueryTraceSingle(ActorLocation, ActorLocation + ActorForwardVector * Radius);

		if (Hit.bBlockingHit)
		{
			AAdultDragonSpikeProjectile OtherAcidBolt = Cast<AAdultDragonSpikeProjectile>(Hit.Actor);

			if (OtherAcidBolt != nullptr)
				return;
			
			FAdultDragonSpikeImpactParams Params;
			Params.HitPoint = Hit.ImpactPoint;
			Params.ImpactNormal = Hit.ImpactNormal;
			UAdultDragonSpikeProjectileEffectHandler::Trigger_SpikeProjectileImpactExplosion(this, Params);

			UAdultDragonSpikeResponseComponent ResponseComp = UAdultDragonSpikeResponseComponent::Get(Hit.Actor);

			if (ResponseComp != nullptr)
			{
				if(Game::Zoe.HasControl())
					ResponseComp.CrumbActivateSpikeHit();
			}

			DestroyActor();
		}

		LifeTime -= DeltaSeconds;

		if (LifeTime <= 0.0)
			DestroyActor();
	}
}