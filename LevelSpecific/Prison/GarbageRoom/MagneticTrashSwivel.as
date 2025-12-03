UCLASS(Abstract)
class AMagneticTrashSwivel : AMagneticFieldAxisRotateActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent BaseMeshComp;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent FX_GearLoop;
	default FX_GearLoop.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = AxisRotateComp)
	USceneComponent SwivelRoot;

	UPROPERTY(DefaultComponent, Attach = SwivelRoot)
	UStaticMeshComponent SwivelMeshComp;

	UPROPERTY(DefaultComponent, Attach = SwivelRoot)
	UStaticMeshComponent MagneticMeshComp;

	UPROPERTY(DefaultComponent, Attach = SwivelRoot)
	USceneComponent PerchRoot;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 5000.0;

	bool bBurstCooldownActive = false;
	bool bBurstSpamCounterForceActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		MagneticFieldResponseComp.OnBurst.AddUFunction(this, n"MagnetBurst");
	}

	UFUNCTION()
	private void MagnetBurst(FMagneticFieldData Data)
	{
		if (bBurstCooldownActive)
			bBurstSpamCounterForceActive = true;

		bBurstCooldownActive = true;

		Timer::SetTimer(this, n"ResetBurstCooldown", 2.0);
	}

	UFUNCTION()
	private void ResetBurstCooldown()
	{
		bBurstCooldownActive = false;
		bBurstSpamCounterForceActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Super::Tick(DeltaTime);

		if (bBurstSpamCounterForceActive)
			AxisRotateComp.ApplyAngularForce(-0.75);

		if (!MagneticFieldResponseComp.WasMagneticallyAffectedThisFrame())
			AxisRotateComp.ApplyAngularForce(-1.0);
	}
}