class ASummitAcidActivatorOuroborosSingleFlameSwitch : ASummitAcidActivatorActor
{
	float TargetRotation;
	float RotationDifference;
	float CurrentRotation;

	default ActivateDuration = 6.0;
	default bWaitForActionCompleted = false;
	default AutoAimDistance = 5015.0;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USummitAcidActivatorAttachComponent Attach1;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USpotLightComponent SpotLight1;

	UPROPERTY()
	FRuntimeFloatCurve Curve;
	default Curve.AddDefaultKey(0.0, 0.25);
	default Curve.AddDefaultKey(0.5, 1.0);
	default Curve.AddDefaultKey(1.0, 0.25);

	UPROPERTY(EditAnywhere)
	float MaxRotateSpeed = 200.0;

	float RotateAmount = 360.0;

	bool bActionCompleted;

	float AlphaTargetMultipler;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnAcidActorActivated.AddUFunction(this, n"OnAcidActorActivated");
		OnAcidActorDeactivated.AddUFunction(this, n"OnAcidActorDeactivated");
	}

	UFUNCTION()
	private void OnAcidActorActivated()
	{
		// AlphaTargetMultipler = 0.5;
		// FlameEffect.Activate();
	}

	UFUNCTION()
	private void OnAcidActorDeactivated()
	{
		AlphaTargetMultipler = 0.0;
		// FlameEffect.Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (TargetRotation == 0.0)
			return;

		float CurveAlpha = 1 - ((TargetRotation - CurrentRotation) / RotationDifference);		
		float Speed = MaxRotateSpeed * Curve.GetFloatValue(CurveAlpha);
		CurrentRotation = Math::FInterpConstantTo(CurrentRotation, TargetRotation - (RotateAmount * AlphaTargetMultipler), DeltaSeconds, Speed);
		MeshRoot.RelativeRotation = FRotator(CurrentRotation, 0, 0);

		if (TargetRotation - CurrentRotation < 0.05 && !bActionCompleted)
		{
			bActionCompleted = true;
			CrumbFireCompletedAction();
		}
	}

	void OnAcidActivatorStarted(AAcidActivator Activator) override
	{
		Super::OnAcidActivatorStarted(Activator);
		TargetRotation += RotateAmount;
		RotationDifference = TargetRotation - CurrentRotation;
		bActionCompleted = false;
		AlphaTargetMultipler = 0.5;
	}

	UFUNCTION(BlueprintPure)
	float GetRotateAlpha() const
	{
		if(RotationDifference == 0)
			return 0;
		return ((TargetRotation - CurrentRotation) / RotationDifference);
	}
};