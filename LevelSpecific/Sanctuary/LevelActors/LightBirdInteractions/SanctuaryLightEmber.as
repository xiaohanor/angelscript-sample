class ASanctuaryLightEmber : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	FHazeAcceleratedFloat AcceleratedFloat;
	float Target = 0.0;
	float Duration = 1.0;

	FTransform InitialRelativeTransform;

	AActor RootActor;

	ULightBirdChargeComponent ChargeComp;
	bool bIsActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialRelativeTransform = RootComponent.RelativeTransform;

		RootActor = AttachParentActor;

		if (RootActor != nullptr)
		{
			auto LightBirdResponseComp = ULightBirdResponseComponent::Get(RootActor);
			if (LightBirdResponseComp != nullptr)
			{
				LightBirdResponseComp.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
				LightBirdResponseComp.OnUnilluminated.AddUFunction(this, n"HandleUnilluminated");
			}
		
			ChargeComp = ULightBirdChargeComponent::Get(RootActor);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (ChargeComp != nullptr)
		{
			Target = ChargeComp.ChargeFraction;
		}

		AcceleratedFloat.AccelerateTo(Target, Duration, DeltaSeconds);

		FTransform ParentTransform = FTransform::Identity;
		if (Root.AttachParent != nullptr)
			ParentTransform = Root.AttachParent.WorldTransform;
		FTransform ParentTransformZeroScale = ParentTransform;
		ParentTransformZeroScale.Scale3D = FVector::ZeroVector;

		FTransform Bobbing;
		Bobbing.Location = FVector::UpVector * Math::Sin(Time::GameTimeSeconds + InitialRelativeTransform.Location.Size() * 1.0) * 50.0;

		ActorTransform = LerpTransform(ParentTransformZeroScale, Bobbing * InitialRelativeTransform * ParentTransform, AcceleratedFloat.Value);
	
		if (AcceleratedFloat.Value > 0.25 && !bIsActive)
			Activate();

		if (AcceleratedFloat.Value < 0.25 && bIsActive)
			Deactivate();
	}

	UFUNCTION()
	private void HandleIlluminated()
	{
		ChargeComp.ChargeTime = ChargeComp.ChargeDuration;
//		Activate();
	}

	UFUNCTION()
	private void HandleUnilluminated()
	{
//		Deactivate();
	}

	void Activate()
	{
		bIsActive = true;
//		Target = 1.0;
		BP_Activate();
	}

	void Deactivate()
	{
		bIsActive = false;
//		Target = 0.0;
		BP_Deactivate();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activate()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_Deactivate()
	{
	}

	FTransform LerpTransform(FTransform A, FTransform B, float Alpha)
	{
		FTransform LerpedTransform;
		LerpedTransform.Location = Math::Lerp(A.Location, B.Location, Alpha);
		LerpedTransform.Rotation = FQuat::Slerp(A.Rotation, B.Rotation, Alpha);
		LerpedTransform.Scale3D = Math::Lerp(A.Scale3D, B.Scale3D, Alpha);

		return LerpedTransform;
	}

	UFUNCTION(BlueprintPure)
	float GetAlphaValue() property
	{
		return AcceleratedFloat.Value;
	}
}