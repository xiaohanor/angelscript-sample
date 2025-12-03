class UInitialBootAccessibilityPage : UInitialBootOptionsPage
{
	UPROPERTY(BindWidget)
	UOptionEnumWidget SpeakerType;
	
	UPROPERTY(BindWidget)
	UOptionEnumWidget Nightmode;

	UPROPERTY(BindWidget)
	UOptionTextWidget ObjectAudio;

	// UPROPERTY(BindWidget)
	// UOptionEnumWidget MenuNarration;

	bool bAllowNightMode = true;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		// EHazeAccessibilityState NarrationState = Online::GetAccessibilityState(EHazeAccessibilityFeature::MenuNarration);
		// if (NarrationState == EHazeAccessibilityState::GameTurnedOn || NarrationState == EHazeAccessibilityState::GameTurnedOff)
		// {
		// 	MenuNarration.Visibility = ESlateVisibility::Visible;
		// }
		// else
		// {
		// 	MenuNarration.Visibility = ESlateVisibility::Collapsed;
		// }

		Super::Construct();

		ObjectAudio.LabelText.ChangeText(NSLOCTEXT("Audio", "3DAudio", "3D Audio"));
		SpeakerType.OnOptionApplied.AddUFunction(this, n"OnSpeakerTypeChanged");
		Update3DAudioCapability();
		UpdateNightmode();
	}

	UFUNCTION()
	private void OnSpeakerTypeChanged(UOptionWidget Widget)
	{
		UpdateNightmode();
	}

	void Update3DAudioCapability()
	{
		if (Game::PlatformName == "Sage")
		{
			ObjectAudio.bIsFocusable = false;
			ObjectAudio.SetVisibility(ESlateVisibility::Hidden);
			return;
		}

		EAkChannelConfigType ConfigType = EAkChannelConfigType::Standard;
		int Channels = 0;
		FAkChannelMask Mask;
		bool bHeadphones = false;
		bool Has3DAudioButNoAvailableObjects = false;
		Audio::GetSpeakerConfiguration(ConfigType, Channels, Mask, bHeadphones, Has3DAudioButNoAvailableObjects);

		// Just to explain what can go on here.
		// First, user has enabled 3DAudio and it works as intended.
		// Second, user has enabled 3DAudio but has recieved ZERO objects to work with.
		// Third, user has enabled 3DAudio but has no AVAILABLE objects YET.
		// The second we can handle through Wwise, but the third we are at the
		// mercy of the platform... Seems very random when it starts working.
		// We notify the user at least!
		// NOTE: These issues mostly happen when changing audio device settings at RUNTIME.

		bAllowNightMode = ConfigType != EAkChannelConfigType::Objects;

		if (ConfigType == EAkChannelConfigType::Objects && !Has3DAudioButNoAvailableObjects)
		{
			ObjectAudio.ValueText.ChangeText(NSLOCTEXT("UHazeGameSettings", "Enabled", "Enabled"));
			ObjectAudio.LabelDescription = NSLOCTEXT("Audio", "3DAudio_Enabled_Desc", 
				"3D Audio is Enabled");
		}
		else
		{
			if (Has3DAudioButNoAvailableObjects)
			{
				ObjectAudio.ValueText.ChangeText(NSLOCTEXT("UHazeGameSettings", "Disabled", "Disabled"));
				ObjectAudio.LabelDescription = NSLOCTEXT("Audio", "3DAudio_Disabled_Desc", 
				"Currently in use by another process");
			}
			else 
			{
				ObjectAudio.ValueText.ChangeText(NSLOCTEXT("UHazeGameSettings", "NotAvailable", "Not Available"));
				ObjectAudio.LabelDescription = NSLOCTEXT("Audio", "3DAudio_NotAvailable_Desc", 
					"Audio device doesn't support 3D Audio");
			}
		}
	}

	void UpdateNightmode()
	{
		if (SpeakerType.Setting == nullptr)
			return;
		
		if (bAllowNightMode)
		{
			Nightmode.SetIsEnabled(true);
			Nightmode.bIsFocusable = true;
		}
		else
		{
			Nightmode.SetIsEnabled(false);
			Nightmode.bIsFocusable = false;
		}
	}
}