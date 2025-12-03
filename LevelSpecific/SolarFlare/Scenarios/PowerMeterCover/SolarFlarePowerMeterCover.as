class ASolarFlarePowerMeterCover : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent LeftInteractionRoot;

	UPROPERTY(DefaultComponent, Attach = LeftInteractionRoot)
	UStaticMeshComponent LeftInteractionMeshComp;

	UPROPERTY(DefaultComponent, Attach = LeftInteractionRoot)
	UInteractionComponent LeftInteractionComp;
	default LeftInteractionComp.InteractionCapability = n"SolarFlarePowerMeterCoverInteractionCapability";

	UPROPERTY(DefaultComponent, Attach = LeftInteractionRoot)
	USceneComponent LeftInteractionMeterRoot;

	UPROPERTY(DefaultComponent, Attach = LeftInteractionMeterRoot)
	UStaticMeshComponent LeftInteractionMeterMeshComp;

	UPROPERTY(DefaultComponent, Attach = LeftInteractionMeterMeshComp)
	UStaticMeshComponent LeftInteractionMeterInnerMeshComp;

	UPROPERTY(DefaultComponent, Attach = LeftInteractionMeterRoot)
	USceneComponent LeftInteractionMeterGaugeRoot;

	UPROPERTY(DefaultComponent)
	USceneComponent RightInteractionRoot;

	UPROPERTY(DefaultComponent, Attach = RightInteractionRoot)
	UStaticMeshComponent RightInteractionMeshComp;

	UPROPERTY(DefaultComponent, Attach = RightInteractionRoot)
	UInteractionComponent RightInteractionComp;
	default RightInteractionComp.InteractionCapability = n"SolarFlarePowerMeterCoverInteractionCapability";

	UPROPERTY(DefaultComponent, Attach = RightInteractionRoot)
	USceneComponent RightInteractionMeterRoot;

	UPROPERTY(DefaultComponent, Attach = RightInteractionMeterRoot)
	UStaticMeshComponent RightInteractionMeterMeshComp;

	UPROPERTY(DefaultComponent, Attach = RightInteractionMeterMeshComp)
	UStaticMeshComponent RightInteractionMeterInnerMeshComp;

	UPROPERTY(DefaultComponent, Attach = RightInteractionMeterRoot)
	USceneComponent RightInteractionMeterGaugeRoot;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(DefaultComponent)
	USceneComponent CoverRoot;

	UPROPERTY(DefaultComponent, Attach = CoverRoot)
	UStaticMeshComponent CoverMeshComp;

	UPROPERTY(DefaultComponent, Attach = CoverMeshComp)
	USolarFlarePlayerCoverComponent CoverComp;

	UPROPERTY(EditAnywhere)
	AStaticCameraActor StaticCamera;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float RotationSpeed = 90;

	UPROPERTY(EditAnywhere, Category = "Materials")
	UMaterialInstance MeterCompletedMaterial;

	UPROPERTY(EditAnywhere, Category = "Materials")
	UMaterialInstance MeterNotCompletedMaterial;

	TMap<UInteractionComponent, float> ButtonMashProgress;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		float LeftProgress = 0.0;
		ButtonMashProgress.Add(LeftInteractionComp,	 LeftProgress);
		float RightProgress = 0.0;
		ButtonMashProgress.Add(RightInteractionComp, RightProgress);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bool bBothAreInSweetSpot = true;

		float RightProgress = ButtonMashProgress[RightInteractionComp];
		RightInteractionMeterGaugeRoot.RelativeRotation = FRotator(0, 0, 360 * RightProgress);
		if(!MeterIsInSweetSpot(RightProgress))
		{
			RightInteractionMeterInnerMeshComp.SetMaterial(0, MeterNotCompletedMaterial);
			bBothAreInSweetSpot = false;
		}
		else
		{
			RightInteractionMeterInnerMeshComp.SetMaterial(0, MeterCompletedMaterial);
		}

		float LeftProgress = ButtonMashProgress[LeftInteractionComp];
		LeftInteractionMeterGaugeRoot.RelativeRotation = FRotator(0, 0, -360 * LeftProgress);
		if(!MeterIsInSweetSpot(LeftProgress))
		{
			LeftInteractionMeterInnerMeshComp.SetMaterial(0, MeterNotCompletedMaterial);
			bBothAreInSweetSpot = false;
		}
		else
		{
			LeftInteractionMeterInnerMeshComp.SetMaterial(0, MeterCompletedMaterial);
		}

		FRotator CoverRootTargetRotation = bBothAreInSweetSpot ? FRotator(90, 0, 0) : FRotator::ZeroRotator;
		CoverRoot.RelativeRotation = Math::RInterpConstantTo(CoverRoot.RelativeRotation, CoverRootTargetRotation, DeltaSeconds, RotationSpeed);
	}

	bool MeterIsInSweetSpot(float Progress) const
	{
		// It's 0.5 +- 0.125 (the sweet spot is 0.25)
		return (Progress >= 0.375
			&& Progress <= 0.625);
	}

	void SetButtonMashProgress(UInteractionComponent InteractionComp, float NewProgress)
	{
		ButtonMashProgress[InteractionComp] = NewProgress;
	}
};