class ASkylineAdditiveLightPlane : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	UMaterialInterface Material;

	UPROPERTY(EditAnywhere)
	FName MaterialParameter = n"EmissiveColor";

	UPROPERTY(BlueprintReadOnly)
	UMaterialInstanceDynamic MID;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditAnywhere)
	float ActivationDelay = 0.0;

	UPROPERTY(EditAnywhere)
	float DeactivationDelay = 0.0;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike LightAnimation;
	default LightAnimation.Duration = 1.0;
	default LightAnimation.bCurveUseNormalizedTime = true;
	default LightAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default LightAnimation.Curve.AddDefaultKey(1.0, 1.0);

	FLinearColor InitialIntensity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorHiddenInGame(true);
		SetActorEnableCollision(false);

		MID = Material::CreateDynamicMaterialInstance(this, Material);

		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		InterfaceComp.OnDeactivated.AddUFunction(this, n"HandleDeactivated");

		InterfaceComp.OnSnapActivated.AddUFunction(this, n"HandleSnapActivated");
		InterfaceComp.OnSnapDeactivated.AddUFunction(this, n"HandleSnapDeactivated");

		LightAnimation.BindUpdate(this, n"HandleAnimationUpdate");

		InitialIntensity = MID.GetVectorParameterValue(MaterialParameter);

		LightAnimation.SetNewTime(0.0);
		UpdateLight(InitialIntensity * LightAnimation.Value);
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		SetActorHiddenInGame(false);

		if (ActivationDelay > 0.0)
			Timer::SetTimer(this, n"ActivateLight", ActivationDelay);
		else
			ActivateLight();
	}

	UFUNCTION()
	private void ActivateLight()
	{
		LightAnimation.Play();
	}

	UFUNCTION()
	private void HandleDeactivated(AActor Caller)
	{
		if (DeactivationDelay > 0.0)
			Timer::SetTimer(this, n"DeactivateLight", DeactivationDelay);
		else
			DeactivateLight();
	}

	UFUNCTION()
	private void DeactivateLight()
	{
		LightAnimation.Reverse();
	}

	UFUNCTION()
	private void HandleAnimationUpdate(float CurrentValue)
	{
		UpdateLight(InitialIntensity * CurrentValue);
	}

	void UpdateLight(FLinearColor Color)
	{
		MID.SetVectorParameterValue(MaterialParameter, Color);
	}

	UFUNCTION()
	private void HandleSnapDeactivated(AActor Caller)
	{
		LightAnimation.SetNewTime(0.0);
		UpdateLight(InitialIntensity * LightAnimation.Value);
	}

	UFUNCTION()
	private void HandleSnapActivated(AActor Caller)
	{
		LightAnimation.SetNewTime(LightAnimation.Duration);
		UpdateLight(InitialIntensity * LightAnimation.Value);
	}
};