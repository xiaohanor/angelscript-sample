class USolarFlareSunSkyCapability : UHazeCapability
{
	default CapabilityTags.Add(n"FlareEffects");

	default TickGroup = EHazeTickGroup::Gameplay;

	ASolarFlareSun Sun;
	AGameSky GameSky;
	AHazePostProcessVolume PostProcessVolume;

	float DirectionalLightIntensity;
	float HDRIntensity;
	float SkyLightIntensity;
	float LightShaftIntensity;

	float CurrentDirectionLightIntensity;
	float CurrentHDRIntensity;
	float CurrentSkyLightIntensity;
	float CurrentLightShaftIntensity;

	float MainOffMultiplier;
	float MainOnMultiplier;
	float HDRIntensityMultiplier = 0.15;

	float MainOffMultiplierPhase1 = 0.2;
	float MainOffMultiplierPhase2 = 0.08;
	float MainOffMultiplierPhase3 = 0.006;
	float MainOnMultiplierPhase1 = 1.0;
	float MainOnMultiplierPhase2 = 1.15;
	float MainOnMultiplierPhase3 = 1.4;
	float MainOnMultiplierFinalPhase = 0.2;

	float Alpha;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Sun = Cast<ASolarFlareSun>(Owner);
		GameSky = TListedActors<AGameSky>().GetSingle();
	
		DirectionalLightIntensity = GameSky.DirectionalLight.Intensity;
		HDRIntensity = GameSky.HDRIntensity;
		GameSky.bUseIntensityOverride = true;
		
		SkyLightIntensity = GameSky.SkyLightIntensity;
		LightShaftIntensity = GameSky.LightShaftIntensity;
	
		CurrentDirectionLightIntensity = DirectionalLightIntensity;
		CurrentHDRIntensity = HDRIntensity;
		CurrentSkyLightIntensity = SkyLightIntensity;
		CurrentLightShaftIntensity = LightShaftIntensity;
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
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Alpha -= Sun.TelegraphDuration * DeltaTime;

		switch(SolarFlareSun::GetVFXPhase())
		{
			case ESolarFlareSunVFXPhase::Phase1:
				MainOffMultiplier = Math::FInterpConstantTo(MainOffMultiplier, MainOffMultiplierPhase1, DeltaTime, MainOffMultiplierPhase1);
				MainOnMultiplier = Math::FInterpConstantTo(MainOnMultiplier, MainOnMultiplierPhase1, DeltaTime, MainOnMultiplierPhase1);
				break;
			case ESolarFlareSunVFXPhase::Phase2:
				MainOffMultiplier = Math::FInterpConstantTo(MainOffMultiplier, MainOffMultiplierPhase2, DeltaTime, MainOffMultiplierPhase2);
				MainOnMultiplier = Math::FInterpConstantTo(MainOnMultiplier, MainOnMultiplierPhase2, DeltaTime, MainOnMultiplierPhase2);
				break;
			case ESolarFlareSunVFXPhase::Phase3:
				MainOffMultiplier = Math::FInterpConstantTo(MainOffMultiplier, MainOffMultiplierPhase3, DeltaTime, MainOffMultiplierPhase3);
				MainOnMultiplier = Math::FInterpConstantTo(MainOnMultiplier, MainOnMultiplierPhase3, DeltaTime, MainOnMultiplierPhase3);
				break;
			case ESolarFlareSunVFXPhase::FinalPhase:
				MainOffMultiplier = Math::FInterpConstantTo(MainOffMultiplier, MainOffMultiplierPhase3, DeltaTime, MainOffMultiplierPhase3);
				MainOnMultiplier = Math::FInterpConstantTo(MainOnMultiplier, MainOnMultiplierFinalPhase, DeltaTime, 18.0);
				break;
			case ESolarFlareSunVFXPhase::Implode:
				break;
			case ESolarFlareSunVFXPhase::BlackHole:
				break;
		}

		if (Sun.bIsFlaring)
		{

			CurrentDirectionLightIntensity = Math::FInterpConstantTo
			(CurrentDirectionLightIntensity, 
			DirectionalLightIntensity * MainOffMultiplier, 
			DeltaTime, 
			(DirectionalLightIntensity * MainOnMultiplier) / Sun.TelegraphDuration);

			CurrentHDRIntensity = Math::FInterpConstantTo
			(CurrentHDRIntensity, 
			HDRIntensity * MainOffMultiplier, 
			DeltaTime, 
			(HDRIntensity * MainOnMultiplier) / Sun.TelegraphDuration);

			CurrentSkyLightIntensity = Math::FInterpConstantTo
			(CurrentSkyLightIntensity, 
			SkyLightIntensity * MainOffMultiplier, 
			DeltaTime, 
			(SkyLightIntensity * MainOnMultiplier) / Sun.TelegraphDuration);

			CurrentLightShaftIntensity = Math::FInterpConstantTo(
			CurrentLightShaftIntensity, 
			0.0, DeltaTime, 
			LightShaftIntensity);
		}
		else
		{
			float CurrentInterpSpeed = MainOnMultiplier;

			if (SolarFlareSun::GetVFXPhase() == ESolarFlareSunVFXPhase::FinalPhase)
			{
				CurrentInterpSpeed = 5.0;
			}

			CurrentDirectionLightIntensity = Math::FInterpConstantTo
			(CurrentDirectionLightIntensity, 
			DirectionalLightIntensity * MainOnMultiplier, 
			DeltaTime, 
			DirectionalLightIntensity * CurrentInterpSpeed);

			CurrentHDRIntensity = Math::FInterpConstantTo
			(CurrentHDRIntensity, 
			HDRIntensity * MainOnMultiplier, 
			DeltaTime, 
			HDRIntensity * CurrentInterpSpeed);

			CurrentSkyLightIntensity = Math::FInterpConstantTo
			(CurrentSkyLightIntensity, 
			SkyLightIntensity * MainOnMultiplier, 
			DeltaTime, 
			SkyLightIntensity * CurrentInterpSpeed);

			CurrentLightShaftIntensity = Math::FInterpConstantTo(
			CurrentLightShaftIntensity, 
			LightShaftIntensity, DeltaTime, 
			LightShaftIntensity * CurrentInterpSpeed);
		}

		GameSky.DirectionalLight.SetIntensity(CurrentDirectionLightIntensity);
		GameSky.HDRIntensity = CurrentHDRIntensity;
		GameSky.SkyLightIntensity = CurrentSkyLightIntensity;
		GameSky.LightShaftIntensity = CurrentLightShaftIntensity;

		// PrintToScreen(f"{MainOnMultiplier=}");
		// PrintToScreen(f"{CurrentHDRIntensity=}");
		// PrintToScreen(f"{GameSky.HDRIntensity=}");
	}
};