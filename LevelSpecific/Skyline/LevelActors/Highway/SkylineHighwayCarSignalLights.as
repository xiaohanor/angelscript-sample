class ASkylineHighwayCarSignalLights : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	UMaterialInterface Material;

	UPROPERTY(EditAnywhere)
	FLinearColor Color = FLinearColor::Yellow;

	UPROPERTY(EditAnywhere)
	FName EmissiveParamater = n"EmissiveColor";

	UPROPERTY(EditAnywhere)
	float Emissive = 50.0;

	UPROPERTY(EditAnywhere)
	float BlinkFreq = 10.0;

	UPROPERTY(EditAnywhere)
	bool bActivateOnStartForward = true;

	UPROPERTY(EditAnywhere)
	bool bActivateOnStartBackward = true;

	UPROPERTY(EditAnywhere)
	bool bHazardWarningLight = false;

	UPROPERTY(EditAnywhere)
	float BlinkDuration = 5.0;

	UPROPERTY(EditInstanceOnly)
	AKineticMovingActor KineticMovingActor;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;
	default DisableComp.bActorIsVisualOnly = true;

	float BlinkStopTime = 0.0;

	float Time = 0.0;

	UPROPERTY(BlueprintReadOnly)
	UMaterialInstanceDynamic MID;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (KineticMovingActor == nullptr)
			KineticMovingActor = Cast<AKineticMovingActor>(AttachmentRootActor);

		if (KineticMovingActor != nullptr)
		{
			KineticMovingActor.OnStartForward.AddUFunction(this, n"HandleStartForward");
			KineticMovingActor.OnStartBackward.AddUFunction(this, n"HandleStartBackward");
		}
	
		MID = Material::CreateDynamicMaterialInstance(this, Material);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Alpha = 0.0;

		if (Time < BlinkStopTime || bHazardWarningLight)
			Alpha = (Math::Sin(Time * BlinkFreq) + 1.0) * 0.5;

		MID.SetVectorParameterValue(EmissiveParamater, (Color * 0.02) + Color * Emissive * Alpha);

		Time += DeltaSeconds;
	}

	UFUNCTION()
	private void HandleStartForward()
	{
		if (bActivateOnStartForward)
		{
			Time = 0.0;
			BlinkStopTime = BlinkDuration;
		}
	}

	UFUNCTION()
	private void HandleStartBackward()
	{
		if (bActivateOnStartBackward)
		{
			Time = 0.0;
			BlinkStopTime = BlinkDuration;
		}
	}
};