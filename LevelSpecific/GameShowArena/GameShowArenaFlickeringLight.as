enum EGameShowLightType
{
	Strip,
	Hanging,
	Big,
	MAX
}

class AGameShowArenaFlickeringLight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY()
	TArray<UStaticMesh> Meshes;
	UPROPERTY()
	TArray<UMaterialInstance> EmissiveMaterials;

	UPROPERTY()
	TArray<UCurveFloat> FlickerCurves;

	UPROPERTY(EditInstanceOnly)
	EGameShowLightType LightType;

	UPROPERTY(EditInstanceOnly)
	bool bStartEnabled = true;

	UPROPERTY(EditInstanceOnly, Meta = (EditCondition = "LightType == EGameShowLightType::Big"))
	TArray<AGodray> BigGodRays;

	UPROPERTY(EditInstanceOnly, Meta = (EditCondition = "LightType == EGameShowLightType::Big"))
	AHazeSpotLight BigSpotlight;

	UPROPERTY(EditInstanceOnly)
	AHazeSphere ConnectedHazeSphere;
	float StartingHazeSphereOpacity;

	float RandomFlickerOffset = 0;
	// All FlickerCurves have a duration of 7
	float FlickerDuration = 7;
	int MaterialIndexToChange = 0;

	FLinearColor OnColor;
	FLinearColor OffColor = FLinearColor::Black;

	float StartingBigGodrayOpacity;
	float StartingBigSpotlightIntensity;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		SetMaterialIndexToUse();
		SetLightMesh();
#endif	
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetMaterialIndexToUse();
		SetLightMesh();

		OnColor = Mesh.CreateDynamicMaterialInstance(MaterialIndexToChange).GetVectorParameterValue(n"EmissiveTint");
		if(LightType != EGameShowLightType::Big)
			RandomFlickerOffset = Math::RandRange(0.0, FlickerDuration);

		if(ConnectedHazeSphere != nullptr)
			StartingHazeSphereOpacity = ConnectedHazeSphere.HazeSphereComponent.Opacity;

		// Temp! Haning lights should probably not be emissive at all...
		if(LightType == EGameShowLightType::Hanging)
			Mesh.SetVectorParameterValueOnMaterialIndex(MaterialIndexToChange, n"EmissiveTint", FVector(OffColor.R, OffColor.G, OffColor.B));

		if(LightType == EGameShowLightType::Big)
		{
			StartingBigGodrayOpacity = BigGodRays[0].Component.Opacity;
			StartingBigSpotlightIntensity = BigSpotlight.SpotLightComponent.Intensity;
		}
	}

	void EnableLight(bool bEnable)
	{
		if(bEnable)
		{
			Mesh.SetVectorParameterValueOnMaterialIndex(MaterialIndexToChange, n"EmissiveTint", FVector(OnColor.R, OnColor.G, OnColor.B));
			
			if(ConnectedHazeSphere != nullptr)
				ConnectedHazeSphere.HazeSphereComponent.SetOpacityValue(StartingHazeSphereOpacity);

			if(LightType == EGameShowLightType::Big)
			{
				for(auto Godray : BigGodRays)
					Godray.Component.SetGodrayOpacity(StartingBigGodrayOpacity);

				BigSpotlight.SpotLightComponent.SetIntensity(StartingBigSpotlightIntensity);
			}
		}
		else
		{
			Mesh.SetVectorParameterValueOnMaterialIndex(MaterialIndexToChange, n"EmissiveTint", FVector(OffColor.R, OffColor.G, OffColor.B));

			if(ConnectedHazeSphere != nullptr)
				ConnectedHazeSphere.HazeSphereComponent.SetOpacityValue(0.0);

			if(LightType == EGameShowLightType::Big)
			{
				for(auto Godray : BigGodRays)
					Godray.Component.SetGodrayOpacity(0.0);

				BigSpotlight.SpotLightComponent.SetIntensity(0.0);
			}
		}
	}

	void RecieveFlickerValue(float Time, EGameShowLightGlitchIntensity Intensity)
	{
		if(LightType == EGameShowLightType::Hanging)
			return;

		float Alpha = (Time + RandomFlickerOffset) % FlickerDuration;

		FLinearColor NewColor = Math::Lerp(OffColor, OnColor, FlickerCurves[Intensity].GetFloatValue(Alpha));
		Mesh.SetVectorParameterValueOnMaterialIndex(MaterialIndexToChange, n"EmissiveTint", FVector(NewColor.R, NewColor.G, NewColor.B));

		if(ConnectedHazeSphere != nullptr)
		{
			ConnectedHazeSphere.HazeSphereComponent.SetOpacityValue(Math::Lerp(0.0, StartingHazeSphereOpacity, FlickerCurves[Intensity].GetFloatValue(Alpha)));
		}

		if(LightType == EGameShowLightType::Big)
		{
			for(auto Godray : BigGodRays)
			{
				float NewGodrayOpacity = Math::Lerp(0.0, StartingBigGodrayOpacity, FlickerCurves[Intensity].GetFloatValue(Alpha));
				Godray.Component.SetGodrayOpacity(NewGodrayOpacity);
			}

			float NewSpotlightIntensity = Math::Lerp(0.0, StartingBigSpotlightIntensity, FlickerCurves[Intensity].GetFloatValue(Alpha));
			BigSpotlight.SpotLightComponent.SetIntensity(NewSpotlightIntensity);
		}
	}

	void SetMaterialIndexToUse()
	{
		switch(LightType)
		{
			case EGameShowLightType::Strip:
			MaterialIndexToChange = 1;
			break;

			case EGameShowLightType::Hanging:
			MaterialIndexToChange = 1;
			break;

			case EGameShowLightType::Big:
			MaterialIndexToChange = 0;
			break;
		}
	}

	void SetLightMesh()
	{
		if(Mesh.StaticMesh != Meshes[LightType])
		{
			Mesh.SetStaticMesh(Meshes[LightType]);
			Mesh.SetMaterial(MaterialIndexToChange, EmissiveMaterials[LightType]);
		}
	}
};