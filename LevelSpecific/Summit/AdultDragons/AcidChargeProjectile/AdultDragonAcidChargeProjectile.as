UCLASS(Abstract)
class AAdultDragonAcidChargeProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent EffectComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	FVector Direction;
	float Speed;
	// AActor TargetActor;

	float CurrentRadius = 300;
	float LifeTime = 10.0;
	AHazePlayerCharacter PlayerInstigator;

	FAcidHomingTargetParams HomingParams;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector PrevLocation = ActorLocation;
		ActorLocation += Direction * Speed * DeltaSeconds;

		auto TraceSettings = GetTraceSettings();
		FHitResult Hit = TraceSettings.QueryTraceSingle(PrevLocation, ActorLocation + Direction * CurrentRadius);

		if (Hit.bBlockingHit)
		{
			FAdultDragonAcidChargeProjectileImpactParams Params;
			Params.HitPoint = Hit.ImpactPoint;
			Params.ImpactNormal = Hit.ImpactNormal;
			UAdultDragonAcidChargeProjectileEffectHandler::Trigger_AcidChargeProjectileImpact(this, Params);

			UAcidResponseComponent ResponseComp = UAcidResponseComponent::Get(Hit.Actor);

			if (ResponseComp != nullptr)
			{
				FAcidHit AcidParams;
				AcidParams.ImpactLocation = Hit.ImpactPoint;
				AcidParams.ImpactNormal = Hit.ImpactNormal;
				AcidParams.HitComponent = Hit.Component;
				AcidParams.PlayerInstigator = PlayerInstigator;
				if (Game::Mio.HasControl())
					ResponseComp.CrumbActivateAcidHit(AcidParams);
			}

 			DestroyProjectile();
		}

		LifeTime -= DeltaSeconds;

		if (LifeTime <= 0.0)
		{
			DestroyProjectile();
		}
	}

	void DestroyProjectile()
	{
		EffectComp.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		//Add pooling logic later
		EffectComp.Deactivate();
		SetActorTickEnabled(false);
		Timer::SetTimer(this, n"CleanupActor", 1);
		//DestroyActor();
	}

	UFUNCTION()
	private void CleanupActor()
	{
		DestroyActor();
	}

	FHazeTraceSettings GetTraceSettings() const
	{
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
		TraceSettings.UseSphereShape(CurrentRadius);
		TraceSettings.IgnoreActor(this);
		TraceSettings.IgnoreActor(Game::Mio);
		TraceSettings.IgnoreActor(Game::Zoe);
		return TraceSettings;
	}
}