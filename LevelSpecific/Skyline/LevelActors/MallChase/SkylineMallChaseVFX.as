class ASkylineMallChaseVFX : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	TArray<UNiagaraComponent> NiagaraComps;

	UPROPERTY(EditAnywhere)
	bool bPreviewNiagara = false;

	UPROPERTY(EditAnywhere)
	float ActivationDelay = 0.0;

	float ActivationTime = 0.0;
	bool bActivated = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		GetComponentsByClass(NiagaraComps);
		for (auto NiagaraComp : NiagaraComps)
			NiagaraComp.SetAutoActivate(bPreviewNiagara);		
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(NiagaraComps);
		DeactivateNiagaraComps();

		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > ActivationTime)
		{
			ActivateNiagaraComps();
			SetActorTickEnabled(false);
		}
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		SetActorTickEnabled(true);
		ActivationTime = Time::GameTimeSeconds + ActivationDelay;
	}

	void ActivateNiagaraComps()
	{
		for (auto NiagaraComp : NiagaraComps)
			NiagaraComp.Activate(true);
	}

	void DeactivateNiagaraComps()
	{
		for (auto NiagaraComp : NiagaraComps)
			NiagaraComp.Deactivate();
	}
};