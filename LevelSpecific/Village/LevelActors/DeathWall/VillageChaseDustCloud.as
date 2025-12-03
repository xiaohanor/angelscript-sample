class AVillageChaseDustCloud : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent DustVFX;
	default DustVFX.bAutoActivate = false;

	UFUNCTION()
	void ActivateDustCloud()
	{
		// SetActorTickEnabled(true);
		// DustVFX.Activate(true);
	}

	UFUNCTION()
	void DeactivateDustCloud()
	{
		SetActorTickEnabled(false);
		DustVFX.Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector ViewLocation = Game::Mio.GetViewLocation();
		FRotator ViewRotation = Game::Mio.GetViewRotation();

		FVector DustLocation = (ViewLocation - (ViewRotation.UpVector * 320.0)) + (ViewRotation.ForwardVector * 120.0);
		SetActorLocationAndRotation(DustLocation, ViewRotation);
	}
}