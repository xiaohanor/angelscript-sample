
event void FOnOptionsMenuClosed();

struct FPlatformLegalText
{
	UPROPERTY()
	TArray<TSoftObjectPtr<ULicenseAsset>> LegalTexts;
}

class UOptionsMenu : UHazeUserWidget
{
	default bIsFocusable = true;
	default Visibility = ESlateVisibility::Visible;

	UPROPERTY()
	FOnOptionsMenuClosed OnClosed;

	UPROPERTY(BindWidget)
	UBorder PageContainer;

	UPROPERTY(BindWidget)
	UHorizontalBox TabList;

	UPROPERTY(BindWidget)
	UWidget DescriptionTooltipPanel;
	UPROPERTY(BindWidget)
	UImage DescriptionBackground;
	UPROPERTY(BindWidget)
	UTextBlock DescriptionTextBlock;

	UPROPERTY(BindWidget)
	UMenuPromptOrButton BackButton;
	UPROPERTY(BindWidget)
	UMenuPromptOrButton ResetButton;
	UPROPERTY(BindWidget)
	UMenuPromptOrButton LegalButton;

	UPROPERTY(BindWidget)
	UWidget LegalContainer;
	UPROPERTY(BindWidget)
	UWidget OptionsContainer;

	UPROPERTY(BindWidget)
	UHazeTextWidget LegalHeading;
	UPROPERTY(BindWidget)
	UScrollBox LegalScroll;
	UPROPERTY(BindWidget)
	URichTextBlock LegalText;
	UPROPERTY(BindWidget)
	UMenuPromptOrButton LegalOKButton;

	UPROPERTY()
	TArray<TSubclassOf<UOptionsMenuPage>> Pages;

	UPROPERTY()
	TSubclassOf<UOptionsMenuTabButton> TabButtonClass;

	TArray<UOptionsMenuTabButton> TabButtons;
	UOptionsMenuPage CurrentPage;
	UOptionWidget FocusedOption;
	int CurrentPageIndex = 0;
	bool bEscapeDown = false;

	bool bIsRightPlayer = false;

	UPROPERTY()
	TMap<FString, FPlatformLegalText> LegalTexts;
	int LegalIndex = -1;

	float CurLegalScrollLeft = 0.0;
	float CurLegalScrollRight = 0.0;

	private bool bNarrateNextTick = false;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool bIsDesignTime)
	{
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		CreateTabButtons();
		SwitchToPage(0);

		BackButton.OnPressed.AddUFunction(this, n"OnBackPressed");
		ResetButton.OnPressed.AddUFunction(this, n"OnResetPressed");
		LegalButton.OnPressed.AddUFunction(this, n"ShowLegal");

		LegalOKButton.OnPressed.AddUFunction(this, n"LegalNext");
		bIsRightPlayer = Game::HazeGameInstance != nullptr && Game::HazeGameInstance.GetPausingPlayer() == EHazeSelectPlayer::Zoe;
	}

	UFUNCTION()
	private void OnBackPressed(UHazeUserWidget Widget = nullptr)
	{
		OptionsMenuBack();
	}

	UFUNCTION()
	private void OnResetPressed(UHazeUserWidget Widget = nullptr)
	{
		FMessageDialog Dialog;
		Dialog.Message = NSLOCTEXT("OptionsMenu", "PromptReset", "Reset all settings back to the default values?");
		Dialog.AddOption(
			FText::Format(
				NSLOCTEXT("OptionsMenu", "ResetCurrentPage", "Reset {0} Settings"),
				CurrentPage.TabName
			),
			FOnMessageDialogOptionChosen(this, n"OnConfirmResetCurrentPage"),
		);
		Dialog.AddOption(
			NSLOCTEXT("OptionsMenu", "ResetAllSettings", "Reset All Settings"),
			FOnMessageDialogOptionChosen(this, n"OnConfirmResetAllPages"),
		);
		Dialog.AddCancelOption();
		ShowPopupMessage(Dialog, this);

		if (Widget == nullptr)
		{
			UMenuEffectEventHandler::Trigger_OnDefaultClick(Menu::GetAudioActor(), FMenuActionData(ResetButton));
		}
	}

	UFUNCTION()
	private void OnConfirmResetCurrentPage()
	{
		if (CurrentPage != nullptr)
			CurrentPage.ResetOptionsToDefault();
		
		GameSettings::ApplyGameSettingsKeyBindings();

		if (CurrentPage != nullptr)
			CurrentPage.RefreshSettings();
	}

	UFUNCTION()
	private void OnConfirmResetAllPages()
	{
		TArray<UHazeGameSettingBase> Settings;
		GameSettings::GetAllSettingsDescriptions(Settings);

		for (UHazeGameSettingBase Setting : Settings)
		{
			FString CurrentValue;
			if (GameSettings::GetGameSettingsValue(Setting.Id, CurrentValue))
			{
				if (CurrentValue != Setting.DefaultValue)
					GameSettings::SetGameSettingsValue(Setting.Id, Setting.DefaultValue);
			}
		}

		TArray<UHazeKeyBindSetting> Keybinds;
		GameSettings::GetAllKeyBindingSettingsDescriptions(Keybinds);

		for (UHazeKeyBindSetting Keybind : Keybinds)
		{
			for (int i = 0; i < 3; ++i)
			{
				EHazeKeybindType Type = EHazeKeybindType(i);
				if (!Keybind.bHasControllerBind && Type != EHazeKeybindType::Keyboard)
					continue;

				FKey CurrentKey;
				if (GameSettings::GetKeybindValue(Keybind.Id, Type, CurrentKey))
				{
					FKey DefaultKey = Keybind.KeyboardDefault;
					if (Type != EHazeKeybindType::Keyboard)
						DefaultKey = Keybind.ControllerDefault;

					if (CurrentKey != DefaultKey)
						GameSettings::SetKeybindValue(Keybind.Id, Type, DefaultKey);
				}
			}
		}

		GameSettings::ApplyGameSettingsKeyBindings();

		if (CurrentPage != nullptr)
			CurrentPage.RefreshSettings();
	}

	UFUNCTION()
	private void ShowLegal(UHazeUserWidget Widget = nullptr)
	{
		OptionsContainer.Visibility = ESlateVisibility::Hidden;
		LegalContainer.Visibility = ESlateVisibility::SelfHitTestInvisible;
		Widget::SetAllPlayerUIFocus(this);
		CurLegalScrollLeft = 0.0;
		CurLegalScrollRight = 0.0;
		ShowLegalText(0);

		if (Widget == nullptr)
		{
			UMenuEffectEventHandler::Trigger_OnDefaultClick(Menu::GetAudioActor(), FMenuActionData(LegalButton));
		}
	}

	void ShowLegalText(int Index)
	{
		LegalIndex = Index;

		FPlatformLegalText ActiveText;
		LegalTexts.Find(Game::GetPlatformName(), ActiveText);

		if (!ActiveText.LegalTexts.IsValidIndex(LegalIndex))
			return;

		auto SoftRef = ActiveText.LegalTexts[LegalIndex];
		auto LegalAsset = SoftRef.Get();
		if (LegalAsset != nullptr)
		{
			FLicenseContent LicenseContent = LegalAsset.GetLicenseForCulture(Internationalization::GetCurrentCulture());
			LegalHeading.SetText(FText::FromString(LicenseContent.Title));
			LegalText.SetText(FText::FromString(LicenseContent.Text));
			LegalScroll.ScrollToStart();

			if (LicenseContent.Title.IsEmpty())
				LegalHeading.Visibility = ESlateVisibility::Collapsed;
			else
				LegalHeading.Visibility = ESlateVisibility::HitTestInvisible;
		}
		else
		{
			SoftRef.LoadAsync(FOnSoftObjectLoaded(this, n"OnLegalTextLoaded"));
			LegalHeading.SetText(FText::FromString("..."));
			LegalText.SetText(FText::FromString("..."));
		}
	}

	UFUNCTION()
	private void OnLegalTextLoaded(UObject LoadedObject)
	{
		if (LegalIndex != -1)
			ShowLegalText(LegalIndex);
	}

	UFUNCTION()
	private void LegalNext(UHazeUserWidget Widget = nullptr)
	{
		FPlatformLegalText ActiveText;
		LegalTexts.Find(Game::GetPlatformName(), ActiveText);

		if (ActiveText.LegalTexts.IsValidIndex(LegalIndex+1))
			ShowLegalText(LegalIndex+1);
		else
			CloseLegalText();
	}

	void CloseLegalText()
	{
		OptionsContainer.Visibility = ESlateVisibility::SelfHitTestInvisible;
		LegalContainer.Visibility = ESlateVisibility::Hidden;
		Widget::SetAllPlayerUIFocus(CurrentPage);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (LegalContainer.IsVisible())
		{
			float TotalScroll = CurLegalScrollLeft + CurLegalScrollRight;
			if (Math::Abs(TotalScroll) > 0.4)
			{
				float ScrollAmount = 10.0 * TotalScroll;

				float NewScrollOffset = LegalScroll.ScrollOffset + ScrollAmount;
				NewScrollOffset = Math::Clamp(NewScrollOffset, 0.0, LegalScroll.ScrollOffsetOfEnd);
				LegalScroll.SetScrollOffset(NewScrollOffset);
			}
		}

		UpdateTooltipPosition();

		if (bNarrateNextTick)
		{
			bNarrateNextTick = false;
			InternalNarrateFullMenu();
		}
	}

	void UpdateTooltipPosition()
	{
		if (FocusedOption == nullptr || DescriptionTextBlock.GetText().IsEmpty() || !FocusedOption.IsHoveredOrActive())
		{
			DescriptionTooltipPanel.Visibility = ESlateVisibility::Hidden;
			return;
		}

		FGeometry OptionGeometry = FocusedOption.GetCachedGeometry();
		if (OptionGeometry.LocalSize.IsZero())
		{
			DescriptionTooltipPanel.Visibility = ESlateVisibility::Hidden;
			return;
		}

		FVector2D ViewResolution = SceneView::GetFullViewportResolution();
		float ScreenAspect = ViewResolution.X / ViewResolution.Y;

		FVector2D OptionPos = OptionGeometry.LocalToAbsolute(FVector2D(0, OptionGeometry.LocalSize.Y * 0.5));
		FGeometry CanvasGeometry = DescriptionTooltipPanel.Parent.GetCachedGeometry();
		FVector2D CanvasOptionPos = CanvasGeometry.AbsoluteToLocal(OptionPos);
		FVector2D TooltipSize = DescriptionTooltipPanel.GetCachedGeometry().LocalSize;

		DescriptionTooltipPanel.Visibility = ESlateVisibility::HitTestInvisible;

		auto TooltipSlot = Cast<UCanvasPanelSlot>(DescriptionTooltipPanel.Slot);
		FMargin Margin = TooltipSlot.Offsets;
		Margin.Top = CanvasOptionPos.Y - TooltipSize.Y*0.5;

		if (bIsRightPlayer)
		{
			if (ScreenAspect < 1.3)
			{
				Margin.Left = 900.0 - TooltipSize.X;
				Margin.Top = CanvasOptionPos.Y + 20;
			}
			else
			{
				Margin.Left = -TooltipSize.X + 40;
			}

			DescriptionBackground.SetRenderScale(FVector2D(-1.0, 1.0));
		}
		else
		{
			if (ScreenAspect < 1.3)
			{
				Margin.Left = 900.0 - TooltipSize.X;
				Margin.Top = CanvasOptionPos.Y + 20;
			}
			else
			{
				Margin.Left = 900.0;
			}

			DescriptionBackground.SetRenderScale(FVector2D(1.0, 1.0));
		}

		TooltipSlot.SetOffsets(Margin);
	}

	void CreateTabButtons()
	{
		TabList.ClearChildren();
		TabButtons.Reset();

		// Remove tabs that should not be shown on this platform
		for (int i = Pages.Num() - 1; i >= 0; --i)
		{
			auto Page = Pages[i];
			auto PageCDO = Cast<UOptionsMenuPage>(Page.Get().DefaultObject);
			if (!PageCDO.ShouldShowPageOnCurrentPlatform())
				Pages.RemoveAt(i);
		}

		// Create buttons for each tab
		for (int i = 0, Count = Pages.Num(); i < Count; ++i)
		{
			auto Page = Pages[i];
			auto PageCDO = Cast<UOptionsMenuPage>(Page.Get().DefaultObject);

			auto TabButton = Cast<UOptionsMenuTabButton>(Widget::CreateWidget(this, TabButtonClass));
			TabButton.Text = PageCDO.TabName;
			TabButton.TabIndex = i;
			TabButton.Update();
			TabButton.OnClicked.AddUFunction(this, n"OnTabClicked");

			auto TabSlot = TabList.AddChildToHorizontalBox(TabButton);
			// FSlateChildSize Size;
			// Size.SizeRule = ESlateSizeRule::Fill;
			// Size.Value = 1.0;
			// TabSlot.SetSize(Size);

			FMargin ButtonPadding;
			ButtonPadding.Left = 5.0;
			ButtonPadding.Right = 5.0;
			TabSlot.Padding = ButtonPadding;

			TabButtons.Add(TabButton);
		}
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		if (LegalContainer.IsVisible())
			return FEventReply::Unhandled();
		return FEventReply::Handled().SetUserFocus(CurrentPage, InFocusEvent.Cause);
	}

	UFUNCTION()
	private void OnTabClicked(UMenuTabButtonWidget Widget)
	{
		auto TabButton = Cast<UOptionsMenuTabButton>(Widget);
		SwitchToPage(TabButton.TabIndex, EFocusCause::Mouse);
	}

	void SwitchToPage(int PageIndex, EFocusCause FocusCause = EFocusCause::SetDirectly)
	{
		PageContainer.ClearChildren();
		CurrentPage = Cast<UOptionsMenuPage>(Widget::CreateWidget(this, Pages[PageIndex]));
		CurrentPageIndex = PageIndex;
		PageContainer.AddChild(CurrentPage);

		CurrentPage.OnOptionFocused.AddUFunction(this, n"OnOptionFocused");

		for (int i = 0, Count = TabButtons.Num(); i < Count; ++i)
		{
			UOptionsMenuTabButton TabButton = TabButtons[i];
			if (i == PageIndex)
				TabButton.bIsActiveTab = true;
			else
				TabButton.bIsActiveTab = false;

			TabButton.Update();
		}

		Widget::SetAllPlayerUIFocus(CurrentPage, FocusCause);

		UMenuEffectEventHandler::Trigger_OnOptionsSwitchToPage(
			Menu::GetAudioActor(), FOptionsMenuSwitchToPageData(CurrentPage, CurrentPageIndex, FocusCause));

		if (FocusCause != EFocusCause::SetDirectly)
		{
			NarrateFullMenu();
		}
	}

	UFUNCTION()
	private void OnOptionFocused(UOptionWidget Widget)
	{
		FocusedOption = Widget;
		if (Widget != nullptr)
			DescriptionTextBlock.Text = Widget.GetDescription();
		else
			DescriptionTextBlock.Text = FText();
	}

	void GetOptionsErrors(TArray<FText>& OutErrors)
	{
		// Find any input binds that don't have anything assigned or that are conflicting
		TArray<UHazeKeyBindSetting> KeybindSettings;
		GameSettings::GetAllKeyBindingSettingsDescriptions(KeybindSettings);

		for (int i = 0; i < int(EHazeKeybindType::EHazeKeybindType_MAX); ++i)
		{
			EHazeKeybindType Type = EHazeKeybindType(i);

			TMap<FKey, FName> KeyToSetting;
			TArray<FName> InvalidSettings;
			TArray<FName> ConflictingSettings;

			for (UHazeKeyBindSetting Setting : KeybindSettings)
			{
				FKey BoundKey;
				GameSettings::GetKeybindValue(Setting.Id, Type, BoundKey);

				if (Type != EHazeKeybindType::Keyboard)
				{
					if (!Setting.bHasControllerBind)
						continue;
				}

				if (BoundKey.IsValid())
				{
					if (KeyToSetting.Contains(BoundKey))
					{
						FName PrevSetting = KeyToSetting[BoundKey];
						if (!InputOptions::IsAllowedOverlappingBind(PrevSetting, Setting.Id) && !InputOptions::IsAllowedOverlappingBind(Setting.Id, PrevSetting))
						{
							// Both keys become invalid if the overlap is not allowed
							ConflictingSettings.Add(PrevSetting);
							ConflictingSettings.Add(Setting.Id);
						}
					}

					KeyToSetting.Add(BoundKey, Setting.Id);
				}
				else
				{
					InvalidSettings.Add(Setting.Id);
				}
			}

			if (ConflictingSettings.Num() != 0 || InvalidSettings.Num() != 0)
			{
				FText TypeName;
				switch (Type)
				{
					case EHazeKeybindType::Keyboard:
						TypeName = NSLOCTEXT("OptionsMenu", "KeybindNameType_Keyboard", "Keyboard");
					break;
					case EHazeKeybindType::MioController:
						TypeName = NSLOCTEXT("OptionsMenu", "KeybindNameType_MioController", "Mio");
					break;
					case EHazeKeybindType::ZoeController:
						TypeName = NSLOCTEXT("OptionsMenu", "KeybindNameType_ZoeController", "Zoe");
					break;
				}

				for (UHazeKeyBindSetting Setting : KeybindSettings)
				{
					if (InvalidSettings.Contains(Setting.Id))
					{
						OutErrors.Add(FText::Format(
							NSLOCTEXT("OptionsMenu", "KeybindError_NoBind", "- Action \"{0}\" ({1}) has no input assigned"),
							Setting.DisplayName,
							TypeName
						));
					}
					else if (ConflictingSettings.Contains(Setting.Id))
					{
						OutErrors.Add(FText::Format(
							NSLOCTEXT("OptionsMenu", "KeybindError_ConflictBind", "- Action \"{0}\" ({1}) has the same input assigned as another action"),
							Setting.DisplayName,
							TypeName
						));
					}
				}
			}
		}
	}

	UFUNCTION()
	void OptionsMenuBack()
	{
		TArray<FText> Errors;
		GetOptionsErrors(Errors);

		if (Errors.Num() != 0)
		{
			FString Message = NSLOCTEXT("OptionsMenu", "ExitWithErrors", "The current settings contain the following errors:\n").ToString();

			int ShowErrors = Math::Min(Errors.Num(), 8);
			if (Errors.Num() == 9)
				ShowErrors += 1;

			for (int i = 0; i < ShowErrors; ++i)
				Message += f"\n{Errors[i]}";

			if (Errors.Num() > ShowErrors)
			{
				Message += "\n";
				Message += FText::Format(
					NSLOCTEXT("OptionsMenu", "ExitMoreErrors", "... {0} more errors"),
					Errors.Num() - ShowErrors);
			}

			FMessageDialog Dialog;
			Dialog.Message = FText::FromString(Message);
			Dialog.AddOption(
				NSLOCTEXT("OptionsMenu", "ConfirmExitWithErrors", "Proceed Anyway"),
				FOnMessageDialogOptionChosen(this, n"OnConfirmExitWithErrors"),
			);
			Dialog.AddCancelOption();
			ShowPopupMessage(Dialog, this);
			return;
		}

		GameSettings::PostApplyNewSettings();
		OnClosed.Broadcast();
	}

	UFUNCTION()
	private void OnConfirmExitWithErrors()
	{
		GameSettings::PostApplyNewSettings();
		OnClosed.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (InKeyEvent.IsRepeat())
			return FEventReply::Unhandled();

		if (LegalContainer.IsVisible())
		{
			if (InKeyEvent.Key == EKeys::Virtual_Back || InKeyEvent.Key == EKeys::Escape)
			{
				bEscapeDown = true;
				return FEventReply::Handled();
			}
			else if (InKeyEvent.Key == EKeys::Virtual_Accept || InKeyEvent.Key == EKeys::Enter)
			{
				LegalNext();
				return FEventReply::Handled();
			}
			else if (InKeyEvent.Key == EKeys::PageDown)
			{
				LegalScroll.SetScrollOffset(Math::Clamp(LegalScroll.ScrollOffset + 500, 0, LegalScroll.ScrollOffsetOfEnd));
				return FEventReply::Handled();
			}
			else if (InKeyEvent.Key == EKeys::PageUp)
			{
				LegalScroll.SetScrollOffset(Math::Clamp(LegalScroll.ScrollOffset - 500, 0, LegalScroll.ScrollOffsetOfEnd));
				return FEventReply::Handled();
			}
			else if (InKeyEvent.Key == EKeys::Down)
			{
				LegalScroll.SetScrollOffset(Math::Clamp(LegalScroll.ScrollOffset + 50, 0, LegalScroll.ScrollOffsetOfEnd));
				return FEventReply::Handled();
			}
			else if (InKeyEvent.Key == EKeys::Up)
			{
				LegalScroll.SetScrollOffset(Math::Clamp(LegalScroll.ScrollOffset - 50, 0, LegalScroll.ScrollOffsetOfEnd));
				return FEventReply::Handled();
			}
		}
		else
		{
			if (InKeyEvent.Key == EKeys::Virtual_Back || InKeyEvent.Key == EKeys::Escape)
			{
				bEscapeDown = true;
				return FEventReply::Handled();
			}
			else if (InKeyEvent.Key == EKeys::Gamepad_LeftTrigger || InKeyEvent.Key == EKeys::F2)
			{
				ShowLegal();
				return FEventReply::Handled();
			}
			else if (InKeyEvent.Key == EKeys::Gamepad_FaceButton_Top || InKeyEvent.Key == EKeys::F1)
			{
				OnResetPressed();
				return FEventReply::Handled();
			}
			else if (InKeyEvent.Key == EKeys::Gamepad_LeftShoulder || InKeyEvent.Key == EKeys::PageUp)
			{
				SwitchToPage(Math::WrapIndex(CurrentPageIndex - 1, 0, Pages.Num()), EFocusCause::Navigation);
				return FEventReply::Handled();
			}
			else if (InKeyEvent.Key == EKeys::Gamepad_RightShoulder || InKeyEvent.Key == EKeys::PageDown)
			{
				SwitchToPage(Math::WrapIndex(CurrentPageIndex + 1, 0, Pages.Num()), EFocusCause::Navigation);
				return FEventReply::Handled();
			}
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (InKeyEvent.IsRepeat())
			return FEventReply::Unhandled();

		if (LegalContainer.IsVisible())
		{
			if (InKeyEvent.Key == EKeys::Virtual_Back || InKeyEvent.Key == EKeys::Escape)
			{
				if (bEscapeDown)
					CloseLegalText();
				bEscapeDown = false;
				return FEventReply::Handled();
			}
			else if (InKeyEvent.Key == EKeys::Virtual_Accept || InKeyEvent.Key == EKeys::Enter)
			{
				return FEventReply::Handled();
			}
		}
		else
		{
			if (InKeyEvent.Key == EKeys::Virtual_Back || InKeyEvent.Key == EKeys::Escape)
			{
				if (bEscapeDown)
					OptionsMenuBack();
				bEscapeDown = false;
				return FEventReply::Handled();
			}
			else if (InKeyEvent.Key == EKeys::Gamepad_LeftTrigger || InKeyEvent.Key == EKeys::F2)
			{
				return FEventReply::Handled();
			}
			else if (InKeyEvent.Key == EKeys::Gamepad_FaceButton_Top || InKeyEvent.Key == EKeys::F1)
			{
				return FEventReply::Handled();
			}
			else if (InKeyEvent.Key == EKeys::Gamepad_LeftShoulder || InKeyEvent.Key == EKeys::PageUp)
			{
				return FEventReply::Handled();
			}
			else if (InKeyEvent.Key == EKeys::Gamepad_RightShoulder || InKeyEvent.Key == EKeys::PageDown)
			{
				return FEventReply::Handled();
			}
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnAnalogValueChanged(FGeometry MyGeometry, FAnalogInputEvent InAnalogInputEvent)
	{
		if (LegalContainer.IsVisible())
		{
			if (InAnalogInputEvent.Key == EKeys::Gamepad_LeftY)
			{
				CurLegalScrollLeft = -InAnalogInputEvent.AnalogValue;
				return FEventReply::Handled();
			}
			else if (InAnalogInputEvent.Key == EKeys::Gamepad_RightY)
			{
				CurLegalScrollRight = -InAnalogInputEvent.AnalogValue;
				return FEventReply::Handled();
			}
		}

		return FEventReply::Unhandled();
	}

	void InternalNarrateFullMenu()
	{
		if (!Game::IsNarrationEnabled())
			return;

		if (CurrentPage == nullptr)
			return;

		FString FullNarration = "";
		FullNarration += CurrentPage.TabName.ToString() + " Options, ";

		if (FocusedOption != nullptr)
		{
			FullNarration += FocusedOption.GetFullNarrationText() + ", ";
		}

		FString ControlNarration;

		EHazePlayerControllerType Controller = Lobby::GetMostLikelyControllerType();
		if (Controller == EHazePlayerControllerType::Keyboard)
		{
			ControlNarration += "Change Tab Left, ";
			ControlNarration += EKeys::PageUp.GetDisplayName().ToString() + ", ";

			ControlNarration += "Change Tab Right, ";
			ControlNarration += EKeys::PageDown.GetDisplayName().ToString() + ", ";

			ControlNarration += BackButton.Text.ToString() + ", ";
			ControlNarration += EKeys::Escape.GetDisplayName().ToString() + ", ";

			ControlNarration += ResetButton.Text.ToString() + ", ";
			ControlNarration += EKeys::F1.GetDisplayName().ToString() + ", ";

			ControlNarration += LegalButton.Text.ToString() + ", ";
			ControlNarration += EKeys::F2.GetDisplayName().ToString() + ", ";
		}
		else
		{
			ControlNarration += "Change Tab Left, ";
			ControlNarration += Game::KeyToNarrationText(EKeys::Gamepad_LeftShoulder, Controller).ToString() + ", ";

			ControlNarration += "Change Tab Right, ";
			ControlNarration += Game::KeyToNarrationText(EKeys::Gamepad_RightShoulder, Controller).ToString() + ", ";

			ControlNarration += BackButton.Text.ToString() + ", ";
			ControlNarration += Game::KeyToNarrationText(EKeys::Virtual_Back, Controller).ToString() + ", ";

			ControlNarration += ResetButton.Text.ToString() + ", ";
			ControlNarration += Game::KeyToNarrationText(EKeys::Gamepad_FaceButton_Top, Controller).ToString() + ", ";

			ControlNarration += LegalButton.Text.ToString() + ", ";
			ControlNarration += Game::KeyToNarrationText(EKeys::Gamepad_LeftTrigger, Controller).ToString() + ", ";
		}

		FullNarration += "Menu Controls, " + ControlNarration;

		Game::NarrateString(FullNarration);
	}

	UFUNCTION()
	void NarrateFullMenu()
	{
		bNarrateNextTick = true;
	}
};

class UOptionsMenuTabButton : UMenuTabButtonWidget
{
	UPROPERTY(BindWidget)
	UTextBlock ButtonTextWidget;
	UPROPERTY(BindWidget)
	UImage ActiveTabHighlight;

	UPROPERTY()
	UTexture2D ActiveHighlightImage;
	UPROPERTY()
	UTexture2D InactiveHighlightImage;
	UPROPERTY()
	UTexture2D PressedHighlightImage;

	UPROPERTY(EditAnywhere, Category = "Options Menu Tab Button")
	FText Text;

	int TabIndex = 0;

	void Update()
	{
		if (Text.IsEmpty())
			ButtonTextWidget.SetText(FText::FromString("Tab"));
		else
			ButtonTextWidget.SetText(Text);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		UHazeGameInstance HazeGameInstance = Game::HazeGameInstance;
		if (HazeGameInstance != nullptr)
		{
			switch (HazeGameInstance.PausingPlayer)
			{
				case EHazeSelectPlayer::Mio:
					ActiveTabHighlight.SetColorAndOpacity(FLinearColor(1, 0.686, 0.7529, 1));
				break;
				case EHazeSelectPlayer::Zoe:
					ActiveTabHighlight.SetColorAndOpacity(FLinearColor(0.913, 0.921, 0.610));
				break;
				default:
					ActiveTabHighlight.SetColorAndOpacity(FLinearColor(0.584, 1, 1));
				break;
			}
		}
		else
		{
			ActiveTabHighlight.SetColorAndOpacity(FLinearColor(0.584, 1, 1));
		}

		if (bPressed)
		{
			ButtonTextWidget.SetRenderTranslation(FVector2D(0, 2));
		}
		else
		{
			ButtonTextWidget.SetRenderTranslation(FVector2D(0, 0));
		}

		if (bIsActiveTab)
		{
			ButtonTextWidget.SetColorAndOpacity(FLinearColor::White);

			FSlateFontInfo Font = ButtonTextWidget.Font;
			Font.TypefaceFontName = NAME_None;
			ButtonTextWidget.SetFont(Font);

			ActiveTabHighlight.SetBrushFromTexture(ActiveHighlightImage);
			ActiveTabHighlight.Visibility = ESlateVisibility::HitTestInvisible;
		}
		else
		{
			FSlateFontInfo Font = ButtonTextWidget.Font;
			Font.TypefaceFontName = NAME_None;
			ButtonTextWidget.SetFont(Font);

			if (bPressed)
			{
				ButtonTextWidget.SetColorAndOpacity(FLinearColor(0.8, 0.8, 0.8, 1.0));
				ActiveTabHighlight.Visibility = ESlateVisibility::HitTestInvisible;
				ActiveTabHighlight.SetBrushFromTexture(PressedHighlightImage);
			}
			else if (bHovered)
			{
				ButtonTextWidget.SetColorAndOpacity(FLinearColor(0.8, 0.8, 0.8, 1.0));
				ActiveTabHighlight.Visibility = ESlateVisibility::HitTestInvisible;
				ActiveTabHighlight.SetBrushFromTexture(InactiveHighlightImage);
			}
			else
			{
				ButtonTextWidget.SetColorAndOpacity(FLinearColor(0.25, 0.25, 0.25, 1.0));
				ActiveTabHighlight.Visibility = ESlateVisibility::Hidden;
			}
		}
	}
};