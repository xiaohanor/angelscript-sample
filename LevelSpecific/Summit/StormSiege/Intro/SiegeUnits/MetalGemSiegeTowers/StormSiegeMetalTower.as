class AStormSiegeMetalTower : AStormSiegeMetalFortification
{
	default bCanRegrow = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	USiegeProjectileShootComponent ProjectileShootComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USiegeActivationComponent ActivationComp;
	default ActivationComp.Range = 24000.0;

	UPROPERTY(DefaultComponent)
	USiegeHealthComponent HealthComp;

	UPROPERTY(EditAnywhere)
	ASerpentEventActivator EventActivator;

	// UPROPERTY(DefaultComponent)
	// UDisableComponent DisableComp;
	// default DisableComp.bAutoDisable = true;
	// default DisableComp.bAutoActivate = true;
	// default DisableComp.AutoDisableRange = 250000;

	default CapabilityComp.DefaultCapabilities.Add(n"SummitSiegeActiveRangeCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitSiegeShootCapability");

	UPROPERTY(EditAnywhere)
	bool bStartActive = false;

	FVector StartScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		StartScale = MeshRoot.RelativeScale3D;
		MeshRoot.RelativeScale3D = FVector(0.05);

		OnStormSiegeMetalDestroyed.AddUFunction(this, n"OnStormSiegeMetalDestroyed");
		EventActivator.OnSerpentEventTriggered.AddUFunction(this, n"OnSerpentEventTriggered");

		if (!bStartActive)
			AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		MeshRoot.RelativeScale3D = Math::VInterpTo(MeshRoot.RelativeScale3D, StartScale, DeltaSeconds, 1.5);
	}

	UFUNCTION()
	private void OnSerpentEventTriggered()
	{
		SummonMetalEnemy();
	}

	UFUNCTION()
	private void OnStormSiegeMetalDestroyed(AStormSiegeMetalFortification DestroyedMetal)
	{
		HealthComp.bAlive = false;
	}

	UFUNCTION()
	void SummonMetalEnemy()
	{
		RemoveActorDisable(this);
		FStormSiegeSummonEnemyParams Params;
		Params.Location = ActorLocation;
		UStormSiegeSummonEffectHandler::Trigger_SummonEnemy(this, Params);
	}
}