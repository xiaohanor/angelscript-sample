class USkylineHighwayCarSignalLightComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	UMaterialInterface Material;

	UPROPERTY(EditAnywhere)
	FLinearColor Color = FLinearColor(1.0, 0.25, 0.0);

	UPROPERTY(EditAnywhere)
	FName SlotName = n"Left";

	UPROPERTY(EditAnywhere)
	FName EmissiveParamater = n"Global_EmissiveTint";

	UPROPERTY(EditAnywhere)
	float Emissive = 20.0;

	UPROPERTY(EditAnywhere)
	float BlinkFreq = 1.5;

	UPROPERTY(EditAnywhere)
	bool bActivateOnStartForward = true;

	UPROPERTY(EditAnywhere)
	bool bActivateOnStartBackward = true;

	UPROPERTY(EditAnywhere)
	bool bHazardWarningLight = false;

	UPROPERTY(EditAnywhere)
	float BlinkDuration = 3.0;

	UPROPERTY(EditInstanceOnly)
	AKineticMovingActor KineticMovingActor;

	float BlinkStopTime = 0.0;

	UPROPERTY(BlueprintReadOnly)
	UMaterialInstanceDynamic MID;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<UPrimitiveComponent> PrimitiveComps;
		Owner.GetComponentsByClass(PrimitiveComps);
		for (auto PrimitiveComp : PrimitiveComps)
		{
			for (auto MaterialSlot : PrimitiveComp.MaterialSlotNames)
			{
				if (MaterialSlot == SlotName)
					MID = PrimitiveComp.CreateDynamicMaterialInstance(PrimitiveComp.GetMaterialIndex(SlotName));
			}
		}

		TArray<USkeletalMeshComponent> SkeletalMeshComps;
		Owner.GetComponentsByClass(SkeletalMeshComps);
		for (auto SkeletalMeshComp : SkeletalMeshComps)
		{
			for (auto MaterialSlot : SkeletalMeshComp.MaterialSlotNames)
			{
				if (MaterialSlot == SlotName)
					MID = SkeletalMeshComp.CreateDynamicMaterialInstance(SkeletalMeshComp.GetMaterialIndex(SlotName));
			}
		}

		if (KineticMovingActor == nullptr)
			KineticMovingActor = Cast<AKineticMovingActor>(Owner.AttachmentRootActor);

		if (KineticMovingActor != nullptr)
		{
			KineticMovingActor.OnStartForward.AddUFunction(this, n"HandleStartForward");
			KineticMovingActor.OnStartBackward.AddUFunction(this, n"HandleStartBackward");
		}

		if (MID == nullptr || KineticMovingActor == nullptr)
			SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Alpha = 0.0;

		if (Time::GameTimeSeconds < BlinkStopTime || bHazardWarningLight)
			Alpha = (Math::Sin(((BlinkStopTime - Time::GameTimeSeconds) * PI * 2.0 * BlinkFreq)) + 1.0) * 0.5;

		MID.SetVectorParameterValue(EmissiveParamater, (Color * 0.5) + Color * Emissive * Alpha);
	}

	UFUNCTION()
	private void HandleStartForward()
	{
		if (bActivateOnStartForward)
		{
			BlinkStopTime = Time::GameTimeSeconds + BlinkDuration;
		}
	}

	UFUNCTION()
	private void HandleStartBackward()
	{
		if (bActivateOnStartBackward)
		{
			BlinkStopTime = Time::GameTimeSeconds + BlinkDuration;
		}
	}
};