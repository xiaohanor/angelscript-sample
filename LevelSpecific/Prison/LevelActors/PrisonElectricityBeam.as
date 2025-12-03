class APrisonElectricityBeam : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ElectricityRoot;

	UPROPERTY(DefaultComponent, Attach = ElectricityRoot)
	UNiagaraComponent ElectricityComp;

	UPROPERTY(DefaultComponent, Attach = ElectricityRoot)
	UBoxComponent KillTrigger;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(EditInstanceOnly)
	bool bAlwaysActive = false;

	UPROPERTY(EditInstanceOnly)
	float ActiveDelay = 0.0;

	UPROPERTY(EditInstanceOnly)
	float ActiveDuration = 2.0;

	UPROPERTY(EditInstanceOnly)
	float InactiveDuration = 2.0;

	UPROPERTY(EditInstanceOnly)
	float BeamLength = 500.0;

	bool bActive = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		ElectricityComp.SetVectorParameter(n"BeamEnd", FVector(BeamLength, 0.0, 0.0));
		KillTrigger.SetRelativeLocation(FVector(BeamLength/2.0, 0.0, 0.0));
		KillTrigger.SetBoxExtent(FVector(BeamLength/2.0, 25.0, 25.0));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		KillTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterKillTrigger");

		ElectricityComp.DeactivateImmediate();

		if (ActiveDelay == 0.0)
			Activate();
		else
			Timer::SetTimer(this, n"Activate", ActiveDelay);
	}

	UFUNCTION(NotBlueprintCallable)
	void Activate()
	{
		bActive = true;
		ElectricityComp.Activate(true);

		if (!bAlwaysActive)
			Timer::SetTimer(this, n"Deactivate", ActiveDuration);
	}

	UFUNCTION(NotBlueprintCallable)
	void Deactivate()
	{
		bActive = false;
		ElectricityComp.Deactivate();

		Timer::SetTimer(this, n"Activate", InactiveDuration);
	}

	UFUNCTION()
	private void EnterKillTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (!bActive)
			return;

		Player.KillPlayer(DeathEffect = DeathEffect);
	}
}