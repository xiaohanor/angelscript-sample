class ASkylinePowerCable : APropLine
{
	UPROPERTY(DefaultComponent)
	USkylineMaterialInstanceComponent SkylineMaterialInstanceComp;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditAnywhere)
	FName EmissiveParameter = n"EmissiveTint";

	UPROPERTY(EditAnywhere)
	FName PulseSpeedParameter = n"pulseEmissive_Speed";

	UPROPERTY(EditAnywhere)
	FLinearColor ActivatedColor = FLinearColor(0.0, 1.0, 0.5) * 10.0;

	UPROPERTY(EditAnywhere)
	FLinearColor DeactivatedColor = FLinearColor::Black;

	UPROPERTY(EditAnywhere)
	float ActivatedSpeed = 2.0;

	UPROPERTY(EditAnywhere)
	float DeactivatedSpeed = 0.5;

	UPROPERTY(EditAnywhere)
	bool bStartActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		InterfaceComp.OnDeactivated.AddUFunction(this, n"HandleDeactivated");

		if (bStartActivated)
			Activate();
		else
			Deactivate();
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		Activate();
	}

	UFUNCTION()
	private void HandleDeactivated(AActor Caller)
	{
		Deactivate();
	}

	UFUNCTION()
	void Activate()
	{
		SkylineMaterialInstanceComp.SetVectorParameterValue(EmissiveParameter, ActivatedColor);
		SkylineMaterialInstanceComp.SetScalarParameterValue(PulseSpeedParameter, ActivatedSpeed);
	}

	UFUNCTION()
	void Deactivate()
	{
		SkylineMaterialInstanceComp.SetVectorParameterValue(EmissiveParameter, DeactivatedColor);
		SkylineMaterialInstanceComp.SetScalarParameterValue(PulseSpeedParameter, DeactivatedSpeed);
	}
};