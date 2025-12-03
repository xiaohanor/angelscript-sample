class ASplitTraversalTankProjectile : AWorldLinkDoubleActor
{
	UPROPERTY()
	UNiagaraSystem Explosion;

	float Speed = 3000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector NewLocation = ActorLocation + ActorForwardVector * (DeltaSeconds * Speed);

		FHazeTraceSettings Trace;
		Trace.IgnoreActor(this);
		Trace.UseLine();
		Trace.TraceWithChannel(ECollisionChannel::WeaponTracePlayer);

		FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, NewLocation);
		if (Hit.bBlockingHit)
		{
			Niagara::SpawnOneShotNiagaraSystemAtLocation(Explosion, Hit.ImpactPoint);
			DestroyActor();

			ASplitTraversalTankDestructible Destructible = Cast<ASplitTraversalTankDestructible>(Hit.Actor);
			if (Destructible != nullptr)
				Destructible.Destroy();

		}
		else
		{
			ActorLocation = NewLocation;
		}
	}
};

class ASplitTraversalTankDestructible : AWorldLinkDoubleActor
{
	void Destroy()
	{
		DestroyActor();
	}
}