class AShootEmUpProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ProjectileRoot;

	float Lifetime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector DeltaMove = ActorForwardVector * 10000.0 * DeltaTime;
		
		SetActorLocation(ActorLocation + DeltaMove);

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnorePlayers();
		Trace.IgnoreActor(this);
		Trace.UseSphereShape(25.0);

		FHitResult HitResult = Trace.QueryTraceSingle(ActorLocation, ActorLocation + DeltaMove);
		if (HitResult.bBlockingHit)
		{
			AShootEmUpEnemy Enemy = Cast<AShootEmUpEnemy>(HitResult.Actor);
			if (Enemy != nullptr)
				Enemy.Destroy();
		}

		Lifetime += DeltaTime;
		if (Lifetime >= 3.0)
			DestroyActor();
	}
}