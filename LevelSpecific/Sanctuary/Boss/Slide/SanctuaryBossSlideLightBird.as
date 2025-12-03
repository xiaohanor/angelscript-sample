class ASanctuaryBossSlideLightBird : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	AActor ActorWithSpline;
	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent)
	UPointLightComponent PointLight;

	UPROPERTY(DefaultComponent)
	UHazeSphereComponent HazeSphere;

	UPROPERTY(EditAnywhere)
	float DistanceOffset = 600.0;

	UPROPERTY(EditAnywhere)
	FVector FocusTargetOffset = FVector(0.0, 0.0, 0.0);

	UPROPERTY(EditAnywhere)
	bool bIsDarkfish = false;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueComp;
	UPROPERTY()
	FRuntimeFloatCurve FloatCurve;

	//Settings
	UPROPERTY()
	const float StartAttenuation = 1000.0;
	UPROPERTY()
	const float EndAttenuation = 2000.0;
	UPROPERTY()
	const float StartOpacity = 0.02;
	UPROPERTY()
	const float EndOpacity = 0.03;
	UPROPERTY()
	const float StartHazeSphereScale = 2.0;
	UPROPERTY()
	const float EndHazeSphereScale = 2.0; 

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		HazeSphere.SetOpacityValue(StartOpacity);
		HazeSphere.SetRelativeScale3D(FVector(StartHazeSphereScale));
		PointLight.SetAttenuationRadius(StartAttenuation);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (ActorWithSpline != nullptr)
			Spline = UHazeSplineComponent::Get(ActorWithSpline);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FSplinePosition TargetPosition;
		for (auto Player : Game::Players)
		{
			auto PlayerSplinePosition = Spline.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);
			if (!TargetPosition.IsValid() || TargetPosition.CanReach(PlayerSplinePosition, ESplineMovementPolarity::Positive))
				TargetPosition = PlayerSplinePosition;
		}

		TargetPosition.Move(DistanceOffset);

		FTransform Transform = TargetPosition.WorldTransform;
		Transform.Location = Transform.Location + Transform.TransformVectorNoScale(FocusTargetOffset);

		SetActorLocationAndRotation(
			Transform.Location,
			Transform.Rotation
		);
	}

	UFUNCTION()
	void IncreaseLight()
	{
		ActionQueComp.Duration(3.0, this, n"HandleLightUpdate");
		BP_Illuminated();
	}

	UFUNCTION()
	private void HandleLightUpdate(float Alpha)
	{
		float AlphaValue = FloatCurve.GetFloatValue(Alpha);
		float LightStrength =  Math::Lerp(StartAttenuation, EndAttenuation, AlphaValue);
		float OpacityStrength = Math::Lerp(StartOpacity, EndOpacity, AlphaValue);
		float HazeSphereScale = Math::Lerp(StartHazeSphereScale, EndHazeSphereScale, AlphaValue);

		HazeSphere.SetOpacityValue(OpacityStrength);
		HazeSphere.SetRelativeScale3D(FVector(HazeSphereScale));
		PointLight.SetAttenuationRadius(LightStrength);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Illuminated(){}
};