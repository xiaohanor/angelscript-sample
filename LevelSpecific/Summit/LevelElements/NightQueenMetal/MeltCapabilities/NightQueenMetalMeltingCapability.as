class UNightQueenMetalMeltingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"NightQueenMetal");
	default CapabilityTags.Add(n"NightQueenMetalMelting");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ANightQueenMetal NightQueenMetal;

	UNightQueenMetalMeltingSettings MeltingSettings;

	bool bRegrowing = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		NightQueenMetal = Cast<ANightQueenMetal>(Owner);
		MeltingSettings = UNightQueenMetalMeltingSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(NightQueenMetal.MeltedAlphaTarget == 0.0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(NightQueenMetal.MeltedAlpha == 0.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bRegrowing = false;
		//NightQueenMetal.MeltedAlpha = 0.0;
		//NightQueenMetal.InitMeltedMaterials();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for(auto Crystal : NightQueenMetal.PoweringCrystals)
		{
			if(Crystal == nullptr)
				continue;
			FSummitCrystalObeliskMetalMeltingParams Params;
			Params.MetalLocation = NightQueenMetal.ActorLocation;
			Params.MetalMesh = NightQueenMetal.MeshComp;
			USummitCrystalObeliskEffectsHandler::Trigger_MetalRegrowthFinished(Crystal, Params);
		}

		UNightQueenMetalAcidEventHandler::Trigger_OnFullyRegrown(NightQueenMetal);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// if(NightQueenMetal.MeltedAlpha >= 0.7 && NightQueenMetal.DissolveAlphaTarget < 1.0)
		if(NightQueenMetal.MeltedAlpha >= 1.0)
		{
			// Start dissolving when fully melted
			NightQueenMetal.DissolveAlphaTarget = 1.0;
		}

		if(NightQueenMetal.ShouldRegrow())
		{
			if(!bRegrowing)
			{
				bRegrowing = true;
				for(auto Crystal : NightQueenMetal.PoweringCrystals)
				{
					FSummitCrystalObeliskMetalMeltingParams Params;
					Params.MetalLocation = NightQueenMetal.ActorLocation;
					Params.MetalMesh = NightQueenMetal.MeshComp;
					USummitCrystalObeliskEffectsHandler::Trigger_MetalRegrowthStarted(Crystal, Params);

					UNightQueenMetalAcidEventHandler::Trigger_OnStartRegrow(NightQueenMetal);
				}
			}

			NightQueenMetal.MeltedAlphaTarget -= MeltingSettings.RegrowthSpeed * DeltaTime;
			NightQueenMetal.MeltedAlphaTarget = Math::Clamp(NightQueenMetal.MeltedAlphaTarget, 0.0, 1.0);
		}

		//PrintToScreenScaled("MeltedAlphaTarget: " + NightQueenMetal.MeltedAlphaTarget);

		if(bRegrowing)
		{
			NightQueenMetal.MeltedAlpha = Math::FInterpConstantTo(NightQueenMetal.MeltedAlpha, NightQueenMetal.MeltedAlphaTarget, DeltaTime, MeltingSettings.RegrowthSpeed);
			//PrintToScreenScaled("REgropwing", 0.0, FLinearColor::Green);
		}
		else
		{
			// NightQueenMetal.MeltedAlpha = Math::FInterpConstantTo(NightQueenMetal.MeltedAlpha, NightQueenMetal.MeltedAlphaTarget, DeltaTime, MeltingSettings.MeltingSpeed);
			NightQueenMetal.MeltedAlpha += (MeltingSettings.MeltingSpeed * DeltaTime * 3.0);
			if(NightQueenMetal.CurrentSettings.bSaturateMeltAlpha)
			{
				NightQueenMetal.MeltedAlpha = Math::Saturate(NightQueenMetal.MeltedAlpha);
			}
			//PrintToScreenScaled("Melting", 0.0, FLinearColor::Red);
		}

		// Delay the shader melt a bit to better match up with the GreenGo Curve. 
		// hack tbh, TODO: rewrite this so we have 3 tracks for the melting
		const float ModifiedAlpha = Math::Max(NightQueenMetal.MeltedAlpha - 0.3, 0.0);
		// const float ModifiedAlpha = 0.0;
		
		NightQueenMetal.SetMeltedMaterials(ModifiedAlpha);

		//PrintToScreen("MeltAlpha: " + NightQueenMetal.MeltedAlpha);
	}

	
}