class UIslandOverseerSpotLightComponent : UActorComponent
{
	USpotLightComponent PreviousSpotLight;
	USpotLightComponent CurrentSpotLight;
	bool bFade;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void SetSpotLight(USpotLightComponent SpotLight)
	{
		PreviousSpotLight = CurrentSpotLight;
		CurrentSpotLight = SpotLight;
		bFade = true;
	}
};