namespace SolarFlarePlayerCover
{
	USolarFlarePlayerCoverAudioManager GetAudioManager()
	{
		return USolarFlarePlayerCoverAudioManager::Get(TListedActors<ASolarFlareSun>().GetSingle());
	}

	UFUNCTION(BlueprintPure)
	float GetSolarFlareCoverAudioOcclusionValue()
	{
		ASolarFlareSun Sun = TListedActors<ASolarFlareSun>().GetSingle();
		if(!devEnsure(Sun != nullptr, f"GetCurrentCoverAudioOcclusionValue cannot be called in a level without ASolarFlareSun!"))
			return 0.0;

		return Sun.GetSolarFlareCoverAudioManager().GetCurrentCoverAudioOcclusionValue();		
	}

	UFUNCTION(BlueprintPure)
	void GetSolarFlarePlayerCoverAudioOcclusionValues(float&out MioOcclusion, float&out ZoeOcclusion)
	{
		ASolarFlareSun Sun = TListedActors<ASolarFlareSun>().GetSingle();
		if(!devEnsure(Sun != nullptr, f"GetPlayerCoverAudioAttenuationValues cannot be called in a level without ASolarFlareSun!"))
			return;

		MioOcclusion = Sun.GetSolarFlareCoverAudioManager().GetPlayerCoverAudioOcclusionValue(Game::GetMio());		
		ZoeOcclusion = Sun.GetSolarFlareCoverAudioManager().GetPlayerCoverAudioOcclusionValue(Game::GetZoe());
	}
}

class USolarFlarePlayerCoverAudioManager : UActorComponent
{
	access SolarFlarePlayerCover = private, USolarFlarePlayerCoverComponent;

	default TickGroup = ETickingGroup::TG_PostPhysics;
	default SetComponentTickEnabled(false);

	private TArray<USolarFlarePlayerCoverComponent> ActiveCovers;
	private TArray<USolarFlarePlayerComponent> PlayerSolarFlareComps;

	private float CurrentCoverOcclusionValue = 0.0;
	float GetCurrentCoverAudioOcclusionValue() const property
	{
		return CurrentCoverOcclusionValue;
	}

	private TPerPlayer<float> MinPlayerAttenuationValues;
	float GetPlayerCoverAudioOcclusionValue(AHazePlayerCharacter Player) const property
	{
		return MinPlayerAttenuationValues[Player];
	}

	private TArray<USolarFlarePlayerComponent> GetPlayerSolarFlareComps()
	{
		if(PlayerSolarFlareComps.Num() == 0)
		{
			for(auto Player : Game::GetPlayers())
			{
				PlayerSolarFlareComps.Add(USolarFlarePlayerComponent::Get(Player));
			}

		}

		return PlayerSolarFlareComps;
	}

	access:SolarFlarePlayerCover void RegisterCover(USolarFlarePlayerCoverComponent CoverComp)
	{
		ActiveCovers.Add(CoverComp);
		SetComponentTickEnabled(true);
	}

	access:SolarFlarePlayerCover void UnRegisterCover(USolarFlarePlayerCoverComponent CoverComp)
	{
		ActiveCovers.RemoveSingleSwap(CoverComp);

		const bool bShouldTick = ActiveCovers.Num() > 0;
		SetComponentTickEnabled(bShouldTick);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto Players = Game::Players;
		
		// Reset tracked player values
		if(Players.IsEmpty())
			return;

		MinPlayerAttenuationValues[Players[0]] = 1.0;
		MinPlayerAttenuationValues[Players[1]] = 1.0;

		float NewCoverOcclusionValue = 0.0;

		bool bAnyPlayerOutsideCoverVolumes = false;

		// First check cover volumes
		for(auto SolarFlareComp : GetPlayerSolarFlareComps())
		{
			const bool bPlayerInCoverVolume = SolarFlareComp.OverlapCoverComps.Num() > 0;
			if(!bPlayerInCoverVolume)
			{
				bAnyPlayerOutsideCoverVolumes = true;			
			}

			for(auto& VolumeOverlapComp : SolarFlareComp.OuterOverlapComps)
			{
				auto Player = Cast<AHazePlayerCharacter>(SolarFlareComp.GetOwner());
				float OutOverlapValue = 1.0;
				VolumeOverlapComp.GetCoverOverlapPlayerAudioAttenuationValues(Player, OutOverlapValue);				
				MinPlayerAttenuationValues[Player] = Math::Min(MinPlayerAttenuationValues[Player], OutOverlapValue);				
			}
		}

		if(bAnyPlayerOutsideCoverVolumes)
		{
			// Then check individual covers
			for(auto& CoverComp : ActiveCovers)
			{
				TPerPlayer<float> CoverValues;
				CoverValues[Players[0]] = 1.0;
				CoverValues[Players[1]] = 1.0;

				CoverComp.GetPlayerCoverAudioAttenuationValues(CoverValues);

				for(auto& Player : Players)
				{
					MinPlayerAttenuationValues[Player] = Math::Min(MinPlayerAttenuationValues[Player], CoverValues[Player]);
				}
			}

		}

		for(auto& Player : Players)
		{
			NewCoverOcclusionValue = Math::Max(NewCoverOcclusionValue, MinPlayerAttenuationValues[Player]);
		}

		CurrentCoverOcclusionValue = NewCoverOcclusionValue;
	}
}