class AMoonMarketBouncyBall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USphereComponent Sphere;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedPositionComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"MoonMarketBouncyBallMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"MoonMarketBouncyBallCapability");

	UPROPERTY()
	UNiagaraSystem DespawnPoof;

	AHazePlayerCharacter OwningPlayer;

	UFUNCTION(CrumbFunction)
	void CrumbBounce(AActor HitActor)
	{
		FMoonMarketBouncyBallHitEventParams Params;
		Params.HitActor = HitActor;
		UMoonMarketBouncyBallEventHandler::Trigger_OnHit(this, Params);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FHazeTraceSettings ImpactTraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		ImpactTraceSettings.UseSphereShape(Sphere.SphereRadius);
		ImpactTraceSettings.IgnoreActor(this);	
		ImpactTraceSettings.IgnoreActor(OwningPlayer);	
		FOverlapResultArray SphereHits = ImpactTraceSettings.QueryOverlaps(ActorLocation);

		for(auto Hit : SphereHits)
		{
			auto ResponseComp = UMoonMarketBouncyBallResponseComponent::Get(Hit.Actor);
			if(ResponseComp == nullptr)
				continue;

			FMoonMarketBouncyBallHitData HitData;
			HitData.ImpactPoint = Hit.Actor.ActorLocation;
			HitData.ImpactNormal = (ActorLocation - Hit.Actor.ActorLocation).GetSafeNormal();
			HitData.ImpactVelocity = ActorVelocity;
			HitData.InstigatingPlayer = OwningPlayer;
			HitData.Ball = this;
			ResponseComp.Hit(HitData);
		}
	}
};