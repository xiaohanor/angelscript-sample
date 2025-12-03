event void FOnStormSiegeMetalGemDestroyed(AStormSiegeMetalGemSplineMover MetalGem);

class AStormSiegeMetalGemSplineMover : AHazeActor
{
	UPROPERTY()
	FOnStormSiegeMetalGemDestroyed OnStormSiegeMetalGemDestroyed;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MetalRoot;

	UPROPERTY(DefaultComponent, Attach = MetalRoot)
	UCapsuleComponent MetalCollision;
	default MetalCollision.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default MetalCollision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default MetalCollision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);
	default MetalCollision.SetCollisionResponseToChannel(ECollisionChannel::PlayerAiming, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = MetalRoot)
	UStaticMeshComponent MetalMesh;
	default MetalMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent GemRoot;

	UPROPERTY(DefaultComponent, Attach = GemRoot)
	UCapsuleComponent GemCollision;
	default GemCollision.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default GemCollision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default GemCollision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);
	default GemCollision.SetCollisionResponseToChannel(ECollisionChannel::PlayerAiming, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = GemRoot)
	UStaticMeshComponent GemMesh;
	default GemMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UAdultDragonAcidAutoAimComponent AcidAutoAim;
	default AcidAutoAim.MaximumDistance = 50000.0;

	UPROPERTY(DefaultComponent)
	UAdultDragonSpikeAutoAimComponent SpikeAutoAim;
	default SpikeAutoAim.MaximumDistance = 50000.0;

	UPROPERTY(DefaultComponent, Attach = GemRoot)
	USiegeMagicBeamComponent BeamComp;
	default BeamComp.MinRangeRequired = 5000.0;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitSiegeActiveRangeCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitSiegeBeamCapability");

	UPROPERTY(DefaultComponent)
	USiegeHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	USiegeActivationComponent ActivationComp;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponse;

	UPROPERTY(DefaultComponent)
	UAdultDragonTailSmashModeResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UStormSiegeUnitSplineMovementComponent SplineMoveComp;

	int CurrentAcidHits;
	int CurrentSpikeHits;
	int MaxAcidHits = 2;
	int MaxSpikeHits = 2;

	bool bGemExposed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcidResponse.OnAcidHit.AddUFunction(this, n"OnAcidHit");
		ResponseComp.OnHitBySmashMode.AddUFunction(this, n"OnHitBySmashMode");
	}

	UFUNCTION()
	void ActivateSplineMover(ASplineActor SplineActor = nullptr)
	{
		if (SplineActor != nullptr)
			SplineMoveComp.SplineComp = SplineActor.Spline;

		SplineMoveComp.ActivateSplineMovement();
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		if (bGemExposed)
			return;

		CurrentAcidHits++;

		if (CurrentAcidHits < MaxAcidHits)
			return;

		bGemExposed = true;
		MetalMesh.SetHiddenInGame(true);
		MetalCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		FStormSiegeMetalGemAcidHitParams Params;
		Params.Location = ActorLocation;
		UStormSiegeMetalGemEffectHandler::Trigger_OnMetalHit(this, Params);

		AcidAutoAim.Disable(this);
		SpikeAutoAim.Enable(this);
		HealthComp.bAlive = false;
	}

	UFUNCTION()
	private void OnHitBySmashMode(FTailSmashModeHitParams Params)
	{
		if (!bGemExposed)
			return;

		CurrentSpikeHits++;

		if (CurrentSpikeHits < MaxSpikeHits)
			return;

		GemMesh.SetHiddenInGame(true);
		GemCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		FStormSiegeMetalGemSpikeHitParams EffectParams;
		EffectParams.Location = ActorLocation;
		UStormSiegeMetalGemEffectHandler::Trigger_OnGemHit(this, EffectParams);

		FOnSummitGemDestroyedParams DestroyParams;
		DestroyParams.Location = ActorLocation;
		DestroyParams.Rotation = ActorRotation;
		DestroyParams.Scale = 2.0;
		USummitGemDestructionEffectHandler::Trigger_DestroyRegularGem(this, DestroyParams);

		SpikeAutoAim.Disable(this);
		AddActorDisable(this);
		OnStormSiegeMetalGemDestroyed.Broadcast(this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbDesummonGemMetal()
	{
		GemMesh.SetHiddenInGame(true);
		MetalMesh.SetHiddenInGame(true);
		GemCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		MetalCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		FStormSiegeSummonEnemyParams Params;
		Params.Location = ActorLocation;
		UStormSiegeSummonEffectHandler::Trigger_DeSummonEnemy(this, Params);		

		SpikeAutoAim.Disable(this);
		AcidAutoAim.Disable(this);
		AddActorDisable(this);
		OnStormSiegeMetalGemDestroyed.Broadcast(this);		
	}
}