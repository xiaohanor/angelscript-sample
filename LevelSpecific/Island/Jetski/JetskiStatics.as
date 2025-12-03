namespace Jetski
{
	UFUNCTION(BlueprintPure, DisplayName = "Get Jetski", Category = "Island|Jetski")
	AJetski BP_GetJetski(AHazePlayerCharacter Player)
	{
		return GetJetski(Player);
	}

	UFUNCTION(BlueprintPure, DisplayName = "Get Jetskis", Category = "Island|Jetski")
	void BP_GetJetskis(AJetski&out OutJetskiMio, AJetski&out OutJetskiZoe)
	{
		OutJetskiMio = GetJetski(Game::Mio);
		OutJetskiZoe = GetJetski(Game::Zoe);
	}

	AJetski GetJetski(EHazePlayer Player)
	{
		return Jetski::GetJetski(Game::GetPlayer(Player));
	}

	AJetski GetJetski(const AHazePlayerCharacter Player)
	{
		auto DriverComp = UJetskiDriverComponent::Get(Player);
		return DriverComp.GetOrCreateJetski();
	}

	UFUNCTION(BlueprintPure, Category = "Island|Jetski")
	AJetski GetOtherJetski(const AJetski Jetski)
	{
		return GetJetski(Jetski.Driver.OtherPlayer);
	}

	TPerPlayer<AJetski> GetJetskis()
	{
		TPerPlayer<AJetski> Jetskis;

		for(auto Player : Game::Players)
			Jetskis[Player] = GetJetski(Player);

		return Jetskis;
	}

	FVector GetJetskiCenterLocation()
	{
		const FVector MioLocation = Jetski::GetJetski(Game::Mio).ActorLocation;
		const FVector ZoeLocation = Jetski::GetJetski(Game::Zoe).ActorLocation;
		return (MioLocation + ZoeLocation) * 0.5;
	}

	AJetskiSpline GetJetskiSpline() 
	{
		return TListedActors<AJetskiSpline>().Single;
	}

	float GetRubberBandFactor(const AJetski Jetski)
	{
#if !RELEASE
		if(DevTogglesJetski::DisableRubberbanding.IsEnabled())
			return 0;
#endif

		// Are we currently ignoring the rubber banding at the current point on the spline?
		if(Jetski.JetskiSpline != nullptr)
		{
			TOptional<FAlongSplineComponentData> PreviousIgnoreRubberBandingComp = Jetski.JetskiSpline.Spline.FindPreviousComponentAlongSpline(UJetskiSplineIgnoreRubberBandingComponent, true, Jetski.GetDistanceAlongSpline());
			if(PreviousIgnoreRubberBandingComp.IsSet())
			{
				auto IgnoreRubberBandingComp = Cast<UJetskiSplineIgnoreRubberBandingComponent>(PreviousIgnoreRubberBandingComp.Value.Component);
				if(IgnoreRubberBandingComp != nullptr)
				{
					if(IgnoreRubberBandingComp.bIgnoreRubberBanding)
						return 0;
				}
			}
		}

		AJetski OtherJetski = Jetski::GetJetski(Jetski.Driver.OtherPlayer);
		if(OtherJetski == nullptr)
			return 0;

		// If the other jetski driver is dead, perform no rubberbanding
		if(OtherJetski.Driver.IsPlayerDead() || OtherJetski.Driver.IsPlayerRespawning())
			return 0;

		float DistanceAlongSpline = Jetski.GetDistanceAlongSpline();
		float OtherDistanceAlongSpline = OtherJetski.GetDistanceAlongSpline();

		float Diff = OtherDistanceAlongSpline - DistanceAlongSpline;

		const float AbsRubberBandFactor = Math::NormalizeToRange(Math::Abs(Diff), Jetski.Settings.MinRubberBandDistance, Jetski.Settings.MaxRubberBandDistance);

		return Math::Saturate(AbsRubberBandFactor) * Math::Sign(Diff);
	}

	// Instigator must be one of the jetskis to prevent too many channels in OceanWaves
	float GetWaveHeightAtLocation(FVector Location, FInstigator Instigator)
	{
		return Jetski::GetWaveData(Location, Instigator).PointOnWave.Z;
	}

	FVector GetWaveNormalAtLocation(FVector Location, FInstigator Instigator)
	{
		return Jetski::GetWaveData(Location, Instigator).PointOnWaveNormal;
	}

	FWaveData GetWaveData(FVector Location, FInstigator Instigator)
	{
		if(OceanWaves::HasOceanWavePaint())
		{
			OceanWaves::RequestWaveData(Instigator, Location);
			
			if(OceanWaves::IsWaveDataReady(Instigator))
			{
				return OceanWaves::GetLatestWaveData(Instigator);
			}
			else
			{
				FWaveData WaveData;
				WaveData.PointOnWave = FVector(Location.X, Location.Y, OceanWaves::GetOceanWavePaint().TargetLandscape.ActorLocation.Z);
				WaveData.PointOnWaveNormal = FVector::UpVector;
				return WaveData;
			}
		}

		FWaveData WaveData;
		WaveData.PointOnWave = Location;
		WaveData.PointOnWaveNormal = FVector::UpVector;
		return WaveData;
	}

	bool IsActive()
	{
		for(AJetski Jetski : Jetski::GetJetskis())
		{
			if(Jetski.IsActorDisabled())
				return false;
		}

		return true;
	}
}