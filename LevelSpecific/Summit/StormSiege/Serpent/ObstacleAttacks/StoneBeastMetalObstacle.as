class AStoneBeastMetalObstacle : AStormSiegeMetalFortification
{
	default CapabilityComp.DefaultCapabilities.Add(n"StoneBeastObstacleMoveToPlayerCapability");

	// UPROPERTY(DefaultComponent, Attach = Root)
	// USphereComponent SphereComp;
	// default SphereComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	// default SphereComp.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UTargetableOutlineComponent TargetableOutlineComp;

	UPROPERTY(DefaultComponent)
	UStoneBeastObstacleComponent ObstacleComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnStormSiegeMetalDestroyed.AddUFunction(this, n"OnStormSiegeMetalDestroyed");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		MeshRoot.AddLocalRotation(FRotator(0.0, 0.0, 460 * DeltaSeconds));
	}

	UFUNCTION()
	private void OnStormSiegeMetalDestroyed(AStormSiegeMetalFortification DestroyedMetal)
	{
		AddActorDisable(this);
	}
};