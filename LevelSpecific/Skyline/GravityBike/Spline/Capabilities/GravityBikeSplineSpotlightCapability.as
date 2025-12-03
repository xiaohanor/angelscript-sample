class UGravityBikeSplineSpotlightCapability : UHazeCapability
{
	AGravityBikeSpline GravityBike;
	USpotLightComponent SpotLightComp;
	float InitialIntensity;

	const float FadeOutDuration = 1;
	const float FadeInDuration = 3;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
		SpotLightComp = USpotLightComponent::Get(Owner);
		InitialIntensity = SpotLightComp.Intensity;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(GravityBike.bIsControlledByCutscene)
		{
			float Intensity = SpotLightComp.Intensity;
			Intensity = Math::FInterpConstantTo(Intensity, 0, DeltaTime, InitialIntensity / FadeOutDuration);
			SpotLightComp.SetIntensity(Intensity);
		}
		else
		{
			float Intensity = SpotLightComp.Intensity;
			Intensity = Math::FInterpConstantTo(Intensity, InitialIntensity, DeltaTime, InitialIntensity / FadeInDuration);
			SpotLightComp.SetIntensity(Intensity);
		}
	}
}