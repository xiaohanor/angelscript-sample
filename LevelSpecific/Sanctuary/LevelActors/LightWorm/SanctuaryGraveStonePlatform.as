class ASanctuaryGraveStonePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent VFXComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactCallbackComp;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	bool bImpacted = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"OnGroundImpact");
		RotateComp.OnMaxConstraintHit.AddUFunction(this, n"HandleOnContrainHit");
		ForceComp.AddDisabler(this);
	}

	UFUNCTION()
	private void HandleOnContrainHit(float Strength)
	{
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
	}

	UFUNCTION()
	private void OnGroundImpact(AHazePlayerCharacter Player)
	{
		if (bImpacted)
			return;

		bImpacted = true;

		VFXComp.Activate();
		
		ForceComp.RemoveDisabler(this);
	}
};