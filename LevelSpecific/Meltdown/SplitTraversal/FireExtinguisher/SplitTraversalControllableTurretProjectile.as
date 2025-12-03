class ASplitTraversalControllableTurretProjectile : AWorldLinkDoubleActor
{
	UPROPERTY()
	float Speed = 1000.0;

	UPROPERTY()
	float Radius = 50.0;

	UPROPERTY()
	float LifeTime = 5.0;

	AActor IgnoredActor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto Trace = Trace::InitProfile(n"PlayerCharacter");
		Trace.UseSphereShape(Radius);
		Trace.IgnoreActor(IgnoredActor);

		FVector DeltaMovement = ActorForwardVector * Speed * DeltaSeconds;

		const FHitResult Hit = Trace.QueryTraceSingle(FantasyRoot.WorldLocation, FantasyRoot.WorldLocation + DeltaMovement);
		if(Hit.bBlockingHit)
		{
			auto WaterPot = Cast<ASplitTraversalWaterPot>(Hit.Actor);

			if (WaterPot != nullptr)
				WaterPot.Shot();

			AddActorWorldOffset(DeltaMovement);
			Explode();
		}

		AddActorWorldOffset(DeltaMovement);

		if (GameTimeSinceCreation > LifeTime)
			Explode();
	}

	private void Explode()
	{
		BP_Explode();
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Explode(){}
};