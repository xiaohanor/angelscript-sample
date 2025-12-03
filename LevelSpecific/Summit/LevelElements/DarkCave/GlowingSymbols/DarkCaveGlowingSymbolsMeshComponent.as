struct FDarkCaveGlowSpotLight
{
	UPROPERTY()
	float Intensity = 1.0;

	UPROPERTY()
	USpotLightComponent SpotLight;

	void SetMultipliedIntensity(float Multiplier)
	{
		SpotLight.SetIntensity(Intensity * Multiplier);
	}
}

class UDarkCaveGlowingSymbolsMeshComponent : UStaticMeshComponent
{
	UPROPERTY(EditAnywhere)
	float PlayerRadius = 3000.0;

	UPROPERTY(EditAnywhere)
	TArray<int> MioIndexes;
	UPROPERTY(EditAnywhere)
	TArray<int> ZoeIndexes;

	UPROPERTY(EditAnywhere)
	FLinearColor StartColor;

	TArray<AHazePlayerCharacter> Players;
	TArray<USpotLightComponent> SpotLights;
	TArray<FDarkCaveGlowSpotLight> GlowLights;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Players = Game::Players;
		GetChildrenComponentsByClass(USpotLightComponent, true, SpotLights);

		for (USpotLightComponent SpotLight : SpotLights)
		{
			FDarkCaveGlowSpotLight LightData;
			LightData.Intensity = SpotLight.Intensity;
			LightData.SpotLight = SpotLight;
			GlowLights.Add(LightData);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float AddedIntensitMultiplier = 0.0;

		for (AHazePlayerCharacter Player : Players)
		{
			float PlayerDistance = Player.GetDistanceTo(Owner);
			float Multiplier = 1 - Math::Clamp(PlayerDistance / PlayerRadius, 0, PlayerRadius);

			AddedIntensitMultiplier += Multiplier;

			TArray<int> Indexes;
			if (Player.IsMio())
				Indexes = MioIndexes;
			else 
				Indexes = ZoeIndexes;

			for (int Index : Indexes)
			{
				SetColorParameterValueOnMaterialIndex(Index, n"EmissiveColor", StartColor * Multiplier * 2);
			}
		}

		AddedIntensitMultiplier /= 2;

		for (FDarkCaveGlowSpotLight& LightData : GlowLights)
		{
			LightData.SetMultipliedIntensity(AddedIntensitMultiplier);
		}
	}
}