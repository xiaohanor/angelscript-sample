class UFloatingActorComponent : UActorComponent
{
	bool bIsGrabbed = false;
	float Alpha = 0.0;
	float LerpSpeed = 1.0;

	FTransform RelativeTransform;
	FTransform AdditionalRelativeTransform;

	UPROPERTY(EditAnywhere)
	TArray<FSanctuaryFloatingData> FloatingData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto ResponseComp = UDarkPortalResponseComponent::Get(Owner);
		if (ResponseComp != nullptr)
		{
			ResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
			ResponseComp.OnReleased.AddUFunction(this, n"HandleReleased");
		}
	}

	UFUNCTION()
	private void HandleGrabbed(ADarkPortalActor PortalActor, UDarkPortalTargetComponent TargetComponenet)
	{
		bIsGrabbed = true;
	}

	UFUNCTION()
	private void HandleReleased(ADarkPortalActor PortalActor, UDarkPortalTargetComponent TargetComponenet)
	{
		bIsGrabbed = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsGrabbed)
			Alpha -= DeltaSeconds * LerpSpeed;
		else
			Alpha += DeltaSeconds * LerpSpeed;

		Alpha = Math::Clamp(Alpha, 0.0, 1.0);

		RelativeTransform = AdditionalRelativeTransform.Inverse() * Owner.RootComponent.RelativeTransform;

		FTransform NewRelativeTransform;

		for (auto Data : FloatingData)
		{	
			if (Data.bRotation)
				if (Data.bConstantRotation)
					NewRelativeTransform.Rotation = NewRelativeTransform.Rotation * FQuat(Data.Axis.GetSafeNormal(), Data.Rate * Time::GameTimeSeconds);
				else
					NewRelativeTransform.Rotation = NewRelativeTransform.Rotation * FQuat(Data.Axis.GetSafeNormal(), Math::Sin((Time::GameTimeSeconds * Data.Rate) + Data.Offset) * Data.Axis.Size());
			else
				NewRelativeTransform.Location = NewRelativeTransform.Location + Data.Axis * Math::Sin((Time::GameTimeSeconds * Data.Rate) + Data.Offset);
		}

		AdditionalRelativeTransform = NewRelativeTransform;

//		AdditionalRelativeTransform.Location = NewRelativeTransform.Location * Alpha;
//		AdditionalRelativeTransform.Rotation = FQuat::FastLerp(RelativeTransform.Rotation, NewRelativeTransform.Rotation, Alpha);

		Owner.RootComponent.RelativeTransform = AdditionalRelativeTransform * RelativeTransform;

	//	PrintToScreen("Debug: " + Owner.RootComponent.ComponentQuat.Rotator(), 0.0, FLinearColor::Green);
	}

}