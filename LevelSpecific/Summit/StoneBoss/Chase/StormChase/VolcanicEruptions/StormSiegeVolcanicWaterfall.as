class AStormSiegeVolcanicWaterfall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	// UPROPERTY(DefaultComponent, Attach = Root)
	// UNiagaraComponent NiagaraComp;
	// default	NiagaraComp.bAutoActivate = false;
	// default NiagaraComp.SetNiagaraVariableVec3("BoxSize", FVector(0.0, 1500.0, 0.0));
	// default NiagaraComp.SetNiagaraVariableVec3("MaxVel", FVector(500.0, 150, 100.0));
	// default NiagaraComp.SetNiagaraVariableVec3("MinVel", FVector(-500.0, -150, -1400.0));

	UPROPERTY(EditAnywhere)
	APlayerTrigger PlayerTrigger;

	UPROPERTY(EditAnywhere)
	AGiantBreakableObject Breakable;

	UPROPERTY(EditAnywhere)
	bool bStartActive = false;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	bool bHaveTriggered;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");

		if (bStartActive)
			ActivateVolcanoEruption();
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		ActivateVolcanoEruption();
	}

	void ActivateVolcanoEruption()
	{
		if (bHaveTriggered)
			return;

		bHaveTriggered = true;
		BP_TriggerEffect();

		if (Breakable != nullptr)
			Breakable.OnBreakGiantObject(FVector(0.0), 155000.0);

		for (AHazePlayerCharacter PerPlayer : Game::Players)
			PerPlayer.PlayCameraShake(CameraShake, this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_TriggerEffect() {}
};