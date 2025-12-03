class AGameShowArenaSpotlight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent SpotlightMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UGodrayComponent Godray;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSphereComponent SpotlightHazeSphere;

	UPROPERTY(DefaultComponent, Attach = Root)
	ULensFlareComponent SpotlightLensFlare;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	float BlinkingTimer = 0;
	float BlinkingTimerDuration = 3.15;
	bool bShouldTickBlinkingTimer = false;

	UPROPERTY()
	TArray<UCurveFloat> FlickerCurves;
	
	UPROPERTY(EditInstanceOnly)

	AHazeSpotLight ConnectedLightSourceSpotlight;
	float RandomFlickerOffset = 0;
	// All FlickerCurves have a duration of 7
	float FlickerDuration = 7;
	int MaterialIndexToChange = 0;

	FLinearColor OnColor;
	FLinearColor OffColor = FLinearColor::Black;

	float StartingGodrayOpacity;
	float StartingSpotlightCompIntensity;
	float StartingHazeSphereOpacity;
	FLinearColor StartingLenseFlareTint;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnColor = SpotlightMesh.CreateDynamicMaterialInstance(MaterialIndexToChange).GetVectorParameterValue(n"EmissiveTint");
		StartingGodrayOpacity = Godray.Opacity;
		StartingHazeSphereOpacity = SpotlightHazeSphere.Opacity;
		RandomFlickerOffset = Math::RandRange(0.0, FlickerDuration);
		StartingSpotlightCompIntensity = ConnectedLightSourceSpotlight.SpotLightComponent.Intensity;
		StartingLenseFlareTint = SpotlightLensFlare.Tint;
	}

	void EnableLight(bool bEnable)
	{
		if(bEnable)
		{
			SpotlightMesh.SetVectorParameterValueOnMaterialIndex(MaterialIndexToChange, n"EmissiveTint", FVector(OnColor.R, OnColor.G, OnColor.B));
			Godray.SetGodrayOpacity(StartingGodrayOpacity);
			ConnectedLightSourceSpotlight.SpotLightComponent.SetIntensity(StartingSpotlightCompIntensity);
			SpotlightHazeSphere.SetOpacityValue(StartingHazeSphereOpacity);
			SpotlightLensFlare.SetTintValue(StartingLenseFlareTint);
		}
		else
		{
			SpotlightMesh.SetVectorParameterValueOnMaterialIndex(MaterialIndexToChange, n"EmissiveTint", FVector(OffColor.R, OffColor.G, OffColor.B));
			Godray.SetGodrayOpacity(0.0);
			ConnectedLightSourceSpotlight.SpotLightComponent.SetIntensity(0.0);
			SpotlightHazeSphere.SetOpacityValue(0.0);
			SpotlightLensFlare.SetTintValue(FLinearColor::Black);
		}
	}

	void RecieveFlickerValue(float Time, EGameShowLightGlitchIntensity Intensity)
	{
		float Alpha = (Time + RandomFlickerOffset) % FlickerDuration;

		FLinearColor NewColor = Math::Lerp(OffColor, OnColor, FlickerCurves[Intensity].GetFloatValue(Alpha));
		SpotlightMesh.SetVectorParameterValueOnMaterialIndex(MaterialIndexToChange, n"EmissiveTint", FVector(NewColor.R, NewColor.G, NewColor.B));
		
		float NewGodRayOpacity = Math::Lerp(0.0, StartingGodrayOpacity, FlickerCurves[Intensity].GetFloatValue(Alpha));
		Godray.SetGodrayOpacity(NewGodRayOpacity);

		float NewSpotlightIntensity = Math::Lerp(0.0, 4.0, FlickerCurves[Intensity].GetFloatValue(Alpha));
		ConnectedLightSourceSpotlight.SpotLightComponent.SetIntensity(NewSpotlightIntensity);

		float NewHazeSphereOpacity = Math::Lerp(0.0, StartingHazeSphereOpacity, FlickerCurves[Intensity].GetFloatValue(Alpha));
		SpotlightHazeSphere.SetOpacityValue(NewHazeSphereOpacity);

		FLinearColor NewLenseFlareTint = Math::Lerp(FLinearColor::Black, StartingLenseFlareTint, FlickerCurves[Intensity].GetFloatValue(Alpha));
		SpotlightLensFlare.SetTintValue(NewLenseFlareTint);
	}

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		Godray.ConstructionScript_Hack();
    }
};