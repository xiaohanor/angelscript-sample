enum ESkylineHighwayRingLightMode
{
	NoShadows,
	ShadowCasting,
	Off
}

class ASkylineHighwayRing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	TArray<ULightComponent> NoShadows;
	TArray<ULightComponent> ShadowCasting;

	TInstigated<ESkylineHighwayRingLightMode> LightMode;
	default LightMode.DefaultValue = ESkylineHighwayRingLightMode::NoShadows;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<ULightComponent> Lights;
		GetComponentsByClass(Lights);
		for (auto Light : Lights)
		{
			if (Light.CastShadows)
				ShadowCasting.Add(Light);
			else
				NoShadows.Add(Light);
		}

		UpdateLightMode();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto CurrentInstigator = LightMode.CurrentInstigator;

		TListedActors<ASkylineHighwayRingLightModeZone> LightModeZones;
		for (auto LightModeZone : LightModeZones)
		{
			if (Math::IsPointInBoxWithTransform(ActorLocation, LightModeZone.BoxComp.WorldTransform, LightModeZone.BoxComp.BoxExtent))
				LightMode.Apply(LightModeZone.LightMode, LightModeZone, LightModeZone.Priority);
			else
				LightMode.Clear(LightModeZone);
		}

		if (CurrentInstigator != LightMode.CurrentInstigator)
			UpdateLightMode();
	}

	void UpdateLightMode()
	{
//		PrintToScreen("LightMode Update", 1.0, FLinearColor::Green);

		switch (LightMode.Get())
		{
			case ESkylineHighwayRingLightMode::NoShadows:
			{
				for (auto Light : NoShadows)
					Light.SetVisibility(true);

				for (auto Light : ShadowCasting)
					Light.SetVisibility(false);

				return;
			}
			case ESkylineHighwayRingLightMode::ShadowCasting:
			{
				for (auto Light : NoShadows)
					Light.SetVisibility(false);

				for (auto Light : ShadowCasting)
					Light.SetVisibility(true);

				return;
			}
			case ESkylineHighwayRingLightMode::Off:
			{
				for (auto Light : NoShadows)
					Light.SetVisibility(false);

				for (auto Light : ShadowCasting)
					Light.SetVisibility(false);

				return;
			}
		}
	}
};