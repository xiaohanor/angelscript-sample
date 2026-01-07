
namespace Audio
{
	const FHazeAudioID Rtpc_MasterVolume = FHazeAudioID("Rtpc_Menu_Volume_Master");
	const FHazeAudioID Rtpc_VoiceVolume = FHazeAudioID("Rtpc_Menu_Volume_VO");
	const FHazeAudioID Rtpc_MusicVolume = FHazeAudioID("Rtpc_Menu_Volume_Music");
	const FHazeAudioID Rtpc_SfxVolume = FHazeAudioID("Rtpc_Menu_Volume_SFX");

	const FHazeAudioID Rtpc_SpeakerSettings_DynamicRange = FHazeAudioID("Rtpc_SpeakerSettings_DynamicRange");
	const FHazeAudioID Rtpc_SpeakerSettings_SpeakerType = FHazeAudioID("Rtpc_SpeakerSettings_SpeakerType");
	const FHazeAudioID Rtpc_SpeakerSettings_ChannelAmount = FHazeAudioID("Rtpc_SpeakerSettings_ChannelAmount");
	const FHazeAudioID Rtpc_SpeakerSettings_Nightmode = FHazeAudioID("Rtpc_SpeakerSettings_Nightmode");
	const FHazeAudioID Rtpc_SpeakerSettings_ObjectsActive = FHazeAudioID("Rtpc_SpeakerSettings_ObjectsActive");

	const FHazeAudioID Rtpc_SpeakerPanning_FR = FHazeAudioID("Rtpc_SpeakerPanning_FR");
	const FHazeAudioID Rtpc_SpeakerPanning_LR = FHazeAudioID("Rtpc_SpeakerPanning_LR");
	const FHazeAudioID Rtpc_Spatialization_SpeakerPanning_Mix = FHazeAudioID("Rtpc_Shared_Spatialization_SpeakerPanning_Mix");
}

class UHazeAudioDefaultMenuSettings : UHazeAudioDefaultMenuSettingsBase
{
	UFUNCTION(BlueprintOverride)
	void GetDefaultValues()
	{
		// Default for all volumes are 0 - 1.
		// Update them here if needed VolumeMasterMinValue etc.

		VolumeVoiceMaxValue = 2;

		VolumeMasterMaxValue = 11;

		if (Game::PlatformName == "Sage")
		{
			SpeakerType = EHazeAudioSpeakerType::TV;
		}
		else
		{
			SpeakerType = EHazeAudioSpeakerType::Speakers;
		}

		DynamicRange = EHazeAudioDynamicRange::High;

		EAkChannelConfigType ConfigType = EAkChannelConfigType::Standard;
		int Channels = 0;
		FAkChannelMask Mask;
		bool bHeadphones = false;
		bool Has3DAudioButNoAvailableObjects = false;
		Audio::GetSpeakerConfiguration(ConfigType, Channels, Mask, bHeadphones, Has3DAudioButNoAvailableObjects);
		
		if (Channels == 2 || bHeadphones)
			ChannelSetup = EHazeAudioChannelSetup::Stereo;
		else if (Channels >= 6 || ConfigType == EAkChannelConfigType::Objects)
			ChannelSetup = EHazeAudioChannelSetup::Surround;
	}
}

event void FOnPostSpeakerConfigUpdates();

// 游戏设置的核心单例类。负责管理所有游戏设置的逻辑状态，处理 Wwise 音频 RTPC 参数的应用，以及根据不同平台（如 PC, Console, Sage）加载特定的默认配置。它是 UI 和底层引擎参数之间的桥梁。
class UGameSettingsApplicator: UHazeGameSettingsApplicatorBase
{
	TArray<EHazeAudioDynamicRange> SettingsToDynamicRange;
	// Speakers
	default SettingsToDynamicRange.Add(EHazeAudioDynamicRange::High);
	default SettingsToDynamicRange.Add(EHazeAudioDynamicRange::Medium);
	default SettingsToDynamicRange.Add(EHazeAudioDynamicRange::Medium);
	// TV
	default SettingsToDynamicRange.Add(EHazeAudioDynamicRange::Medium);
	default SettingsToDynamicRange.Add(EHazeAudioDynamicRange::Medium);
	default SettingsToDynamicRange.Add(EHazeAudioDynamicRange::Low);
	// Headphones
	default SettingsToDynamicRange.Add(EHazeAudioDynamicRange::High);
	default SettingsToDynamicRange.Add(EHazeAudioDynamicRange::High);
	default SettingsToDynamicRange.Add(EHazeAudioDynamicRange::High);

	// TODO (GK) - Remove legacy settings.

	UPROPERTY(BlueprintReadOnly)
	EHazeAudioDynamicRange CurrentDynamicRange = EHazeAudioDynamicRange(-1);

	UPROPERTY(BlueprintReadOnly)
	EHazeAudioSpeakerType CurrentSpeakerType = EHazeAudioSpeakerType(-1);
	float CurrentSpeakerRtpcValue = -1;

	UPROPERTY(BlueprintReadOnly)
	EHazeAudioChannelSetup CurrentChannelConfig = EHazeAudioChannelSetup(-1);

	UPROPERTY(BlueprintReadOnly)
	bool bCurrentNightmodeSetting = false;

	UPROPERTY(BlueprintReadOnly)
	bool bCurrentStreamerModeSetting = false;

	UPROPERTY(EditAnywhere)
	int32 DynamicRangeRtpcInterpolationMs = 0;

	UPROPERTY(EditAnywhere)
	int32 SpeakerTypeRtpcInterpolationMs = 0;

	UPROPERTY(EditAnywhere)
	int32 ChannelConfigRtpcInterpolationMs = 250;

	bool bSettingsLoaded = false;
	bool bOverrideToTvAndNightmode = false;

	FOnPostSpeakerConfigUpdates PostSpeakerConfigUpdates;

	private bool bObjectsActive = false;

	UFUNCTION(BlueprintOverride)
	void OnSpeakerConfigUpdates()
	{
		// Will be run after the BP has done it's updates.
		if (PostSpeakerConfigUpdates.IsBound())
			PostSpeakerConfigUpdates.Broadcast();
	}

	// We decided to not include this, since it can override certain users that's made an active choice.
	// UFUNCTION(BlueprintOverride)
	// void OnHandheldUpdate(bool bIsConsole)
	// {
	// 	bOverrideToTvAndNightmode = !bIsConsole;

	// 	if (bSettingsLoaded)
	// 	{
	// 		UpdateNightmode();
	// 	}
	// }

	UFUNCTION(BlueprintCallable)
	void SetObjectsActiveRtpc(bool bActive)
	{
		bObjectsActive = bActive;
		AudioComponent::SetGlobalRTPC(Audio::Rtpc_SpeakerSettings_ObjectsActive, bActive ? 1 : 0, 0);
	}

	UFUNCTION(BlueprintOverride)
	void Initialize()
	{
		OnSpeakerConfigUpdates();
		// Settings can't be loaded before initialize.
		bSettingsLoaded = true;
		
		#if EDITOR
		// Audio departments doesn't want any modified volume options, if any ONLY TEMP!
		// So ignore volume changes made by previous users or UXR testers.
		if (AudioUtility::IsWaapiConnected())
		{
			GameSettings::SetGameSettingsValue(n"MasterVolume", "11");
			GameSettings::SetGameSettingsValue(n"VoiceVolume", "1");
			GameSettings::SetGameSettingsValue(n"MusicVolume", "1");
		}
		#endif
	}

	UFUNCTION(BlueprintCallable)
	void UpdateAudioDeviceDefaults(
		EHazeAudioSpeakerType SpeakerType,
		EHazeAudioChannelSetup Channels,
		EHazeAudioDynamicRange DynamicRange)
	{
		// NOTE: We only update those that have the default value set.
		//		 The default value will be changed to In params.

		SaveAudioSetting(SpeakerType);
		// SaveAudioSetting(Channels);
		// SaveAudioSetting(DynamicRange);

		ApplyAudioChannelSetupSettings(Channels);
	}
	
	void ChangeDefaultSettingIfDefaultSet(const FName& SettingsName, const FString& Value)
	{
		UHazeGameSettingBase Settings;
		GameSettings::GetGameSettingsDescription(SettingsName, Settings);

		// if settings hasn't been loaded yet we can't compare...
		if (bSettingsLoaded)
		{
			FString CurrentValue;
			GameSettings::GetGameSettingsValue(SettingsName, CurrentValue);

			if (CurrentValue != Settings.DefaultValue)
				return;
		}

		// UpdateDefault does all checks internally.
		Settings.UpdateDefault(Value);
		// We don't need to save the value, since it's still just a default value.
		// GameSettings::SetGameSettingsValue(SettingsName, Value);
	}

	void SaveAudioSetting(EHazeAudioSpeakerType SpeakerType)
	{
		if (CurrentSpeakerType == SpeakerType)
			return;

		FString Value;

		switch(SpeakerType)
		{
			case EHazeAudioSpeakerType::Speakers:
			Value = "Speakers";
			break;
			case EHazeAudioSpeakerType::TV:
			Value = "TV";
			break;
			case EHazeAudioSpeakerType::Headphones:
			Value = "Headphones";
			break;
		}

		ChangeDefaultSettingIfDefaultSet(n"AudioSpeakerType", Value);
	}

	void SaveAudioSetting(EHazeAudioChannelSetup Channels)
	{
		if (CurrentChannelConfig == Channels)
			return;

		FString Value;

		switch(Channels)
		{
			case EHazeAudioChannelSetup::Stereo:
			Value = "Stereo";
			break;
			case EHazeAudioChannelSetup::Surround:
			Value = "Surround";
			break;
		}

		ChangeDefaultSettingIfDefaultSet(n"AudioChannelSetup", Value);
	}

	void SaveAudioSetting(EHazeAudioDynamicRange DynamicRange)
	{
		if (CurrentDynamicRange == DynamicRange)
			return;

		FString Value;

		switch(DynamicRange)
		{
			case EHazeAudioDynamicRange::Low:
			Value = "Low";
			break;
			case EHazeAudioDynamicRange::Medium:
			Value = "Medium";
			break;
			case EHazeAudioDynamicRange::High:
			Value = "High";
			break;
		}

		ChangeDefaultSettingIfDefaultSet(n"AudioDynamicRange", Value);
	}


	EHazeAudioDynamicRange GetValidDynamicRangeBasedOnSpeakerType(EHazeAudioSpeakerType SpeakerType, EHazeAudioDynamicRange Current) 
	{
		int Index = int(SpeakerType) * int(EHazeAudioSpeakerType::EHazeAudioSpeakerType_MAX) + int(Current);

		if (SettingsToDynamicRange.IsValidIndex(Index))
			return SettingsToDynamicRange[Index];

		return EHazeAudioDynamicRange::High;
	}

	UFUNCTION(BlueprintOverride)
	bool ApplyAudioSpeakerTypeSettings(EHazeAudioSpeakerType SpeakerType)
	{
		auto CurrentSpeakerSetting = float(SpeakerType);

		if (bOverrideToTvAndNightmode)
		{
			// Force it to be TV with Nightmode.
			CurrentSpeakerSetting = 4;
		}
		else if (IsNightmodeEnabled())
		{
			switch(SpeakerType)
			{
				case EHazeAudioSpeakerType::Speakers:
				case EHazeAudioSpeakerType::Headphones:
				CurrentSpeakerSetting = 3;
				break;
				case EHazeAudioSpeakerType::TV:
				CurrentSpeakerSetting = 4;
				break;
			}
		}
		
		if(CurrentSpeakerSetting != CurrentSpeakerRtpcValue)
		{
			CurrentSpeakerRtpcValue = CurrentSpeakerSetting;
			AudioComponent::SetGlobalRTPC(Audio::Rtpc_SpeakerSettings_SpeakerType, CurrentSpeakerSetting, SpeakerTypeRtpcInterpolationMs);

			EHazeAudioPanningRule Panning = 
				SpeakerType == EHazeAudioSpeakerType::Headphones ? 
				EHazeAudioPanningRule::Headphones : 
				EHazeAudioPanningRule::Speakers;

			CurrentSpeakerType = SpeakerType;
			// Note: Updates all emitters with the panning rtpc and wwise panning rule
			Audio::SetPanningRule(Panning);

			EHazeAudioDynamicRange NewDynamicRange = GetValidDynamicRangeBasedOnSpeakerType(SpeakerType, CurrentDynamicRange);
			ApplyAudioDynamicRangeSettings(NewDynamicRange);
		}

		// We no longer block any changes to speaker type.
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ApplyAudioChannelSetupSettings(EHazeAudioChannelSetup ChannelType)
	{
		if(ChannelType != CurrentChannelConfig)
		{
			AudioComponent::SetGlobalRTPC(Audio::Rtpc_SpeakerSettings_ChannelAmount, float(ChannelType), ChannelConfigRtpcInterpolationMs);
			CurrentChannelConfig = ChannelType;
		}

		return ChannelType == CurrentChannelConfig;
	}

	UFUNCTION(BlueprintOverride)
	bool ApplyAudioDynamicRangeSettings(EHazeAudioDynamicRange DynamicRange)
	{
		if(DynamicRange != CurrentDynamicRange)
		{
			EHazeAudioDynamicRange ValidValue = GetValidDynamicRangeBasedOnSpeakerType(CurrentSpeakerType, DynamicRange);
			AudioComponent::SetGlobalRTPC(Audio::Rtpc_SpeakerSettings_DynamicRange, float(ValidValue), DynamicRangeRtpcInterpolationMs);
			CurrentDynamicRange = ValidValue;
		}

		return DynamicRange == CurrentDynamicRange;
	}

	UFUNCTION(BlueprintOverride)
	bool ApplyAudioMasterVolume(float Value)
	{
		AudioComponent::SetGlobalRTPC(Audio::Rtpc_MasterVolume, Value);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ApplyAudioVoiceVolume(float Value)
	{
		AudioComponent::SetGlobalRTPC(Audio::Rtpc_VoiceVolume, Value);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ApplySoundEffectVolume(float Value)
	{
		AudioComponent::SetGlobalRTPC(Audio::Rtpc_SfxVolume, Value);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ApplyAudioMusicVolume(float Value)
	{
		AudioComponent::SetGlobalRTPC(Audio::Rtpc_MusicVolume, Value);
		return true;
	}

	bool IsNightmodeEnabled() const
	{
		bool bCanBeEnabled = !bObjectsActive && (bOverrideToTvAndNightmode || bCurrentNightmodeSetting || bCurrentStreamerModeSetting);

		return bCanBeEnabled;
	}

	void UpdateNightmode()
	{
		bool bIsEnabled = IsNightmodeEnabled();
		
		if (bIsEnabled)
			AudioComponent::SetGlobalRTPC(Audio::Rtpc_SpeakerSettings_Nightmode, 1);
		else
			AudioComponent::SetGlobalRTPC(Audio::Rtpc_SpeakerSettings_Nightmode, 0);

		ApplyAudioSpeakerTypeSettings(CurrentSpeakerType);

	}

	UFUNCTION(BlueprintOverride)
	bool ApplyNightmode(bool bEnabled)
	{
		bCurrentNightmodeSetting = bEnabled;
		UpdateNightmode();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ApplyStreamerMode(bool bEnabled)
	{
		bCurrentStreamerModeSetting = bEnabled;
		UpdateNightmode();

		return true;
	}
	
	bool HasStreamerMode() const 
	{
		return bCurrentStreamerModeSetting;
	}
}