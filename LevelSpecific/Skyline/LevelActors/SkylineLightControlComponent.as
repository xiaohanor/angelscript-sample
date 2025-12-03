class USkylineLightControlComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USkylineLightControlComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		DrawWorldString("SkylineLightControlComp", InComponent.Owner.ActorLocation + FVector::UpVector * 10.0, FLinearColor::White, 2.0, bCenterText = true);
	}
}

class USkylineLightControlComponent : UActorComponent
{
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

	ULightComponent LightComp;
	float InitialIntensity = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LightComp = ULightComponent::Get(Owner);
		if (LightComp != nullptr)
		{
			InitialIntensity = LightComp.Intensity;
		}

		auto InterfaceComp = USkylineInterfaceComponent::Get(Owner);
		if (InterfaceComp != nullptr)
		{
			InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
			InterfaceComp.OnDeactivated.AddUFunction(this, n"HandleDeactivated");

			InterfaceComp.OnSnapActivated.AddUFunction(this, n"HandleSnapActivated");
			InterfaceComp.OnSnapDeactivated.AddUFunction(this, n"HandleSnapDeactivated");
		}

		LightAnimation.BindUpdate(this, n"HandleAnimationUpdate");
	
		LightAnimation.SetNewTime(0.0);
		UpdateLight(InitialIntensity * LightAnimation.Value);
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
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

	void UpdateLight(float Intensity)
	{
		LightComp.SetIntensity(Intensity);
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
		float Hej = LightAnimation.Value;
		UpdateLight(InitialIntensity * LightAnimation.Value);
	}
};