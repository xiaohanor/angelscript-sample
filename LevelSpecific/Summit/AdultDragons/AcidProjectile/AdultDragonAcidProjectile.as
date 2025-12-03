struct FAcidHomingTargetParams
{
	AActor HomingTarget;
	FVector HomingPointOffset;
	float HomingCorrection = 0.5;
}

class AAdultDragonAcidProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent TrailEffectComp;

	FVector Direction;
	float Speed;
	AActor OwningPlayer;
	AActor OtherPlayer;
	// AActor TargetActor;
	float Radius = 350.0;
	float LifeTime = 10.0;
	AHazePlayerCharacter PlayerInstigator;

	FAcidHomingTargetParams HomingParams;

	FVector PreviousLocation;

	TArray<AActor> ActorsToIgnore;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PreviousLocation = ActorLocation;
		SetActorRotation(FRotator::MakeFromXZ(Direction, FVector::UpVector));
		ActorsToIgnore.Add(this);

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
		TraceSettings.UseSphereShape(100);
		TraceSettings.IgnorePlayers();
		TraceSettings.IgnoreActors(ActorsToIgnore);
		FOverlapResultArray Overlaps = TraceSettings.QueryOverlaps(ActorLocation);
		for (auto Overlap : Overlaps)
		{
			if (Overlap.bBlockingHit)
			{
				auto DissolveSphere = Cast<AAcidDissolveSphere>(Overlap.Actor);
				if (DissolveSphere != nullptr)
				{
					ActorsToIgnore.Add(DissolveSphere);
					ActorsToIgnore.Add(DissolveSphere.ActorToMaskCollision);
				}
			}
		}
	}

	UFUNCTION()
	void HandleOverlapAcidDissolveSphere(AAcidDissolveSphere DissolveSphere)
	{
		ActorsToIgnore.Add(DissolveSphere.ActorToMaskCollision);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		LifeTime -= DeltaSeconds;
		if (LifeTime <= 0.0)
			DestroyActor();

		PreviousLocation = ActorLocation;
		ActorLocation += Direction * Speed * DeltaSeconds;

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
		TraceSettings.UseLine();
		TraceSettings.IgnorePlayers();
		TraceSettings.IgnoreActors(ActorsToIgnore);

		FHitResult Hit = TraceSettings.QueryTraceSingle(PreviousLocation, ActorLocation + Direction * AdultAcidDragon::AcidProjectileRadius);

		if (Hit.bBlockingHit)
		{
			AAdultDragonAcidProjectile OtherAcidBolt = Cast<AAdultDragonAcidProjectile>(Hit.Actor);

			if (OtherAcidBolt != nullptr)
				return;

			auto DissolveSphere = Cast<AAcidDissolveSphere>(Hit.Actor);
			if (DissolveSphere != nullptr)
			{
				ActorsToIgnore.Add(DissolveSphere);
				return;
			}

			FAdultDragonAcidBoltImpactParams Params;
			Params.HitPoint = Hit.ImpactPoint;
			Params.ImpactNormal = Hit.ImpactNormal;
			UAdultDragonAcidProjectileEffectHandler::Trigger_AcidProjectileImpactExplosion(this, Params);

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

			DestroyActor();
		}
	}
}