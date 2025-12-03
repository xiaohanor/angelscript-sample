class AMedallionHydra2DProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent CollisionComp;

	UPROPERTY(DefaultComponent)
	USanctuaryBossSplineMovementComponent SplineMovementComp;

	FVector2D SplineDirection;

	float Speed = 1000.0;

	float LifeTime = 10.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineDirection = SplineMovementComp.ConvertWorldDirectionToSplineDirection(ActorForwardVector);
		CollisionComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FHitResult HitResult = SplineMovementComp.SetSplineLocation(
			SplineMovementComp.GetSplineLocation() + SplineDirection * Speed * DeltaSeconds,
			true);

		if (HitResult.bBlockingHit)
			Explode();

		if (GameTimeSinceCreation >= LifeTime)
			DestroyActor();
	}

	UFUNCTION()
	private void HandleOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                           UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                           const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			Player.DamagePlayerHealth(0.5);
			Explode();
		}
	}

	void Explode()
	{
		BP_Explode();
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Explode(){}
};