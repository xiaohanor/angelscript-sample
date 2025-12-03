class ASanctuaryLightBirdLantern : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LowerRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent UpperRoot;

	UPROPERTY(DefaultComponent)
	UPointLightComponent PointLightComponent;

	UPROPERTY(DefaultComponent)
	UHazeSphereComponent HazeSphereComponent;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComponent;

	UPROPERTY()
	float ActivatedRotationSpeed = 360.0;

	UPROPERTY()
	float BaseRotationSpeed = 20.0;

	UPROPERTY()
	float AccelerationDuration = 1.0;

	FHazeAcceleratedFloat AcceleratedRotationSpeed;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Bird Response")
	bool bListenToParentLightBirdResponse = true;

	FHazeAcceleratedFloat AcceleratedFloat;

	UMaterialInstanceDynamic MID;
	float InitialLightIntensity = 0.0;
	float InitialHazeSphereOpacity = 0.0;

	bool bIsActivated = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		HazeSphereComponent.ConstructionScript_Hack();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bListenToParentLightBirdResponse && AttachParentActor != nullptr)
			LightBirdResponseComponent.AddListenToResponseActor(AttachParentActor);

		LightBirdResponseComponent.OnIlluminated.AddUFunction(this, n"OnIlluminated");
		LightBirdResponseComponent.OnUnilluminated.AddUFunction(this, n"OnUnilluminated");

		InitialLightIntensity = PointLightComponent.Intensity;
		InitialHazeSphereOpacity = HazeSphereComponent.Opacity;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AcceleratedFloat.AccelerateTo((bIsActivated ? 1.0 : 0.0), (bIsActivated ? 1.0 : 1.0), DeltaSeconds);
		PointLightComponent.SetIntensity(InitialLightIntensity * AcceleratedFloat.Value);
		HazeSphereComponent.SetOpacityValue(InitialHazeSphereOpacity * AcceleratedFloat.Value);

		if (bIsActivated)
		{
			AcceleratedRotationSpeed.AccelerateTo(ActivatedRotationSpeed, AccelerationDuration, DeltaSeconds);
		}
		else
		{
			AcceleratedRotationSpeed.AccelerateTo(BaseRotationSpeed, AccelerationDuration, DeltaSeconds);
		}

		LowerRoot.AddRelativeRotation(FRotator(0.0, AcceleratedRotationSpeed.Value * DeltaSeconds, 0.0));
		UpperRoot.AddRelativeRotation(FRotator(0.0, -AcceleratedRotationSpeed.Value * DeltaSeconds, 0.0));
	}

	UFUNCTION()
	private void OnIlluminated()
	{
		bIsActivated = true;
	}

	UFUNCTION()
	private void OnUnilluminated()
	{
		bIsActivated = false;
	}
}