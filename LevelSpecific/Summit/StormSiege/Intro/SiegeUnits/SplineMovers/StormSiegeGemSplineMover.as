class AStormSiegeGemSplineMover : ASummitSiegeGem
{
	default AutoAimCompTail.AutoAimMaxAngle = 8.0;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USiegeProjectileShootComponent ProjectileShootComp;
	default ProjectileShootComp.MinRangeRequired = 5000.0;
	default ProjectileShootComp.PredictionDistance = 1000.0;
	default ProjectileShootComp.RandomizedOffset = 1.0;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitSiegeActiveRangeCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitSiegeShootCapability");

	UPROPERTY(DefaultComponent, ShowOnActor)
	UStormSiegeUnitSplineMovementComponent SplineMoveComp;

	UPROPERTY(DefaultComponent)
	USiegeHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	USiegeActivationComponent ActivationComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnSummitGemDestroyed.AddUFunction(this, n"OnSummitGemDestroyed");

		//Summon
		FStormSiegeSummonEnemyParams Params;
		Params.Location = ActorLocation;
		UStormSiegeSummonEffectHandler::Trigger_SummonEnemy(this, Params);

		// TArray<FString> disablers;
		// GetDisableInstigatorsDebugInformation(disablers);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
	}

	UFUNCTION()
	void ActivateSplineMover(ASplineActor SplineActor = nullptr)
	{
		if (SplineActor != nullptr)
			SplineMoveComp.SplineComp = SplineActor.Spline;

		SplineMoveComp.ActivateSplineMovement();
	}

	UFUNCTION()
	private void OnSummitGemDestroyed(ASummitSiegeGem CrystalDestroyed)
	{
		HealthComp.bAlive = false;
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