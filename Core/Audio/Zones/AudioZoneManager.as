struct FVoGameAuxSendVolumeData
{
	UPROPERTY()
	AHazePlayerCharacter Player = nullptr;

	// In dB
	UPROPERTY()
	float GameAuxVolume = 0;

	// In dB
	UPROPERTY()
	float UserAuxVolume0 = 0;

	UPROPERTY()
	UHazeAudioActorMixer AmixOverride = nullptr;

	bool bRequiresReset = true;

	FVoGameAuxSendVolumeData(AHazePlayerCharacter InPlayer, float InGamAuxVolume, float InUserAuxVolume, UHazeAudioActorMixer InAmix) 
	{
		Player = InPlayer;
		GameAuxVolume = InGamAuxVolume;
		UserAuxVolume0 = InUserAuxVolume;
		AmixOverride = InAmix;
	}
}

class UAudioZoneManager : UHazeAudioZoneManager
{
	UPROPERTY()
	UHazeAudioActorMixer DefaultVoAmix = nullptr;

	UPROPERTY()
	TArray<UHazeAudioBus> PlayerDefaultVoBuses;

	private TArray<FVoGameAuxSendVolumeData> PlayerVoGameAuxSendVolumes;
	// There will always be a minium of two, but there can be OVERRIDES!
	default PlayerVoGameAuxSendVolumes.SetNum(2);
	private bool bGameAuxSendRequiresReset = false;

	UFUNCTION(BlueprintOverride)
	void Initialize()
	{
		auto GameInstance = Game::GetHazeGameInstance();

		DefaultVoAmix = GameInstance.GlobalAudioDataAsset.DefaultVoAmixForGameAuxVolume;

		// Setup the default buses
		PlayerDefaultVoBuses.SetNum(2);
		PlayerDefaultVoBuses[EHazePlayer::Mio] = GameInstance.GlobalAudioDataAsset.DefaultMioVoBusForUserAuxVolume;
		PlayerDefaultVoBuses[EHazePlayer::Zoe] = GameInstance.GlobalAudioDataAsset.DefaultZoeVoBusForUserAuxVolume;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Zones and ReverbComponents are processed seperately

		if (bGameAuxSendRequiresReset)
		{
			PlayerVoGameAuxSendVolumes.SetNum(2);
			for (auto& Data : PlayerVoGameAuxSendVolumes)
			{
				if (Data.bRequiresReset)
				{
					// If the player is nullptr, it's been removed and any volume changed will have been removed with the emitter.
					// devCheck(Data.Player != nullptr, "AudioZoneManager must have a player reference when resetting VO GameAuxSendValues the values!");
					Data.GameAuxVolume = 0;
					Data.UserAuxVolume0 = 0;
				}
			}
		}

		for (AHazeAudioZone Zone : ActiveZones)
		{
			Process(Zone, PlayerVoGameAuxSendVolumes);
		}

		for (const auto& Data : PlayerVoGameAuxSendVolumes)
		{
			if (Data.Player == nullptr)
				continue;

			auto PlayerVoEmitter = Audio::GetPlayerVoEmitter(Data.Player);
			auto ActorMixer = Data.AmixOverride != nullptr ? Data.AmixOverride : DefaultVoAmix;

			if (ActorMixer != nullptr)
				PlayerVoEmitter.SetNodeProperty(ActorMixer, EHazeAudioNodeProperty::GameAuxSendVolume, Data.GameAuxVolume);

			auto Bus = PlayerDefaultVoBuses[Data.Player.Player];
			if (Bus != nullptr)
				PlayerVoEmitter.SetNodeProperty(Bus, EHazeAudioNodeProperty::UserAuxSendVolume0, Data.UserAuxVolume0);
		}

		for	(UHazeAudioReverbComponent Component : ProcessingQueue)
		{
			Process(Component);
		}

		ProcessingQueue.Reset();
	}

	void Process(AHazeAudioZone Zone, TArray<FVoGameAuxSendVolumeData>& VoGameAuxVolumes)
	{
		if (Zone.ZoneType == EHazeAudioZoneType::Portal)
			return;

		if (Zone.Priority == 0)
		{
			float RtpcValue = Zone.GetZonesListenerRelevance();
			Zone.SetZoneRTPC(RtpcValue, 0);
			return;
		}

		float FinalRelevance = 0.0;
		float RelevanceWithOverridePowerOf = 0;
		float OverrideZoneRtpcPowerOf = 0;

		// Track if both cameras are in water
		if (Zone.ZoneType == EHazeAudioZoneType::Ambience)
		{
			float32 RtpcValue = 0;
			AudioComponent::GetCachedGlobalRTPC(Rtpc_CamerasInWaterAudioID, RtpcValue);
			if (RtpcValue == 2.f)
			{
				Zone.SetZoneRTPC(FinalRelevance, OverrideZoneRtpcPowerOf);
				return;
			}
		}
		
		float ZonePanning = .5;

		// Process relevance, affected by previous ambient zones
		for (auto ListenerOverlap : Zone.ListenerOverlaps)
		{
			auto ReverbComponent = Cast<UHazeAudioReverbComponent>(ListenerOverlap.Object);
			auto PrioritizedZone = ReverbComponent
				.GetPrioritizedZone();

			bool bLowerRelevance = PrioritizedZone != Zone;

			float Relevance = ListenerOverlap.ObjectRelevance * Zone.GetZoneRelevance();

			if (bLowerRelevance)
			{
				Relevance =
					Math::Clamp(Relevance * GetLowerPrioReverbSendValue(Zone, ReverbComponent), 0.0, 1.0);
			}

			FinalRelevance = Math::Max(Relevance, FinalRelevance);

			if (ListenerOverlap.RTPCCurvePowerOverride != 0 && FinalRelevance == Relevance)
			{
				RelevanceWithOverridePowerOf = Relevance;
				OverrideZoneRtpcPowerOf = ListenerOverlap.RTPCCurvePowerOverride;
			}

			auto Player = Cast<AHazePlayerCharacter>(ListenerOverlap.Object.Listener.Owner);
			if (Player == nullptr)
				continue;

			ApplyGameAuxVolumeForVO(Zone, Player, VoGameAuxVolumes, Relevance);

			if (Zone.ZoneType != EHazeAudioZoneType::Ambience)
				continue;

			ZonePanning += Relevance * 0.5 * (Player.IsZoe() ? 1 : -1);
		}

		if (RelevanceWithOverridePowerOf != FinalRelevance)
			OverrideZoneRtpcPowerOf = 0;

		Zone.SetZoneRTPC(FinalRelevance, OverrideZoneRtpcPowerOf);

		if (Zone.ZoneType != EHazeAudioZoneType::Ambience)
			return;

		auto AmbientZone = Cast<AAmbientZone>(Zone);

		AmbientZone.UpdatePanning(ZonePanning);
	}

	void ApplyGameAuxVolumeForVO(AHazeAudioZone Zone, AHazePlayerCharacter Player, TArray<FVoGameAuxSendVolumeData>& VoGameAuxVolumes, const float& Relevance)
	{
		if (Zone.ZoneType != EHazeAudioZoneType::Ambience &&
			Zone.ZoneType != EHazeAudioZoneType::Reverb)
			return;

		float VoGameAuxVolume = 0;
		float VoUserAuxVolume = 0;
		UHazeAudioActorMixer AmixOverride = nullptr;
		AudioZone::GetVoGameAuxVolumeValues(Zone, VoGameAuxVolume, VoUserAuxVolume, AmixOverride);

		if (VoGameAuxVolume == 0 && VoUserAuxVolume == 0)
			return;

		bGameAuxSendRequiresReset = true;

		if (AmixOverride != nullptr)
		{
			VoGameAuxVolumes.Add(FVoGameAuxSendVolumeData(Player, VoGameAuxVolume * Relevance, VoUserAuxVolume * Relevance, AmixOverride));
		}
		else
		{
			auto& Data = VoGameAuxVolumes[Player.Player];
			Data.Player = Player;
			Data.GameAuxVolume += VoGameAuxVolume * Relevance;
			Data.UserAuxVolume0 += VoUserAuxVolume * Relevance;
			Data.bRequiresReset = true;
		}
	}

	TSet<UHazeAudioAuxBus> ProcessedBusses;
	float PreviousReverbSends = 0;
	float CurrentZonesRelevences = 0;

	private void ProcessZone(
		UHazeAudioReverbComponent ReverbComponent,
		const FHazeAudioZoneOverlap& OverlappedZone,
		AHazeAudioZone Zone)
	{
		float ObjectSendLevel = OverlappedZone.AttenuationDistance * OverlappedZone.ZoneRelevance;
		// Calculating reverb send values based on current zones per AudioComponent
		float SendLevelMultiplier = Zone.InternalGetSendLevel();

		auto ZoneReverbBus = Zone.InternalGetReverbAuxBus();
		bool bIgnoreReverbSend = ProcessedBusses.Contains(ZoneReverbBus);
		float AttenuatedReverbSendValue = OverlappedZone.DistanceToZone != -1 ? 1 - Math::Clamp(PreviousReverbSends, 0, 1) : 1;

		// Environment - This is reset EVERYTIME the component is processed for updates (See Process below)
		float ObjectEnvironmentRelevance = Math::Clamp(ObjectSendLevel * AttenuatedReverbSendValue, 0, 1);
		float32 EnvironmentsRelevence = 0;
		if (!ReverbComponent.OverlappedEnvironmentsRelevances.Find(Zone.EnvironmentType, EnvironmentsRelevence)
			|| ObjectEnvironmentRelevance > EnvironmentsRelevence)
		{
			ReverbComponent.OverlappedEnvironmentsRelevances.FindOrAdd(Zone.EnvironmentType) = float32(ObjectEnvironmentRelevance);
		}
		//

		// Reverb
		if (bIgnoreReverbSend)
			return;

		CurrentZonesRelevences += ObjectEnvironmentRelevance;
		ProcessedBusses.Add(ZoneReverbBus);
		float FinalSendValue = Math::Clamp((ObjectEnvironmentRelevance * SendLevelMultiplier), 0, 1);

		ReverbComponent.UpdateObjectAuxSendValue(ZoneReverbBus, FinalSendValue);
	}

	private void Process(UHazeAudioReverbComponent ReverbComponent)
	{
		auto AudioComponent = ReverbComponent;
		if (AudioComponent == nullptr)
			return;

		if (AudioComponent.ConnectedObjects.Num() == 0)
			return;

		AudioComponent.OverlappedEnvironmentsRelevances.Reset();
		if (AudioComponent.ZoneOverlaps.Num() == 0)
			return;

		PreviousReverbSends = 0;
		CurrentZonesRelevences = 0;
		ProcessedBusses.Reset();

		int PreviousPriority = -1;
		for (int i=ReverbComponent.ZoneOverlaps.Num()-1; i >= 0; --i)
		{
			auto Overlap = ReverbComponent.ZoneOverlaps[i];
			auto Zone = Overlap.Zone;

			if(Zone == nullptr)
				continue;

			if (!Zone.EnsureReverbReady())
				break;

			if (Zone.Priority == 0)
				break;

			if (PreviousPriority != Zone.Priority)
			{
				PreviousReverbSends += CurrentZonesRelevences;
				CurrentZonesRelevences = 0;

				PreviousPriority = Zone.Priority;
			}

			ProcessZone(ReverbComponent, Overlap, Zone);
		}

		ReverbComponent.SetAuxSendValue();
	}

	private bool GetRelevanceToAdd(
		AHazeAudioZone Zone,
		const FHazeAudioZoneOverlap& OverlappedZone,
		UHazeAudioReverbComponent ReverbComponent,
		const bool& bIgnoreWaterZones,
		const bool& bIgnoreReverbZones,
		float& RelevanceToAdd)
	{
		if(OverlappedZone.Zone == nullptr || !OverlappedZone.Zone.EnsureReverbReady() || OverlappedZone.Zone == Zone)
			return false;

		if (bIgnoreWaterZones && OverlappedZone.Zone.ZoneType == EHazeAudioZoneType::Water)
			return false;

		if (bIgnoreReverbZones && OverlappedZone.Zone.ZoneType == EHazeAudioZoneType::Reverb)
			return false;

		if(Zone.ZonePriority >= OverlappedZone.ZonePriority)
			return false;

		RelevanceToAdd = OverlappedZone.AttenuationDistance * OverlappedZone.ZoneRelevance;
		return true;
	}

	const FHazeAudioID Rtpc_CamerasInWaterAudioID = FHazeAudioID("Rtpc_Shared_Camera_InWater");

	float GetLowerPrioReverbSendValue(AHazeAudioZone Zone, UHazeAudioReverbComponent ReverbComponent)
	{
		float SendReductionValue = 0;

		bool bIgnoreReverbZones = Zone.ZoneType == EHazeAudioZoneType::Ambience;
		bool bIgnoreWaterZones = Zone.ZoneType == EHazeAudioZoneType::Ambience;

		for (int i=ReverbComponent.ZoneOverlaps.Num()-1; i >= 0; --i)
		{
			auto Overlap = ReverbComponent.ZoneOverlaps[i];

			float Relevance = 0;
			if (!GetRelevanceToAdd(Zone, Overlap, ReverbComponent, bIgnoreWaterZones, bIgnoreReverbZones, Relevance))
				continue;

			SendReductionValue += Relevance;
		}

		return 1.0 - Math::Clamp(SendReductionValue, 0.0, 1.0);
	}

}
