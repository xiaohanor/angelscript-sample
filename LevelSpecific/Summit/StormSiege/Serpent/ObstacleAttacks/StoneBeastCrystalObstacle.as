class AStoneBeastCrystalObstacle : ASummitSiegeGem
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UAdultDragonTailSmashAutoAimComponent AutoAim;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereComp;
	default SphereComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default SphereComp.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"StoneBeastObstacleMoveToPlayerCapability");

	UPROPERTY(DefaultComponent)
	UTargetableOutlineComponent TargetableOutlineComp;

	UPROPERTY(DefaultComponent)
	UStoneBeastObstacleComponent ObstacleComp;

	UPROPERTY()
	UNiagaraSystem Destruction;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		MeshRoot.AddLocalRotation(FRotator(0.0, 0.0, 360 * DeltaSeconds));
	}
};