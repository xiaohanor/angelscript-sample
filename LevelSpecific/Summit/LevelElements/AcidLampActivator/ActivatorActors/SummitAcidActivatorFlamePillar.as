class ASummitAcidActivatorFlamePillar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FlameEffect;
	default FlameEffect.SetAutoActivate(false);

	private float ProgressAlpha;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Alpha = (1.0 - ProgressAlpha) * 5.0;
		if (Alpha < 5.0)
			FlameEffect.SetNiagaraVariableFloat("SizeAlpha", Alpha / 5.0);
	}

	void SetAlphaProgress(float CurrentProgress)
	{
		ProgressAlpha = CurrentProgress;
	}

	void TurnOn()
	{
		FlameEffect.Activate();
	}

	void TurnOff()
	{
		FlameEffect.Deactivate();
	}
};