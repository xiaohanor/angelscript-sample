UCLASS(Abstract)
class AGarbageRoomPressurePlateGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent GateRoot;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CamShakeFFComp;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike ActivateTimeLike;

	bool bActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActivateTimeLike.BindUpdate(this, n"UpdateActivate");
		ActivateTimeLike.BindFinished(this, n"FinishActivate");
	}

	UFUNCTION()
	void OpenGate()
	{
		if (bActivated)
			return;

		bActivated = true;
		ActivateTimeLike.PlayFromStart();

		UGarbageRoomPressurePlateGateEffectEventHandler::Trigger_StartOpening(this);
	}

	UFUNCTION()
	private void UpdateActivate(float CurValue)
	{
		float Pitch = Math::Lerp(0.0, -90.0, CurValue);
		GateRoot.SetRelativeRotation(FRotator(Pitch, 0.0, 0.0));
	}

	UFUNCTION()
	private void FinishActivate()
	{
		CamShakeFFComp.ActivateCameraShakeAndForceFeedback();
	}
}