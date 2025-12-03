struct FSkylineBossTankLight
{
	UPROPERTY()
	FLinearColor Color;

	UPROPERTY()
	float Freq = 0.0;

	UPROPERTY()
	float FreqAlpha = 1.0;

	UPROPERTY()
	float BlendTime = 0.0;

	UPROPERTY()
	FRuntimeFloatCurve Curve;
}

class USkylineBossTankLightComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	FName MaterialParameter = n"EmissiveColor";

	UPROPERTY(EditAnywhere)
	FSkylineBossTankLight DefaultLightSettings;
	default DefaultLightSettings.Color = FLinearColor::Green;
	default DefaultLightSettings.BlendTime = 0.0;

	UPROPERTY(EditAnywhere)
	FName PrimitiveComponentName = n"Mesh";

	UPROPERTY(EditAnywhere)
	TArray<FName> SlotNames;
	default SlotNames.Add(n"WhiteMetal_mat");
	default SlotNames.Add(n"DarkMetal_mat");
	default SlotNames.Add(n"Emission_01_mat");
	default SlotNames.Add(n"MissileRed_mat");

	UPROPERTY(BlueprintReadOnly)
	TArray<UMaterialInstanceDynamic> MIDs;

	TInstigated<FSkylineBossTankLight> LightSettings;
	FSkylineBossTankLight PrevLightSettings;

	UPROPERTY(BlueprintReadOnly)
	FLinearColor Color;

	float BlendTimeStamp = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LightSettings.DefaultValue = DefaultLightSettings;
		PrevLightSettings = LightSettings.Get();

		auto PrimitiveComponent = UPrimitiveComponent::Get(Owner, PrimitiveComponentName);

		for (int i = 0; i < PrimitiveComponent.NumMaterials; i++)
		{
			if (SlotNames.Num() > 0)
			{
				if (SlotNames.Contains(PrimitiveComponent.MaterialSlotNames[i]))
					MIDs.Add(PrimitiveComponent.CreateDynamicMaterialInstance(i));
			}
			else
				MIDs.Add(PrimitiveComponent.CreateDynamicMaterialInstance(i));
		}

		for (auto MID : MIDs)
			MID.SetVectorParameterValue(MaterialParameter, Color);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Alpha = 1.0;
		
		if (LightSettings.Get().BlendTime > SMALL_NUMBER)
			Alpha = Math::Clamp(1.0 - (BlendTimeStamp - Time::GameTimeSeconds) / LightSettings.Get().BlendTime, 0.0, 1.0);

		if (LightSettings.Get().Curve.NumKeys > 0)
			Alpha = LightSettings.Get().Curve.GetFloatValue(Alpha);

		Color = Math::Lerp(PrevLightSettings.Color, LightSettings.Get().Color, Alpha);

		float FreqValue = (Math::Sin(Time::GameTimeSeconds * LightSettings.Get().Freq) + 1.0) * 0.5;

		Color *= Math::Lerp(1.0, 1.0 - FreqValue, LightSettings.Get().FreqAlpha);
		
		for (auto MID : MIDs)
			MID.SetVectorParameterValue(MaterialParameter, Color);
	}

	UFUNCTION()
	void ApplyLightSettings(FSkylineBossTankLight Settings, FInstigator Instigator)
	{
		PrevLightSettings = LightSettings.Get();
		LightSettings.Apply(Settings, Instigator);
		BlendTimeStamp = Time::GameTimeSeconds + LightSettings.Get().BlendTime;
	}

	UFUNCTION()
	void ClearLightSettings(FInstigator Instigator)
	{
		PrevLightSettings = LightSettings.Get();
		LightSettings.Clear(Instigator);
		BlendTimeStamp = Time::GameTimeSeconds + PrevLightSettings.BlendTime;
	}
};