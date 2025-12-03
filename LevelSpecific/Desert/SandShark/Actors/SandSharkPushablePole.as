event void FSandSharkPushablePoleFallenSignature();

class ASandSharkPushablePole : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsAxisRotateComponent Root;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CamShakeFFComp;

	UPROPERTY(DefaultComponent)
	USceneComponent ImpactLocationComp;

	UPROPERTY()
	FSandSharkPushablePoleFallenSignature OnFallen;

	UPROPERTY(EditInstanceOnly)
	ASandShark SharkToAttract;

	UPROPERTY(EditInstanceOnly)
	ASandSharkSpline OverrideSpline;

	UPROPERTY(EditAnywhere)
	float DistractDuration = 1.0;
	

	bool bFall = false;
	bool bFallen = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Root.OnMaxConstraintHit.AddUFunction(this, n"Fallen");
	}

	UFUNCTION()
	private void Fallen(float Strength)
	{
		if (bFallen)
			return;

		bFallen = true;
		OnFallen.Broadcast();

		CamShakeFFComp.ActivateCameraShakeAndForceFeedback();

		USandSharkPushablePoleEffectEventHandler::Trigger_Impact(this);
		SharkToAttract.QueueDistractionParams(FSandSharkThumperDistractionParams(OverrideSpline, DistractDuration));

	}

	UFUNCTION()
	void Fall()
	{
		if (bFall)
			return;

		bFall = true;

		USandSharkPushablePoleEffectEventHandler::Trigger_StartFalling(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bFall)
			return;

		Root.ApplyAngularForce(5);
	}

	UFUNCTION()
	void SetCompleted()
	{
		bFall = true;
		OnFallen.Broadcast();
	}
};

class USandSharkPushablePoleEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void StartFalling() {}
	UFUNCTION(BlueprintEvent)
	void Impact() {}
}