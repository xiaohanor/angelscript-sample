class AMeltdownBossPhaseThreeAcidPuddle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent AcidTrail;

	float CurrentLifeTime = 0.0;
	float LifeTime = 3.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentLifeTime += DeltaSeconds;
		if (CurrentLifeTime >= LifeTime)
			KillAcid();
			
	}

	UFUNCTION(BlueprintEvent)
	void KillAcid()
	{

	}
};