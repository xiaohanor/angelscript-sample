
class UGraphicsOptionsMenuPage : UOptionsMenuPage
{
	default bShowUnblurredGameInBackground = true;

	UPROPERTY(BindWidget)
	UOptionEnumWidget WindowModeOption;
	UPROPERTY(BindWidget)
	UOptionEnumWidget ResolutionOption;
	UPROPERTY(BindWidget)
	UOptionEnumWidget HDROption;
	UPROPERTY(BindWidget)
	UOptionTextWidget HDRNotDisplayed;
	UPROPERTY(BindWidget)
	UOptionButtonWidget ApplyResolutionButton;

	UPROPERTY(BindWidget)
	UOptionEnumWidget UpscalingOption;
	UPROPERTY(BindWidget)
	UOptionSliderWidget ResolutionScaleOption;
	UPROPERTY(BindWidget)
	UOptionEnumWidget DLSSQualityOption;
	UPROPERTY(BindWidget)
	UOptionEnumWidget TSRQualityOption;
	UPROPERTY(BindWidget)
	UOptionEnumWidget FSRQualityOption;

	UPROPERTY(BindWidget)
	UOptionEnumWidget VSyncOption;

	FString OriginalResolution;
	FString OriginalWindowMode;

	float ResolutionRevertTimer = -1.0;
	float PokeRenderTargetTimer = -1.0;
	FString PokeVSyncValue;

	// Only show graphics tab on PC
	bool ShouldShowPageOnCurrentPlatform() const override
	{
		return !Game::IsConsoleBuild();
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		Super::Construct();
		OriginalResolution = ResolutionOption.CurrentValue;
		OriginalWindowMode = WindowModeOption.CurrentValue;

		ApplyResolutionButton.OnClicked.AddUFunction(this, n"OnApplyResolution");

		HDRNotDisplayed.LabelText.ChangeText(HDROption.LabelText.Text);
		HDRNotDisplayed.ValueText.ChangeText(NSLOCTEXT("HDRSetting", "HDRNotAvailable", "Not Available"));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		// Only show the resolution option if window mode is fullscreen
		if (WindowModeOption.CurrentValue == "Fullscreen")
		{
			ResolutionOption.Visibility = ESlateVisibility::Visible;
		}
		else
		{
			if (ResolutionOption.bFocused)
				Widget::SetAllPlayerUIFocus(WindowModeOption);
			ResolutionOption.Visibility = ESlateVisibility::Collapsed;
		}

		// Only show the apply resolution button if we've changed resolution
		bool bHasChangedResolution = false;
		if ((OriginalResolution != ResolutionOption.CurrentValue && WindowModeOption.CurrentValue == "Fullscreen")
			|| OriginalWindowMode != WindowModeOption.CurrentValue)
			bHasChangedResolution = true;

		if (bHasChangedResolution)
			ApplyResolutionButton.Visibility = ESlateVisibility::Visible;
		else
			ApplyResolutionButton.Visibility = ESlateVisibility::Hidden;

		// Show the correct upscaling quality option
		if (UpscalingOption.CurrentValue == "DLSS")
		{
			DLSSQualityOption.Visibility = ESlateVisibility::Visible;
			TSRQualityOption.Visibility = ESlateVisibility::Collapsed;
			FSRQualityOption.Visibility = ESlateVisibility::Collapsed;
			ResolutionScaleOption.Visibility = ESlateVisibility::Collapsed;
		}
		else if (UpscalingOption.CurrentValue == "TSR")
		{
			DLSSQualityOption.Visibility = ESlateVisibility::Collapsed;
			TSRQualityOption.Visibility = ESlateVisibility::Visible;
			FSRQualityOption.Visibility = ESlateVisibility::Collapsed;
			ResolutionScaleOption.Visibility = ESlateVisibility::Collapsed;
		}
		else if (UpscalingOption.CurrentValue == "FSR")
		{
			DLSSQualityOption.Visibility = ESlateVisibility::Collapsed;
			TSRQualityOption.Visibility = ESlateVisibility::Collapsed;
			FSRQualityOption.Visibility = ESlateVisibility::Visible;
			ResolutionScaleOption.Visibility = ESlateVisibility::Collapsed;
		}
		else
		{
			DLSSQualityOption.Visibility = ESlateVisibility::Collapsed;
			TSRQualityOption.Visibility = ESlateVisibility::Collapsed;
			FSRQualityOption.Visibility = ESlateVisibility::Collapsed;
			ResolutionScaleOption.Visibility = ESlateVisibility::Visible;
		}

		if (ResolutionRevertTimer > 0.0)
		{
			ResolutionRevertTimer -= InDeltaTime;
			if (ResolutionRevertTimer < 0.0)
				OnRevertResolution();
		}

		if (PokeRenderTargetTimer > 0.0)
		{
			PokeRenderTargetTimer -= InDeltaTime;
			if (PokeRenderTargetTimer < 0.0)
				OnPokeRenderTarget();
		}

		// Show the HDR option only when HDR is supported
		if (GameSettings::IsHDROutputSupported())
		{
			HDROption.Visibility = ESlateVisibility::Visible;
			HDRNotDisplayed.Visibility = ESlateVisibility::Collapsed;
		}
		else
		{
			HDROption.Visibility = ESlateVisibility::Collapsed;
			HDRNotDisplayed.Visibility = ESlateVisibility::Visible;
		}
	}

	void OnPokeRenderTarget()
	{
		// Why are we doing this? No idea, but toggling vsync seems to work around a
		// glitch on steam deck where the window size and the render target size are out of sync
		if (PokeVSyncValue.IsEmpty())
		{
			PokeVSyncValue = VSyncOption.CurrentValue;
			if (PokeVSyncValue == "On")
				VSyncOption.CurrentValue = "Off";
			else
				VSyncOption.CurrentValue = "On";
			GameSettings::SetGameSettingsValue(VSyncOption.OptionId, VSyncOption.CurrentValue);
			PokeRenderTargetTimer = 0.5;
		}
		else
		{
			VSyncOption.CurrentValue = PokeVSyncValue;
			GameSettings::SetGameSettingsValue(VSyncOption.OptionId, VSyncOption.CurrentValue);
			PokeVSyncValue.Empty();
		}
	}

	UFUNCTION()
	private void OnApplyResolution()
	{
		WindowModeOption.Apply();
		ResolutionOption.Apply();

		FMessageDialog MessageDialog;
		MessageDialog.Message = NSLOCTEXT("OptionsMenu", "ResolutionDialog", "Keep these display settings?\nAutomatically reverting to the previous display settings after 15 seconds.");
		MessageDialog.AddOption(
			NSLOCTEXT("OptionsMenu", "KeepResolution", "Keep Display Settings"),
			FOnMessageDialogOptionChosen(this, n"OnChooseKeepResolution"));
		MessageDialog.AddOption(
			NSLOCTEXT("OptionsMenu", "RevertResolution", "Revert"),
			FOnMessageDialogOptionChosen(this, n"OnRevertResolution"),
			EMessageDialogOptionType::Cancel);

		ShowPopupMessage(MessageDialog, this);
		ResolutionRevertTimer = 15.0;
		PokeRenderTargetTimer = 1.0;
	}

	UFUNCTION()
	private void OnRevertResolution()
	{
		WindowModeOption.CurrentValue = OriginalWindowMode;
		ResolutionOption.CurrentValue = OriginalResolution;

		WindowModeOption.UpdateValue();
		WindowModeOption.Apply();

		ResolutionOption.UpdateValue();
		ResolutionOption.Apply();

		ClosePopupMessageByInstigator(this);
		ResolutionRevertTimer = -1.0;
	}

	UFUNCTION()
	private void OnChooseKeepResolution()
	{
		OriginalResolution = ResolutionOption.CurrentValue;
		OriginalWindowMode = WindowModeOption.CurrentValue;
	}
};