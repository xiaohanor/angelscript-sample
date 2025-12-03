class USolarFlareSunPostProcessingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"FlareEffects");

	default TickGroup = EHazeTickGroup::Gameplay;

	ASolarFlareSun Sun;
	AHazePostProcessVolume PostProcessVolume;

	float MinBrightness;
	float MaxBrightness;
	float BloomIntensity;
	float VignetteIntensity = 0.075;
	float SensorWidth;
	float LensFlareIntensity;
	float Temp;
	float ChromaticAbberation;

	float TargetMinBrightness;
	float TargetMaxBrightness;
	float TargetBloomIntensity;
	float TargetVignetteIntensity = 0.075;
	float TargetSensorWidth;
	float TargetLensFlareIntensity;
	float TargetTemp;
	float TargetChromaticAbberation;

	float CurrentMinBrightness;
	float CurrentMaxBrightness;
	float CurrentBloomIntensity;
	float CurrentVignetteIntensity = 0.075;
	float CurrentSensorWidth;
	float CurrentLensFlareIntensity;
	float CurrentTemp;
	float CurrentChromaticAbberation;

	float PostProcessThreshold = 15000.0;

	UMaterialInstanceDynamic BlurHorizontal;
	UMaterialInstanceDynamic BlurVertical;
	FWeightedBlendable Blendable;
	FWeightedBlendable Blendable2;

	bool bReachedMaxBlend;

	FLinearColor ArtistColor;
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Sun = Cast<ASolarFlareSun>(Owner);
		Sun.OnSolarFlareActivateWave.AddUFunction(this, n"OnSolarFlareActivateWave");
		Sun.OnSolarFlareActivateBlackHole.AddUFunction(this, n"OnSolarFlareActivateBlackHole");
		PostProcessVolume = Sun.PostProcessVolume;
		MinBrightness = PostProcessVolume.Settings.AutoExposureMinBrightness;
		MaxBrightness = PostProcessVolume.Settings.AutoExposureMaxBrightness;
		BloomIntensity = PostProcessVolume.Settings.BloomIntensity; 
		VignetteIntensity = PostProcessVolume.Settings.VignetteIntensity;	
		SensorWidth = PostProcessVolume.Settings.DepthOfFieldFocalDistance;
		LensFlareIntensity = 1.0;
		Temp = PostProcessVolume.Settings.WhiteTemp;
		ChromaticAbberation = PostProcessVolume.Settings.SceneFringeIntensity;
		
		// PostProcessVolume.Settings.ColorGrad

		CurrentMinBrightness = MinBrightness;
		CurrentMaxBrightness = MaxBrightness;
		CurrentBloomIntensity = BloomIntensity; 
		CurrentVignetteIntensity = VignetteIntensity;	
		CurrentSensorWidth = SensorWidth;
		CurrentTemp = Temp;
		CurrentChromaticAbberation = ChromaticAbberation;

		if(Sun.BlurHorizontal != nullptr)
		{
			BlurHorizontal = Material::CreateDynamicMaterialInstance(Sun, Sun.BlurHorizontal);
			Blendable.Object = BlurHorizontal;
			Blendable.Weight = 1.0;
			PostProcessVolume.Settings.WeightedBlendables.Array.Add(Blendable);
		}

		if(Sun.BlurVertical != nullptr)
		{
			BlurVertical = Material::CreateDynamicMaterialInstance(Sun, Sun.BlurVertical);
			Blendable2.Object = BlurVertical;
			Blendable2.Weight = 1.0;
			PostProcessVolume.Settings.WeightedBlendables.Array.Add(Blendable2);
		}
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
		float InterpMultiplier = 1.0;
		
		if (SolarFlareSun::GetVFXPhase() == ESolarFlareSunVFXPhase::FinalPhase)
		{
			TargetMinBrightness = MinBrightness + (20 * Sun.MashLauncher.GetFullProgress());
			TargetMaxBrightness = MaxBrightness + (20 * Sun.MashLauncher.GetFullProgress());
			TargetBloomIntensity = BloomIntensity * 0.5;
			TargetSensorWidth = 0.0;
			TargetVignetteIntensity = 0.5 * Sun.MashLauncher.GetFullProgress();
			TargetLensFlareIntensity = 1.0;
			TargetTemp = Temp + (Temp * 2.0 * Sun.MashLauncher.GetFullProgress());
			TargetChromaticAbberation = 1.0 * Sun.MashLauncher.GetFullProgress();
		}
		else if (SolarFlareSun::GetVFXPhase() == ESolarFlareSunVFXPhase::BlackHole)
		{
			TargetSensorWidth = 0.0;
			TargetVignetteIntensity = VignetteIntensity + (TargetVignetteIntensity * 1.5);
			InterpMultiplier = 0.3;			
			TargetTemp = Temp;
			TargetChromaticAbberation = 0.0;
		}
		else if (GetPostProcessMultiplierCurved() != 0.0 && !bReachedMaxBlend)
		{
			InterpMultiplier = 1.5;

			switch(SolarFlareSun::GetVFXPhase())
			{
				case ESolarFlareSunVFXPhase::Phase1:
					TargetMinBrightness = MinBrightness - (MinBrightness * 0.5 * GetPostProcessMultiplierCurved());
					TargetMaxBrightness = MaxBrightness - (MaxBrightness * 0.5 * GetPostProcessMultiplierCurved());
					TargetBloomIntensity = BloomIntensity + (BloomIntensity * 0.75 * GetPostProcessMultiplierCurved());
					TargetVignetteIntensity = VignetteIntensity + (TargetVignetteIntensity * 0.3 * GetPostProcessMultiplierCurved());
					TargetLensFlareIntensity = LensFlareIntensity + (4.0 * GetPostProcessMultiplier());
					TargetTemp = Temp + (Temp * 1.5 * GetPostProcessMultiplierCurved());
					TargetChromaticAbberation = 7.0 * GetPostProcessMultiplierCurved();
					break;
				case ESolarFlareSunVFXPhase::Phase2:
					TargetMinBrightness = MinBrightness - (MinBrightness * 0.7 * GetPostProcessMultiplierCurved());
					TargetMaxBrightness = MaxBrightness - (MaxBrightness * 0.7 * GetPostProcessMultiplierCurved());
					TargetBloomIntensity = BloomIntensity + (BloomIntensity * 10.0 * GetPostProcessMultiplierCurved());
					TargetVignetteIntensity = VignetteIntensity + (TargetVignetteIntensity * 0.4 * GetPostProcessMultiplierCurved());
					TargetLensFlareIntensity = LensFlareIntensity + (4.5 * GetPostProcessMultiplier());
					TargetTemp = Temp + (Temp * 1.5 * GetPostProcessMultiplierCurved());
					TargetChromaticAbberation = 9.0 * GetPostProcessMultiplierCurved();
					break;
				case ESolarFlareSunVFXPhase::Phase3:
					TargetMinBrightness = MinBrightness - (MinBrightness * 1.0 * GetPostProcessMultiplierCurved());
					TargetMaxBrightness = MaxBrightness - (MaxBrightness * 1.0 * GetPostProcessMultiplierCurved());
					TargetBloomIntensity = BloomIntensity + (BloomIntensity * 1.25 * GetPostProcessMultiplierCurved());
					TargetVignetteIntensity = VignetteIntensity + (TargetVignetteIntensity * 0.5 * GetPostProcessMultiplierCurved());
					TargetLensFlareIntensity = LensFlareIntensity + (5.0 * GetPostProcessMultiplier());
					// TargetTemp = Temp * (Temp * 1.2 * GetPostProcessMultiplierCurved());
					TargetTemp = Temp;
					TargetChromaticAbberation = 10.0 * GetPostProcessMultiplierCurved();
					break;
				case ESolarFlareSunVFXPhase::FinalPhase:
					TargetMinBrightness = MinBrightness - (MinBrightness * 0.85 * GetPostProcessMultiplierCurved());
					TargetMaxBrightness = MaxBrightness - (MaxBrightness * 0.85 * GetPostProcessMultiplierCurved());
					TargetBloomIntensity = BloomIntensity + (BloomIntensity * 1.5 * GetPostProcessMultiplierCurved());
					TargetVignetteIntensity = VignetteIntensity + (TargetVignetteIntensity * 0.6 * GetPostProcessMultiplierCurved());
					TargetLensFlareIntensity = LensFlareIntensity + (7.0 * GetPostProcessMultiplier());
					TargetTemp = Temp * (Temp * 1.1 * GetPostProcessMultiplierCurved());
					TargetChromaticAbberation = 10.0 * GetPostProcessMultiplierCurved();
					break;
				case ESolarFlareSunVFXPhase::Implode:
					TargetSensorWidth = 0.0;
					TargetTemp = Temp;
					TargetChromaticAbberation = ChromaticAbberation;
					break;
				case ESolarFlareSunVFXPhase::BlackHole:
					TargetSensorWidth = 0.0;
					TargetTemp = Temp;
					TargetChromaticAbberation = ChromaticAbberation;
					break;
			}

			TargetSensorWidth = 0.6 * GetPostSensorWidthMultiplier();

			if (GetPostProcessMultiplierCurved() > 0.95)
				bReachedMaxBlend = true;
		}
		else if (Sun.bIsFlaring)
		{
			InterpMultiplier = 1.0 / Sun.TelegraphDuration;
			bReachedMaxBlend = false;

			switch(SolarFlareSun::GetVFXPhase())
			{
				case ESolarFlareSunVFXPhase::Phase1:
					TargetMinBrightness = MinBrightness * 8;
					TargetMaxBrightness = MaxBrightness * 8;
					TargetBloomIntensity = BloomIntensity * 0.4;
					TargetVignetteIntensity = 0.2;
					TargetLensFlareIntensity = LensFlareIntensity;
					TargetChromaticAbberation = 0.1;
					break;
				case ESolarFlareSunVFXPhase::Phase2:
					TargetMinBrightness = MinBrightness * 15;
					TargetMaxBrightness = MaxBrightness * 15;
					TargetBloomIntensity = BloomIntensity * 0.3;
					TargetVignetteIntensity = 0.3;
					TargetLensFlareIntensity = LensFlareIntensity;
					TargetChromaticAbberation = 0.25;
					break;
				case ESolarFlareSunVFXPhase::Phase3:
					TargetMinBrightness = MinBrightness * 25;
					TargetMaxBrightness = MaxBrightness * 25;
					TargetBloomIntensity = BloomIntensity * 0.2;
					TargetVignetteIntensity = 0.5;
					TargetLensFlareIntensity = LensFlareIntensity;
					TargetChromaticAbberation = 0.5;
					break;
				case ESolarFlareSunVFXPhase::FinalPhase:
					TargetMinBrightness = MinBrightness * 30;
					TargetMaxBrightness = MaxBrightness * 30;
					TargetBloomIntensity = BloomIntensity * 0.1;
					TargetVignetteIntensity = 0.55;
					TargetLensFlareIntensity = LensFlareIntensity;
					TargetChromaticAbberation = 4.0;
					break;
				case ESolarFlareSunVFXPhase::Implode:
					TargetSensorWidth = 0.0;
					TargetLensFlareIntensity = LensFlareIntensity;
					break;
				case ESolarFlareSunVFXPhase::BlackHole:
					TargetSensorWidth = 0.0;
					TargetLensFlareIntensity = LensFlareIntensity;
					break;
			}	

			TargetTemp = Temp;
			TargetChromaticAbberation = 0.0;
			TargetSensorWidth = 0.0;
		}
		else
		{
			switch(SolarFlareSun::GetVFXPhase())
			{
				case ESolarFlareSunVFXPhase::Phase1:
					InterpMultiplier = 0.8;
					break;
				case ESolarFlareSunVFXPhase::Phase2:
					InterpMultiplier = 0.8;
					break;
				case ESolarFlareSunVFXPhase::Phase3:
					InterpMultiplier = 0.8;
					break;
				case ESolarFlareSunVFXPhase::FinalPhase:
					InterpMultiplier = 1.0;
					break;
				case ESolarFlareSunVFXPhase::Implode:
					InterpMultiplier = 1.0;
					break;
				case ESolarFlareSunVFXPhase::BlackHole:
					InterpMultiplier = 1.0;
					break;
			}

			if (SolarFlareSun::GetVFXPhase() != ESolarFlareSunVFXPhase::FinalPhase)
			{
				TargetMinBrightness = MinBrightness;
				TargetMaxBrightness = MaxBrightness;
				TargetBloomIntensity = BloomIntensity;
				TargetVignetteIntensity = VignetteIntensity;
				TargetTemp = Temp;
				TargetChromaticAbberation = ChromaticAbberation;
				TargetLensFlareIntensity = 0.0;				
			}
			else
			{
				TargetMinBrightness = MinBrightness * 8.0;
				TargetMaxBrightness = MaxBrightness * 8.0;
				TargetBloomIntensity = BloomIntensity;
				TargetVignetteIntensity = VignetteIntensity * 0.4;				
				TargetTemp = Temp;
				TargetChromaticAbberation = ChromaticAbberation;
				TargetLensFlareIntensity = 0.0;				
			}

			TargetSensorWidth = 0.0;
 		}

		CurrentMinBrightness = Math::FInterpConstantTo(CurrentMinBrightness, TargetMinBrightness, DeltaTime, MinBrightness * InterpMultiplier);
		CurrentMaxBrightness = Math::FInterpConstantTo(CurrentMaxBrightness, TargetMaxBrightness, DeltaTime, MaxBrightness * InterpMultiplier);
		// PrintToScreen(f"{TargetMinBrightness=}");
		// PrintToScreen(f"{TargetMaxBrightness=}");
		// PrintToScreen(f"{CurrentMinBrightness=}");
		// PrintToScreen(f"{CurrentMaxBrightness=}");
		// PrintToScreen(f"{InterpMultiplier=}");
		CurrentBloomIntensity = Math::FInterpConstantTo(CurrentBloomIntensity, TargetBloomIntensity, DeltaTime, 100 * InterpMultiplier);
		CurrentVignetteIntensity = Math::FInterpConstantTo(CurrentVignetteIntensity, TargetVignetteIntensity, DeltaTime, VignetteIntensity * InterpMultiplier);
		CurrentSensorWidth = Math::FInterpConstantTo(CurrentSensorWidth, TargetSensorWidth, DeltaTime, 2.5 * InterpMultiplier);
		CurrentLensFlareIntensity = Math::FInterpConstantTo(CurrentLensFlareIntensity, TargetLensFlareIntensity, DeltaTime, InterpMultiplier);
		CurrentChromaticAbberation = Math::FInterpConstantTo(CurrentChromaticAbberation, TargetChromaticAbberation, DeltaTime, InterpMultiplier);
		CurrentTemp = Math::FInterpTo(CurrentTemp, TargetTemp, DeltaTime, 3.0 * InterpMultiplier);
		CurrentChromaticAbberation = Math::FInterpConstantTo(CurrentChromaticAbberation, TargetChromaticAbberation, DeltaTime, 15.0 * InterpMultiplier);
		
		if(Sun.BlurHorizontal != nullptr)
		{
			BlurHorizontal.SetScalarParameterValue(n"Radius", CurrentSensorWidth * 6.0);
		}

		if(Sun.BlurVertical != nullptr)
		{
			BlurVertical.SetScalarParameterValue(n"Radius", CurrentSensorWidth * 6.0);
		}

		PrintToScreen(f"{TargetChromaticAbberation=}");
		PrintToScreen(f"{CurrentChromaticAbberation=}");

		PostProcessVolume.Settings.AutoExposureMinBrightness = CurrentMinBrightness;
		PostProcessVolume.Settings.AutoExposureMaxBrightness = CurrentMaxBrightness;
		PostProcessVolume.Settings.BloomIntensity = CurrentBloomIntensity;
		PostProcessVolume.Settings.VignetteIntensity = CurrentVignetteIntensity;		
		PostProcessVolume.Settings.DepthOfFieldSensorWidth = 0;
		PostProcessVolume.Settings.LensFlareIntensity = CurrentLensFlareIntensity;
		PostProcessVolume.Settings.WhiteTemp = CurrentTemp;
		PostProcessVolume.Settings.SceneFringeIntensity = CurrentChromaticAbberation;
	}

	float GetPostProcessMultiplier()
	{
		if (Sun.CurrentFireDonut == nullptr || Sun.CurrentFireDonut.IsActorBeingDestroyed())
			return 0.0;

		float Percent = GetAverageAbsDistToPlayers() / PostProcessThreshold;
		Percent = Math::Clamp(Percent, 0, 1);
		return 1 - Percent;
	}

	float GetPostProcessMultiplierCurved()
	{
		if (Sun.CurrentFireDonut == nullptr || Sun.CurrentFireDonut.IsActorBeingDestroyed())
			return 0.0;

		float Percent = GetAverageAbsDistToPlayers() / PostProcessThreshold;
		Percent = Math::Clamp(Percent, 0, 1);
		return Sun.PostProcessIntensityCurve.GetFloatValue(1 - Percent);
	}

	//To get closer distance
	float GetPostSensorWidthMultiplier()
	{
		if (Sun.CurrentFireDonut == nullptr)
			return 0.0;

		float Percent = GetAverageAbsDistToPlayers() / (PostProcessThreshold / 15);
		Percent = Math::Clamp(Percent, 0, 1);
		return Sun.PostProcessIntensityCurve.GetFloatValue(1 - Percent);
	}

	float GetAverageAbsDistToPlayers()
	{
		if (Sun.CurrentFireDonut == nullptr)
			return 0.0;

		FVector Average = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) / 2;
		FVector Direction = Sun.ActorLocation - Average;
		return Math::Abs(Sun.CurrentFireDonut.DistanceDeathCheck - Direction.Size());
	}
	
	UFUNCTION()
	private void OnSolarFlareActivateWave()
	{
		CurrentSensorWidth = 0.6;
	}

	UFUNCTION()
	private void OnSolarFlareActivateBlackHole()
	{
		CurrentSensorWidth = 0.0;
	}
};