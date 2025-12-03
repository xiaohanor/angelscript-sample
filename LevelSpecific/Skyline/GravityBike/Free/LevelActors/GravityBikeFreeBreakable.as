class AGravityBikeFreeBreakable : ABreakableActor
{
	UPROPERTY(DefaultComponent)
	UGravityBikeFreeImpactResponseComponent BikeImpactResponseComp;

	UPROPERTY(DefaultComponent)
	UGravityBikeWeaponProjectileResponseComponent BikeWeaponResponseComp;

	UPROPERTY(EditAnywhere)
	float ImpactScatter = 0.1;

	float ForceMax = 10000.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();	
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		BikeImpactResponseComp.OnImpact.AddUFunction(this, n"HandleOnBikeImpact");
		BikeWeaponResponseComp.OnImpact.AddUFunction(this, n"HandleOnBikeWeaponImpact");
	}

	UFUNCTION()
	private void HandleOnBikeImpact(AGravityBikeFree GravityBike, FGravityBikeFreeOnImpactData Data)
	{
		if (Data.Component != BreakableComponent)
			return;

		FVector AdjustedImpactPoint = Data.ImpactPoint - GravityBike.MoveComp.PreviousVelocity.SafeNormal * 10.0;
		FVector AdjustedImpactDirection = GravityBike.MoveComp.PreviousVelocity.SafeNormal;

		Break(AdjustedImpactPoint, 1.0, AdjustedImpactDirection * GravityBike.ActorVelocity.Size() * 1.0, ImpactScatter);
	}

	UFUNCTION()
	private void HandleOnBikeWeaponImpact(FGravityBikeWeaponImpactData ImpactData)
	{
		if (ImpactData.HitComponent != BreakableComponent)
			return;

		FVector AdjustedImpactPoint = ImpactData.ImpactPoint + ImpactData.ImpactNormal * 10.0;
		FVector AdjustedImpactDirection = -ImpactData.ImpactNormal;

		Break(AdjustedImpactPoint, 1.0, AdjustedImpactDirection * 2000.0, ImpactScatter);
	}

	UFUNCTION()
	void Break(FVector Location, float Radius, FVector Force, float Scatter)
	{
//		Debug::DrawDebugLine(Location, Location + Force, FLinearColor::Red, 10.0, 3.0);

		BreakableComponent.BreakAt(Location, Radius, Force, Scatter);

		TArray<UTargetableComponent> Targetables;
		GetComponentsByClass(Targetables);
		for (auto Targetable : Targetables)
			Targetable.Disable(this);
	}
};