class ASummitFireSection : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FireComp;
	default FireComp.SetAutoActivate(false);

	float Duration = 4.0;
	float TurnOffTime;
	bool bIsBurning;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > TurnOffTime)
		{
			FireComp.Deactivate();
			SetActorTickEnabled(false);
		}
	}

	void ActivateFire()
	{
		TurnOffTime = Time::GameTimeSeconds + Duration;
		FireComp.Activate();
		SetActorTickEnabled(true);
	}
}