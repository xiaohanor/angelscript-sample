class AIslandOverseerPlayerLight : AHazePointLight
{
	default PointLightComponent.CastShadows = false;

	const float Duration = 4;
	float Intensity;
	float FadeTime;
	bool bFadeIn;
	bool bCompleted;

	FHazeAcceleratedFloat AccIntensity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Intensity = PointLightComponent.Intensity;
		PointLightComponent.SetIntensity(0);
		bCompleted = true;
	}

	UFUNCTION()
	void FadeIn()
	{
		bFadeIn = true;
		FadeTime = Time::GameTimeSeconds;
		AccIntensity.SnapTo(0);
		bCompleted = false;
	}

	UFUNCTION()
	void FadeOut()
	{
		bFadeIn = false;
		FadeTime = Time::GameTimeSeconds;
		AccIntensity.SnapTo(Intensity);
		bCompleted = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(FadeTime < SMALL_NUMBER || Time::GetGameTimeSince(FadeTime) > Duration)
		{			
			if(!bCompleted)
			{
				if(!bFadeIn)
					DetachFromActor();
				bCompleted = true;
			}
			return;
		}

		float Target = bFadeIn ? Intensity : 0;
		AccIntensity.AccelerateTo(Target, Duration, DeltaSeconds);
		PointLightComponent.SetIntensity(AccIntensity.Value);
	}
}