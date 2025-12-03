class UIslandOverseerSpotLightFaderCapability : UHazeCapability
{
	UIslandOverseerSpotLightComponent SpotLightComp;
	float Duration = 5;
	FHazeAcceleratedFloat AccFadeIn;
	FHazeAcceleratedFloat AccFadeOut;
	float FadeInTarget;
	float PreviousSpotLightIntensity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SpotLightComp = UIslandOverseerSpotLightComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(SpotLightComp.CurrentSpotLight == nullptr)
			return false;
		if(!SpotLightComp.bFade)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Duration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SpotLightComp.bFade = false;

		AccFadeIn.SnapTo(0);
		FadeInTarget = SpotLightComp.CurrentSpotLight.Intensity;
		SpotLightComp.CurrentSpotLight.SetIntensity(0);
		SpotLightComp.CurrentSpotLight.SetVisibility(true);

		if(SpotLightComp.PreviousSpotLight != nullptr)
		{
			PreviousSpotLightIntensity = SpotLightComp.PreviousSpotLight.Intensity;
			AccFadeOut.SnapTo(PreviousSpotLightIntensity);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(SpotLightComp.PreviousSpotLight != nullptr)
		{
			SpotLightComp.PreviousSpotLight.SetVisibility(false);
			SpotLightComp.PreviousSpotLight.SetIntensity(PreviousSpotLightIntensity);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccFadeIn.AccelerateTo(FadeInTarget, Duration, DeltaTime);
		SpotLightComp.CurrentSpotLight.SetIntensity(AccFadeIn.Value);

		if(SpotLightComp.PreviousSpotLight == nullptr)
			return;

		AccFadeOut.AccelerateTo(0, Duration, DeltaTime);
		SpotLightComp.PreviousSpotLight.SetIntensity(AccFadeOut.Value);
	}
};