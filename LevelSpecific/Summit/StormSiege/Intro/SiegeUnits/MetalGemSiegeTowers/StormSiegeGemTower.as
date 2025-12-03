class AStormSiegeGemTower : ASummitSiegeGem
{
	UPROPERTY(DefaultComponent, Attach = Root)
	USiegeProjectileShootComponent ProjectileShootComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USiegeActivationComponent ActivationComp;
	default ActivationComp.Range = 24000.0;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitSiegeActiveRangeCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitSiegeShootCapability");

	UPROPERTY(DefaultComponent)
	USiegeHealthComponent HealthComp;

	UPROPERTY(EditAnywhere)
	bool bStartActive = false;

	UPROPERTY(EditAnywhere)
	ASerpentEventActivator EventActivator;

	FVector StartScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		StartScale = MeshRoot.RelativeScale3D;
		MeshRoot.RelativeScale3D = FVector(0.05);

		OnSummitGemDestroyed.AddUFunction(this, n"OnSummitGemDestroyed");
		EventActivator.OnSerpentEventTriggered.AddUFunction(this, n"OnSerpentEventTriggered");

		if (!bStartActive)
		{
			AddActorDisable(this);
		}
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
		SummonGemEnemy();
	}

	UFUNCTION()
	private void OnSummitGemDestroyed(ASummitSiegeGem CrystalDestroyed)
	{
		HealthComp.bAlive = false;
	}

	UFUNCTION()
	void SummonGemEnemy()
	{
		RemoveActorDisable(this);
		FStormSiegeSummonEnemyParams Params;
		Params.Location = ActorLocation;
		UStormSiegeSummonEffectHandler::Trigger_SummonEnemy(this, Params);
	}
}