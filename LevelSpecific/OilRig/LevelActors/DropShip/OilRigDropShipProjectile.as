class AOilRigDropShipProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ProjectileRoot;

	FVector TargetLocation;

	float Speed = 6000.0;

	bool bLaunched = false;

	bool bPlayImpactEffect = false;

	void Launch(FVector TargetLoc, bool bImpactEffect)
	{
		TargetLocation = TargetLoc;
		bPlayImpactEffect = bImpactEffect;

		FVector Dir = (TargetLoc - ActorLocation).GetSafeNormal();
		SetActorRotation(Dir.Rotation());

		bLaunched = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bLaunched)
			return;

		FVector Loc = Math::VInterpConstantTo(ActorLocation, TargetLocation, DeltaTime, Speed);
		SetActorLocation(Loc);
		
		if (Loc.Equals(TargetLocation))
		{
			Impact();
		}
	}

	void Impact()
	{
		BP_Impact(bPlayImpactEffect);
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Impact(bool bImpactEffect) {}
}