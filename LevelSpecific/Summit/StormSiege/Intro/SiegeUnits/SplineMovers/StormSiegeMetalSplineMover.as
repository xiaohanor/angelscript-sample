class AStormSiegeMetalSplineMover : AStormSiegeMetalFortification
{
	default CapabilityComp.DefaultCapabilities.Add(n"SummitSiegeActiveRangeCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitSiegeShootCapability");

	UPROPERTY(DefaultComponent, Attach = Root)
	USiegeProjectileShootComponent ProjectileShootComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UStormSiegeUnitSplineMovementComponent SplineMoveComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USiegeProjectileShootComponent ShootComp;
	default ShootComp.MinRangeRequired = 5000.0;
	default ShootComp.PredictionDistance = 1000.0;
	default ShootComp.RandomizedOffset = 1.0;

	UPROPERTY(DefaultComponent)
	USiegeHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	USiegeActivationComponent ActivationComp;

	UPROPERTY(EditAnywhere)
	bool bStartDisabled = true;

	default AutoAimComp.bOnlyValidIfAimOriginIsWithinAngle = false;
	default AutoAimComp.AutoAimMaxAngle = 8.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		//Summon
		FStormSiegeSummonEnemyParams Params;
		Params.Location = ActorLocation;
		UStormSiegeSummonEffectHandler::Trigger_SummonEnemy(this, Params);

		OnStormSiegeMetalDestroyed.AddUFunction(this, n"OnStormSiegeMetalDestroyed");
		if (bStartDisabled)
			AddActorDisable(this);
	}

	UFUNCTION()
	private void OnStormSiegeMetalDestroyed(AStormSiegeMetalFortification DestroyedMetal)
	{
		FStormSiegeMetalDestroyedParams Params;
		Params.Location = ActorLocation;
		Params.Scale = 1.0;
		UStormSiegeMetalFortificationEffectHandler::Trigger_OnMetalDestroyed(this, Params);
		HealthComp.bAlive = false;
	}

	UFUNCTION()
	void ActivateSplineMover(ASplineActor SplineActor = nullptr)
	{
		RemoveActorDisable(this);

		if (SplineActor != nullptr)
			SplineMoveComp.SplineComp = SplineActor.Spline;

		SplineMoveComp.ActivateSplineMovement();
	}

	UFUNCTION(CrumbFunction)
	void CrumbDeSummonEnemy()
	{
		FStormSiegeSummonEnemyParams Params;
		Params.Location = ActorLocation;
		UStormSiegeSummonEffectHandler::Trigger_DeSummonEnemy(this, Params);		
		AddActorDisable(this);
	}
}