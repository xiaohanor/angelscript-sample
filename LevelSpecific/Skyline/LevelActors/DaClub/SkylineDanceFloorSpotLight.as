class ASkylineDanceFloorSpotLight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USpotLightComponent SpotLight;
	default SpotLight.SetIntensity(2000.0);
	default SpotLight.SetAttenuationRadius(8000.0);
	default SpotLight.SetCastShadows(false);
	default SpotLight.SetUseInverseSquaredFalloff(false);

	UPROPERTY(EditAnywhere)
	TArray<float> Oscillators;
	default Oscillators.Add(2.0);

	float InitialIntensity = 0.0;

	bool bSyncToMainMusicBeat = true;

	bool bDetectBPM = true;
	float BPM = 120.0;
	float LastBeatTime = 0.0;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve BeatCurve;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialIntensity = SpotLight.Intensity;
/*
		auto MusicManager = UHazeAudioMusicManager::Get();
		MusicManager.OnMainMusicMarker().AddUFunction(this, n"HandleMainMusicMarker");
		MusicManager.OnMainMusicBeat().AddUFunction(this, n"HandleMainMusicBeat");
*/
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Time = Time::GameTimeSeconds;
		float Intensity = InitialIntensity;
		float Alpha = 1.0;
//		float Alpha = (Math::Sin(Time) + 1.0) * 0.5;

		for (auto Oscillator : Oscillators)
		{
//			Alpha += (Math::Sin(Time * Oscillator * PI * 2.0) + 1.0) * 0.5;
			Alpha *= (Math::Sin(Time * Oscillator * PI * 2.0) + 1.0) * 0.5;
		}

//		Alpha /= Oscillators.Num();

//		PrintToScreen("Alpha: " + Alpha + " Time: " + Time::GameTimeSeconds, 0.0, FLinearColor::Green);

//		Alpha = (Alpha > 0.5 ? 1.0 : 0.0);

		Intensity = InitialIntensity * Alpha;

		SpotLight.SetIntensity(Intensity);
	}

	UFUNCTION()
	private void HandleMainMusicMarker(const FString& MarkerName)
	{
	}

	UFUNCTION()
	private void HandleMainMusicBeat()
	{
		if (bDetectBPM && LastBeatTime > 0.0)
			BPM = 60.0 / (Time::GameTimeSeconds - LastBeatTime);

		LastBeatTime = Time::GameTimeSeconds;

		PrintToScreen("-Beat- BPM: " + BPM, 0.2);
	}
};