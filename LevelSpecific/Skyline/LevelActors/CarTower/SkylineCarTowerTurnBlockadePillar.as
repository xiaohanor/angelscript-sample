event void FSkylinPillarFallingSignature();
class ASkylineCarTowerTurnBlockadePillar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent PillarPivot;

	UPROPERTY(DefaultComponent, Attach = PillarPivot)
	UStaticMeshComponent WholePillar;

	UPROPERTY(DefaultComponent, Attach = PillarPivot)
	UStaticMeshComponent BrokenPillar;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterFaceComp;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike TimeLike;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent)
	USceneComponent ExplosionLoc;

	UPROPERTY(EditAnywhere)
	float FallAngle = 45.0;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ExplosionVFX;

	UPROPERTY()
	FSkylinPillarFallingSignature OnPillarFallen;

	UPROPERTY(DefaultComponent, Attach = PillarPivot)
	UNiagaraComponent SmokeVFX;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BrokenPillar.SetHiddenInGame(true);

		InterFaceComp.OnActivated.AddUFunction(this, n"HandleOnActivaed");
		TimeLike.BindUpdate(this, n"HandleOnTimeLikeUpdate");
		
	}

	UFUNCTION()
	private void HandleOnTimeLikeUpdate(float CurrentValue)
	{
		PillarPivot.SetRelativeRotation(FRotator(FallAngle * CurrentValue, 0.0, 0.0));
	}

	UFUNCTION()
	private void HandleOnActivaed(AActor Caller)
	{
		TimeLike.Play();
		SmokeVFX.Activate();
		Niagara::SpawnOneShotNiagaraSystemAttached(ExplosionVFX, ExplosionLoc);
		BrokenPillar.SetHiddenInGame(false);
		WholePillar.SetHiddenInGame(true);
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		OnPillarFallen.Broadcast();
		Timer::SetTimer(this, n"TurnOffSmoke", 5.0);
	}

	UFUNCTION()
	private void TurnOffSmoke()
	{
		SmokeVFX.Deactivate();
	}
};