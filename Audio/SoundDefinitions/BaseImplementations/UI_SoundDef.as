enum EHazeUIPosition
{
	None,
	First,
	Last,
}

enum EHazeUIMovement
{
	None,
	Up,
	Down,
}

UCLASS(Abstract)
class UUI_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UWidget LastWidget = nullptr;

	UHazeUserWidget LastTest;
	bool bNotifyLostFocus = false;

	UPROPERTY(BlueprintReadOnly)
	EHazeUIMovement VerticalMovement = EHazeUIMovement::None;
	ULobbyChapterSelectItemWidget LastChapterSelectItem;

	FHazeAudioID Rtpc_SpeakerPanning_LR = FHazeAudioID("Rtpc_SpeakerPanning_LR");
	UOptionsMenu OptionsMenu;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// We will override it for the pause menu, set it to be only affect the pausemenu ui sounds!
		// So if the options menu is activated we need to reset it to zero.
		DefaultEmitter.SetRTPC(Rtpc_SpeakerPanning_LR, 0, 0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if (bNotifyLostFocus &&
			LastWidget != nullptr && 
			HasWidgetLostFocusOrHover(LastWidget))
		{
			bNotifyLostFocus = false;

			#if TEST
			if (IsDebugging())
				PrintToScreen(f"Lost Focus From: {LastWidget.Name}", Duration = 2);
			#endif

			OnLastFocusLost();
		}
	}

	bool HasWidgetLostFocusOrHover(UWidget Widget) const
	{
		auto PromptOrButton = Cast<UMenuPromptOrButton>(Widget);
		if (PromptOrButton != nullptr && !PromptOrButton.IsButtonHovered())
			return true;
		
		auto IconPrompt = Cast<UMenuIconOrPrompt>(Widget);
		if (IconPrompt != nullptr && !IconPrompt.IsButtonHovered())
			return true;

		auto MenuTabButton = Cast<UMenuTabButtonWidget>(Widget);
		if (MenuTabButton != nullptr && !MenuTabButton.bHovered)
			return true;

		auto TabButton = Cast<UMenuTabButtonWidget>(Widget);
		if (TabButton != nullptr && !TabButton.bHovered)
			return true;

		auto MenuButton = Cast<UMenuButtonWidget>(Widget);
		if (MenuButton != nullptr && !MenuButton.bHovered)
			return true;
		
		auto OptionWidget = Cast<UOptionWidget>(Widget);
		if (OptionWidget != nullptr && !OptionWidget.bHovered)
			return true;

		auto SelectItem = Cast<UChapterSelectItemWidget>(Widget);
		if (SelectItem != nullptr && !SelectItem.bHovered)
			return true;

		return false;
	}

	// REGISTER TO WIDGETS

	void RegisterToMainMenuWidget(UMainMenuWidget Widget)
	{
		if (Widget == nullptr)
			return;

		RegisterToButton(Widget.PlayLocalButton);
		RegisterToButton(Widget.PlayLocalWirelessButton);
		RegisterToButton(Widget.PlayOnlineButton);
		RegisterToButton(Widget.DevJoinButton);
		RegisterToButton(Widget.DevMenuButton);
		RegisterToButton(Widget.OptionsButton);
		RegisterToButton(Widget.CreditsButton);
		RegisterToButton(Widget.QuitButton);
	}

	void RegisterToOptionsMenuWidget(UMainMenuOptions Widget)
	{
		if (Widget == nullptr)
			return;

		OptionsMenu = Widget.OptionsMenu;

		RegisterToPromptOrButton(OptionsMenu.BackButton, false, true);
		RegisterToPromptOrButton(OptionsMenu.ResetButton);
		RegisterToPromptOrButton(OptionsMenu.LegalButton);
		RegisterToPromptOrButton(OptionsMenu.LegalOKButton);
		// React to keyboard/controller.
		OptionsMenu.OnClosed.AddUFunction(this, n"OnOptionsMenuClosing");

		for (auto TabButton: OptionsMenu.TabButtons)
		{
			RegisterToButton(TabButton);
		}
	}

	UFUNCTION()
	private void OnOptionsMenuClosing()
	{
		if (OptionsMenu != nullptr && OptionsMenu.BackButton.IsButtonPressed())
			return;

		OnOptionsMenuClosed();
	}

	UFUNCTION(BlueprintEvent)
	private void OnOptionsMenuClosed()
	{
		
	}

	void RegisterToAllOptions(UOptionsMenuPage OptionsPage)
	{
		if (OptionsPage == nullptr)
			return;

		for (auto Option: OptionsPage.Options)
		{
			// Early outs if not the type.
			RegisterOptionsButton(Cast<UOptionButtonWidget>(Option));
			RegisterOptionsEnum(Cast<UOptionEnumWidget>(Option));
			RegisterOptionsSlider(Cast<UOptionSliderWidget>(Option));
		}

		auto AudioPage = Cast<UAudioOptionsMenuPage>(OptionsPage);
		if (AudioPage != nullptr)
		{
			RegisterToOptionsText(AudioPage.ObjectAudio);
		}

		auto InputOptions = Cast<UInputOptionsMenuPage>(OptionsPage);
		if (InputOptions != nullptr)
		{
			for (auto KeyBinding: InputOptions.KeybindWidgets)
			{
				RegisterKeyBindOptionWidget(KeyBinding);
			}
		}
	}

	void RegisterKeyBindOptionWidget(UKeybindOptionWidget Widget)
	{
		Widget.OnMouseHovered.AddUFunction(this, n"OnKeyBindingMouseHovered");
		Widget.OnKeybindFocused.AddUFunction(this, n"OnKeyBindingKeyBindFocused");
		// Widget.OnClicked.AddUFunction(this, n"OnKeyBindingClicked");

		Widget.KeyboardInput.OnInputChange.AddUFunction(this, n"OnKeyBindingInputChange");
		Widget.MioInput.OnInputChange.AddUFunction(this, n"OnKeyBindingInputChange");
		Widget.ZoeInput.OnInputChange.AddUFunction(this, n"OnKeyBindingInputChange");
	}

	UFUNCTION()
	private void OnKeyBindingMouseHovered(UKeybindOptionWidget Widget)
	{
		OnButtonFocusedHandled(Widget, Widget.bHovered, false, false);
	}

	UFUNCTION()
	private void OnKeyBindingKeyBindFocused(UKeybindOptionWidget Widget)
	{
		OnButtonFocusedHandled(Widget, Widget.bHovered, false, false);
	}

	UFUNCTION()
	private void OnKeyBindingClicked(UKeybindOptionWidget Widget)
	{
		OnButtonClickedHandled(Widget, Widget.bHovered, false, false);
	}

	UFUNCTION()
	private void OnKeyBindingInputChange(UKeybindInputBox InputBox, bool bStart)
	{
		OnInputKeyBindingApply(InputBox, bStart);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnInputKeyBindingApply(UKeybindInputBox Widget, bool bStartTakingInput) {}

	void RegisterToLevelSelect(ULobbyChapterSelectWidget Widget)
	{
		if (Widget == nullptr)
			return;
		
		RegisterToPromptOrButton(Widget.BackButton, false, true);
		RegisterToPromptOrButton(Widget.ProceedButton, true, false);
		// RegisterToChapterSelectWidget(Widget.ChapterSelect);
	}

	void RegisterToLobbyChooseStartType(ULobbyChooseStartTypeWidget Widget)
	{
		if (Widget == nullptr)
			return;
		
		RegisterToLobbyStartTypeButton(Widget.NewGameButton);
		RegisterToLobbyStartTypeButton(Widget.ContinueButton);
		RegisterToLobbyStartTypeButton(Widget.ChapterSelectButton);
	}

	void RegisterToLobbyPlayersWidget(ULobbyPlayersWidget Widget)
	{
		if (Widget == nullptr)
			return;
		
		RegisterToPromptOrButton(Widget.BackButton, false, true);
		RegisterToPromptOrButton(Widget.InviteButton);
		RegisterToPromptOrButton(Widget.ProceedButton, true, false);
		RegisterToPromptOrButton(Widget.FriendsPassInfoButton, false, false);

		Widget.ProceedButton.OnEnabled.AddUFunction(this, n"OnLobbyPlayerProceedButtonEnabled");
		
		Widget.PlayerOneInfo.OnStateUpdated.AddUFunction(this, n"OnLobbyPlayerStateLeftUpdated");
		Widget.PlayerTwoInfo.OnStateUpdated.AddUFunction(this, n"OnLobbyPlayerStateRightUpdated");

		Widget.PlayerOneInfo.OnClicked.AddUFunction(this, n"OnLobbyPlayerLeftClicked");
		Widget.PlayerOneInfo.OnClicked.AddUFunction(this, n"OnLobbyPlayerLeftClicked");
	}

	UFUNCTION(BlueprintEvent)
	private void OnLobbyPlayerProceedButtonEnabled(UHazeUserWidget Widget)
	{
	}

	UFUNCTION(BlueprintEvent)
	private void OnLobbyPlayerStateLeftUpdated(ELobbyPlayerWidgetState State)
	{
	}

	UFUNCTION(BlueprintEvent)
	private void OnLobbyPlayerStateRightUpdated(ELobbyPlayerWidgetState State)
	{
	}

	UFUNCTION(BlueprintEvent)
	private void OnLobbyPlayerLeftClicked()
	{
	}

	UFUNCTION(BlueprintEvent)
	private void OnLobbyPlayerRightClicked()
	{
	}

	void RegisterToCharacterSelectWidget(ULobbyCharacterSelectWidget Widget)
	{
		if (Widget == nullptr)
			return;

		RegisterToCharacterSelectPlayerWidget(Widget.PlayerOneInfo, true);
		RegisterToCharacterSelectPlayerWidget(Widget.PlayerTwoInfo, false);

		Widget.OnCharacterMoveSelection.AddUFunction(this, n"OnCharacterMoveSelection");
	}

	void RegisterToCharacterSelectPlayerWidget(ULobbyCharacterSelectPlayer Widget, bool bIsMio)
	{
		if (Widget == nullptr)
			return;

		Widget.LeftArrowButton.OnFocused.AddUFunction(this, n"OnMenuArrowButtonFocused");
		Widget.RightArrowButton.OnFocused.AddUFunction(this, n"OnMenuArrowButtonFocused");
	}

	void RegisterToMessageDialogWidget(UMessageDialogWidget Widget)
	{
		if (Widget == nullptr)
			return;

		for (auto Button: Widget.Buttons)
		{
			RegisterToMenuButton(Button);
		}

		if (Widget.MessageDialog.Options.Num() > 1)
		{
			auto LastButton = Widget.Buttons.Last();
			
			if (Widget.MessageDialog.Options.Last().Type == EMessageDialogOptionType::Cancel)
			{
				LastButton.OnClicked.UnbindObject(this);
				LastButton.OnClicked.AddUFunction(this, n"OnDialogMessageClosed");
			}
		}
	}

	UFUNCTION(BlueprintEvent)
	private void OnDialogMessageClosed(UMenuButtonWidget Button)
	{
	}

	void RegisterToPauseMenu(UPauseMenu Widget)
	{
		if (Widget == nullptr)
			return;

		// RegisterToChapterSelectWidget(Widget.ChapterSelect);
		RegisterToPromptOrButton(Widget.ChapterSelectBackButton, false, true);
		RegisterToPromptOrButton(Widget.ChapterSelectProceedButton, true, false);
		RegisterToMenuButton(Widget.ChapterSelectButton);

		RegisterToMenuButton(Widget.ResumeButton);
		RegisterToMenuButton(Widget.OptionsButton);
		RegisterToMenuButton(Widget.MainMenuButton);
		RegisterToMenuButton(Widget.RestartCheckpointButton);
		RegisterToMenuButton(Widget.QuitButton);

		RegisterToMenuButton(Widget.SkipCheckpointButton);
		RegisterToMenuButton(Widget.RestartSideStoryButton);
		RegisterToMenuButton(Widget.ExitSideContentButton);

		OptionsMenu = Widget.OptionsMenu;

		RegisterToPromptOrButton(OptionsMenu.BackButton, false, true);
		RegisterToPromptOrButton(OptionsMenu.ResetButton);
		RegisterToPromptOrButton(OptionsMenu.LegalButton);
		RegisterToPromptOrButton(OptionsMenu.LegalOKButton);
		OptionsMenu.OnClosed.AddUFunction(this, n"OnPauseMenuClosed");

		for (auto TabButton: OptionsMenu.TabButtons)
		{
			RegisterToButton(TabButton);
		}

		RegisterToAllOptions(OptionsMenu.CurrentPage);
	}

	UFUNCTION(BlueprintEvent)
	void OnPauseMenuClosed()
	{
	}

	//~

	// REGISTER TO DIFFERENT UI WIDGETS

	void RegisterToButton(UMainMenuButton Button, bool bProceedButton = false, bool bBackButton = false)
	{
		if (!bProceedButton && !bBackButton)
		{
			Button.OnClicked.AddUFunction(this, n"OnButtonClicked");
			Button.OnFocused.AddUFunction(this, n"OnButtonFocused");
		}
		else if(bProceedButton)
		{
			Button.OnClicked.AddUFunction(this, n"OnButtonProceedClicked");
			Button.OnFocused.AddUFunction(this, n"OnButtonProceedFocused");
		}
		else
		{
			Button.OnClicked.AddUFunction(this, n"OnButtonBackClicked");
			Button.OnFocused.AddUFunction(this, n"OnButtonBackFocused");
		}
	}

	UFUNCTION()
	private void OnButtonBackClicked(UMenuButtonWidget Button)
	{
		OnButtonClickedHandled(Button, Button.bFocusedByMouse, false, true);
	}

	UFUNCTION()
	private void OnButtonBackFocused(UMenuButtonWidget Button)
	{
		OnButtonFocusedHandled(Button, Button.bFocusedByMouse, false, true);
	}

	UFUNCTION()
	private void OnButtonProceedClicked(UMenuButtonWidget Button)
	{
		OnButtonClickedHandled(Button, Button.bFocusedByMouse, true, false);
	}

	UFUNCTION()
	private void OnButtonProceedFocused(UMenuButtonWidget Button)
	{
		OnButtonFocusedHandled(Button, Button.bFocusedByMouse, true, false);
	}

	void RegisterToPromptOrButton(UMenuPromptOrButton PromptOrButton, bool bProceedButton = false, bool bBackButton = false)
	{
		if (!bProceedButton && !bBackButton)
		{
			PromptOrButton.OnPressed.AddUFunction(this, n"OnNonParamButtonClicked");
			PromptOrButton.OnFocused.AddUFunction(this, n"OnNonParamButtonFocused");
		}
		else if(bProceedButton)
		{
			PromptOrButton.OnPressed.AddUFunction(this, n"OnNonParamButtonProceedClicked");
			PromptOrButton.OnFocused.AddUFunction(this, n"OnNonParamButtonProceedFocused");
		}
		else
		{
			PromptOrButton.OnPressed.AddUFunction(this, n"OnNonParamButtonBackClicked");
			PromptOrButton.OnFocused.AddUFunction(this, n"OnNonParamButtonBackFocused");
		}
	}

	void RegisterToButton(UOptionsMenuTabButton Button)
	{
		// We need some sort of context for this. To bad we can't do lambdas.
		// For now just do a None name call.
		// Button.OnClicked.AddUFunction(this, n"OnMenuTabButtonClicked");
		Button.OnFocused.AddUFunction(this, n"OnMenuTabButtonFocused");
	}

	void RegisterOptionsButton(UOptionButtonWidget Button)
	{
		if (Button == nullptr)
			return;

		Button.Prompt.OnPressed.AddUFunction(this, n"OnNonParamButtonClicked");
		Button.OnOptionFocused.AddUFunction(this, n"OnOptionButtonFocused");
	}

	void RegisterOptionsEnum(UOptionEnumWidget Enum)
	{
		if (Enum == nullptr)
			return;

		Enum.OnOptionFocused.AddUFunction(this, n"OnOptionButtonFocused");
		// if (!Enum.bAutoApply)
		{
			Enum.OnCustomLeftAndRight.AddUFunction(this, n"OnOptionsEnumApplied");
		}
		// else
		// {
			// Enum.OnOptionApplied.AddUFunction(this, n"OnOptionsEnumApplied");
		// }

		RegisterToArrowButton(Enum.LeftArrowButton);

		for (auto Dot: Enum.DotWidgets)
		{
			RegisterToDotIndicator(Enum, Dot);
		}

		RegisterToArrowButton(Enum.RightArrowButton);
	}


	void RegisterOptionsSlider(UOptionSliderWidget Slider)
	{
		if (Slider == nullptr)
			return;

		Slider.OnOptionFocused.AddUFunction(this, n"OnOptionButtonFocused");
		Slider.OnValueApplied.AddUFunction(this, n"OnSliderValueApplied");

		RegisterToArrowButton(Slider.LeftArrowButton);
		RegisterToArrowButton(Slider.RightArrowButton);
	}

	void RegisterToOptionsText(UOptionTextWidget Widget)
	{
		if (Widget == nullptr)
			return;

		Widget.OnOptionFocused.AddUFunction(this, n"OnOptionButtonFocused");
	}

	void RegisterToDotIndicator(UOptionEnumWidget ParentEnum, UOptionEnumDotIndicator DotIndicator)
	{
		if (DotIndicator == nullptr)
			return;

		
		DotIndicator.OnClicked.AddUFunction(this, n"OnDotIndicatorClicked");
		DotIndicator.OnFocused.AddUFunction(this, n"OnDotIndicatorFocused");
	}

	void RegisterToArrowButton(UMenuArrowButtonWidget Widget)
	{
		if (Widget == nullptr)
			return;
		
		Widget.OnClicked.AddUFunction(this, n"OnMenuArrowButtonClicked");
		Widget.OnFocused.AddUFunction(this, n"OnMenuArrowButtonFocused");
	}

	void RegisterToChapterSelectWidget(UChapterSelectWidget Widget)
	{
		if (Widget == nullptr)
			return;

		RegisterToArrowButton(Widget.PreviousGroupButton);
		RegisterToArrowButton(Widget.NextGroupButton);
	}

	void RegisterToChapterSelectItems(UChapterSelectWidget Widget)
	{
		if (Widget == nullptr)
			return;
		
		if (Widget.ItemWidgets.IsValidIndex(Widget.SelectedItem))
			LastChapterSelectItem = Widget.ItemWidgets[Widget.SelectedItem];
		
		Widget.OnItemSelectionChanged.AddUFunction(this, n"OnChapterSelectItemChanged");
		
		for (auto ItemWidget : Widget.ItemWidgets)
		{
			RegisterToChapterSelectItem(ItemWidget);
		}
	}

	UFUNCTION()
	private void OnChapterSelectItemChanged(ULobbyChapterSelectItemWidget Widget, FChapterSelectionItem Item)
	{
		// Simulate that it's been clicked.
		if (Widget == LastChapterSelectItem)
			return;

		LastChapterSelectItem = Widget;

		OnChapterSelectButtonClicked(Widget);
	}

	void RegisterToChapterSelectItem(UChapterSelectItemWidget ItemWidget)
	{
		if (ItemWidget == nullptr)
			return;
		// We don't need to subscribe since we get callbacks from "OnItemSelectionChanged"
		// ItemWidget.OnClicked.AddUFunction(this, n"OnChapterSelectButtonClicked");
		ItemWidget.OnFocused.AddUFunction(this, n"OnChapterSelectButtonFocused");
	}

	void RegisterToLobbyStartTypeButton(ULobbyStartTypeButton Button)
	{
		Button.OnClicked.AddUFunction(this, n"OnLobbyButtonClicked");
		Button.OnFocused.AddUFunction(this, n"OnLobbyButtonFocused");
	}

	void RegisterToMenuButton(UMenuButtonWidget Button)
	{
		Button.OnClicked.AddUFunction(this, n"OnButtonClicked");
		Button.OnFocused.AddUFunction(this, n"OnButtonFocused");
	}

	EHazeUIPosition GetElementPosition(UHazeUserWidget Widget)
	{
		auto MenuButton = Cast<UMainMenuButton>(Widget);
		if (MenuButton != nullptr)
		{
			if (MenuButton.bIsFirstOption)
			{
				return EHazeUIPosition::First;
			}
			else if (MenuButton.bIsLastOption)
			{
				return EHazeUIPosition::Last;
			}

			return EHazeUIPosition::None;
		}

		auto DialogButton = Cast<UMessageDialogButton>(Widget);
		if (DialogButton != nullptr)
		{
			if (DialogButton.bIsFirstOption)
			{
				return EHazeUIPosition::First;
			}
			else if (DialogButton.bIsLastOption)
			{
				return EHazeUIPosition::Last;
			}

			return EHazeUIPosition::None;
		}

		auto PauseMenuButton = Cast<UPauseMenuButton>(Widget);
		if (PauseMenuButton != nullptr)
		{
			if (PauseMenuButton.bIsFirstOption)
			{
				return EHazeUIPosition::First;
			}
			else if (PauseMenuButton.bIsLastOption)
			{
				return EHazeUIPosition::Last;
			}

			return EHazeUIPosition::None;
		}

		auto DotIndicator = Cast<UOptionEnumDotIndicator>(Widget);
		if (DotIndicator != nullptr)
		{
			if (DotIndicator.OptionIndex == 0)
			{
				return EHazeUIPosition::First;
			}
			else if (DotIndicator.EnumOption.DotWidgets.Last() == Widget)
			{
				return EHazeUIPosition::Last;
			}

			return EHazeUIPosition::None;
		}

		auto Parent = Widget.GetParent();
		if ( Parent != nullptr)
		{
			auto Childs = Parent.GetAllChildren();
			if (Childs.Num() >= 1)
			{
				if (Childs.Last() == Widget)
				{
					return EHazeUIPosition::Last;
				}
				else
				{
					for (auto Child : Childs)
					{
						auto UserWidget = Cast<UHazeUserWidget>(Child);
						if (!Child.IsVisible() || UserWidget == nullptr || UserWidget.Visibility != ESlateVisibility::Visible)
						{
							continue;
						}

						if (Child == Widget)
							return EHazeUIPosition::First;

						break;
					}
				}
			}
		}

		return EHazeUIPosition::None;
	}

	void UpdateLastWidgetAndCompareVerticalMovement(UWidget NewWidget)
	{
		if (LastWidget != nullptr)
		{
			if (LastWidget.PaintSpaceGeometry.RenderTransformTranslation.Y > NewWidget.PaintSpaceGeometry.RenderTransformTranslation.Y)
			{
				#if TEST
				if (IsDebugging())
					PrintToScreen(f"MovedUp: {NewWidget.Name}", Duration = 2);
				#endif
				VerticalMovement = EHazeUIMovement::Up;
			}
			else 
			{
				#if TEST
				if (IsDebugging())
					PrintToScreen(f"MovedDown: {NewWidget.Name}", Duration = 2);
				#endif
				VerticalMovement = EHazeUIMovement::Down;
			}
		}
		
		// Only notify of lost focus if the focus was made by mouse input
		if (!HasWidgetLostFocusOrHover(NewWidget))
			bNotifyLostFocus = true;
		LastWidget = NewWidget;
	}
	
	UFUNCTION()
	private void OnCharacterMoveSelection(EHazePlayer Player, bool bMoveLeft)
	{
		OnCharacterMovedSelection(Player, bMoveLeft);
	}

	UFUNCTION(BlueprintEvent)
	void OnCharacterMovedSelection(EHazePlayer Player, bool bMoveLeft) {}

	UFUNCTION(BlueprintEvent)
	void OnCharacterReadyClickedMio(bool bReady) {}

	UFUNCTION(BlueprintEvent)
	void OnCharacterReadyClickedZoe(bool bReady) {}
	
	UFUNCTION()
	void OnButtonClicked(UMenuButtonWidget Button)
	{
		#if TEST
		if (IsDebugging())
			PrintToScreen(f"Clicked: {Button.Name}", Duration = 10);
		#endif

		OnButtonClick(Button.Name, Button.bFocusedByMouse);
	}

	UFUNCTION()
	void OnButtonFocused(UMenuButtonWidget Button)
	{
		OnButtonFocusedHandled(Button, Button.bFocusedByMouse, false, false);
	}

	private void OnButtonClickedHandled(UHazeUserWidget Button, bool bFocusedByMouse, bool bProceed, bool bBack)
	{
		#if TEST
		if (IsDebugging())
			PrintToScreen(f"Clicked: {Button.Name}", Duration = 10);
		#endif

		if (bProceed)
		{
			OnButtonProceedClick(Button.Name, bFocusedByMouse);
		}
		else if (bBack)
		{
			OnButtonBackClick(Button.Name, bFocusedByMouse);
		}
		else
		{
			OnButtonClick(Button.Name, bFocusedByMouse);
		}
	}

	private void OnButtonFocusedHandled(UHazeUserWidget Button, bool bFocusedByMouse, bool bProceed, bool bBack)
	{
		auto Position = GetElementPosition(Button);

		#if TEST
		if (IsDebugging())
			PrintToScreen(f"OnButtonFocus: {Button.Name} - {Position}", Duration = 10);
		#endif

		auto ParentWidget = Cast<UMainMenuWidget>(Button.ParentUserWidget);
		bool bAnimated = ParentWidget != nullptr;

		UpdateLastWidgetAndCompareVerticalMovement(Button);

		if (bProceed)
		{
			OnButtonProceedFocus(Button.Name, bFocusedByMouse, Position, bAnimated);
		}
		else if (bBack)
		{
			OnButtonBackFocus(Button.Name, bFocusedByMouse, Position, bAnimated);
		}
		else
		{
			OnButtonFocus(Button.Name, bFocusedByMouse, Position, bAnimated);
		}
	}

	UFUNCTION()
	void OnNonParamButtonClicked(UHazeUserWidget Widget)
	{
		auto PromptOrButton = Cast<UMenuPromptOrButton>(Widget);
		if (PromptOrButton != nullptr)
		{
			OnButtonClickedHandled(PromptOrButton, PromptOrButton.IsButtonHovered(), false, false);
			return;
		}

		auto IconPrompt = Cast<UMenuIconOrPrompt>(Widget);
		if(IconPrompt != nullptr)
		{
			OnButtonClickedHandled(PromptOrButton, IconPrompt.IsButtonHovered(), false, false);
		}
		else
		{
			OnButtonClickedHandled(Widget, false, false, false);
		}
	}

	UFUNCTION()
	void OnNonParamButtonFocused(UHazeUserWidget Widget)
	{
		auto PromptOrButton = Cast<UMenuPromptOrButton>(Widget);
		if (PromptOrButton != nullptr)
		{
			OnButtonFocusedHandled(Widget, PromptOrButton.IsButtonHovered(), false, false);
			return;
		}

		auto IconPrompt = Cast<UMenuIconOrPrompt>(Widget);
		if(IconPrompt != nullptr)
		{
			OnButtonFocusedHandled(Widget, IconPrompt.IsButtonHovered(), false, false);
		}
		else
		{
			OnButtonFocusedHandled(Widget, false, false, false);
		}
	}

	UFUNCTION()
	private void OnNonParamButtonBackClicked(UHazeUserWidget Widget)
	{
		auto PromptOrButton = Cast<UMenuPromptOrButton>(Widget);
		if (PromptOrButton != nullptr)
		{
			OnButtonClickedHandled(PromptOrButton, PromptOrButton.IsButtonHovered(), false, true);
			return;
		}

		auto IconPrompt = Cast<UMenuIconOrPrompt>(Widget);
		if(IconPrompt != nullptr)
		{
			OnButtonClickedHandled(PromptOrButton, IconPrompt.IsButtonHovered(), false, true);
		}
		else
		{
			OnButtonClickedHandled(Widget, false, false, true);
		}
	}

	UFUNCTION()
	private void OnNonParamButtonBackFocused(UHazeUserWidget Widget)
	{
		auto PromptOrButton = Cast<UMenuPromptOrButton>(Widget);
		if (PromptOrButton != nullptr)
		{
			OnButtonFocusedHandled(Widget, PromptOrButton.IsButtonHovered(), false, true);
			return;
		}

		auto IconPrompt = Cast<UMenuIconOrPrompt>(Widget);
		if(IconPrompt != nullptr)
		{
			OnButtonFocusedHandled(Widget, IconPrompt.IsButtonHovered(), false, true);
		}
		else
		{
			OnButtonFocusedHandled(Widget, false, false, true);
		}
	}

	UFUNCTION()
	private void OnNonParamButtonProceedClicked(UHazeUserWidget Widget)
	{
			auto PromptOrButton = Cast<UMenuPromptOrButton>(Widget);
		if (PromptOrButton != nullptr)
		{
			OnButtonClickedHandled(PromptOrButton, PromptOrButton.IsButtonHovered(), true, false);
			return;
		}

		auto IconPrompt = Cast<UMenuIconOrPrompt>(Widget);
		if(IconPrompt != nullptr)
		{
			OnButtonClickedHandled(PromptOrButton, IconPrompt.IsButtonHovered(), true, false);
		}
		else
		{
			OnButtonClickedHandled(Widget, false, true, false);
		}
	}

	UFUNCTION()
	private void OnNonParamButtonProceedFocused(UHazeUserWidget Widget)
	{
		auto PromptOrButton = Cast<UMenuPromptOrButton>(Widget);
		if (PromptOrButton != nullptr)
		{
			OnButtonFocusedHandled(Widget, PromptOrButton.IsButtonHovered(), true, false);
			return;
		}

		auto IconPrompt = Cast<UMenuIconOrPrompt>(Widget);
		if(IconPrompt != nullptr)
		{
			OnButtonFocusedHandled(Widget, IconPrompt.IsButtonHovered(), true, false);
		}
		else
		{
			OnButtonFocusedHandled(Widget, false, true, false);
		}
	}

	UFUNCTION()
	void OnMenuTabButtonClicked(UMenuTabButtonWidget Widget)
	{
		auto OptionsWidget = Cast<UOptionsMenuTabButton>(Widget);

		#if TEST
		if (IsDebugging())
			PrintToScreen(f"OnMenuTabButtonClicked {GetMenuTabButtonName(OptionsWidget)}", Duration = 10);
		#endif

		OnButtonClick(GetMenuTabButtonName(OptionsWidget), false);
	}

	UFUNCTION()
	void OnMenuTabButtonFocused(UMenuTabButtonWidget Widget)
	{
		auto OptionsWidget = Cast<UOptionsMenuTabButton>(Widget);
		auto Position = GetElementPosition(Widget);

		#if TEST
		if (IsDebugging())
		{
			PrintToScreen(f"OnMenuTabButtonFocused {GetMenuTabButtonName(OptionsWidget)}- Ignored: {Widget.bIsActiveTab} - {Position}", Duration = 10);
		}
		#endif
		
		UpdateLastWidgetAndCompareVerticalMovement(Widget);

		if (Widget.bIsActiveTab)
			return;
		
		// OnButtonFocus(GetMenuTabButtonName(OptionsWidget), true, EHazeUIPosition::None);
		OnMenuTabButtonFocus();
	}

	UFUNCTION(BlueprintEvent)
	void OnMenuTabButtonFocus() {}

	FName GetMenuTabButtonName(const UOptionsMenuTabButton TabButton) const
	{
		auto OptionsWidget = Cast<UMainMenuOptions>(TabButton.GetParent());
		if (OptionsWidget == nullptr)
			return NAME_None;
		
		// TODO: Convert to array of fnames or use enum.
		return OptionsWidget.OptionsMenu.Pages[TabButton.TabIndex].DefaultObject.Name;
	}

	UFUNCTION()
	void OnOptionButtonFocused(UOptionWidget Widget)
	{
		auto Position = GetElementPosition(Widget);
		
		#if TEST
		if (IsDebugging())
			PrintToScreen(f"OnMenuTabButtonFocused {Widget.Name} - {Position}", Duration = 10);
		#endif

		UpdateLastWidgetAndCompareVerticalMovement(Widget);
		OnButtonFocus(Widget.Name, Widget.bFocusedByMouse, Position, false);
	}

	UFUNCTION()
	void OnMenuArrowButtonClicked(UMenuArrowButtonWidget Widget)
	{
		#if TEST
		if (IsDebugging())
			PrintToScreen(f"OnMenuArrowButtonClicked {Widget} - {Widget.DesiredSize}", Duration = 10);
		#endif

		OnArrowButtonClick(Widget.Name, Widget.bHovered);
	}

	UFUNCTION()
	void OnMenuArrowButtonFocused(UMenuArrowButtonWidget Widget)
	{
		#if TEST
		if (IsDebugging())
			PrintToScreen(f"OnMenuArrowButtonFocused {Widget}", Duration = 10);
		#endif

		OnArrowButtonFocus(Widget.Name, true);
	}

	UFUNCTION()
	void OnChapterSelectButtonClicked(UChapterSelectItemWidget Widget)
	{
		#if TEST
		if (IsDebugging())
			PrintToScreen(f"OnChapterSelectButtonClicked {Widget}", Duration = 10);
		#endif

		OnChapterSelectButtonClick(Widget.Name, Widget.bHovered);
	}

	UFUNCTION()
	void OnChapterSelectButtonFocused(UChapterSelectItemWidget Widget)
	{
		#if TEST
		if (IsDebugging())
			PrintToScreen(f"OnChapterSelectButtonFocused {Widget}", Duration = 10);
		#endif

		UpdateLastWidgetAndCompareVerticalMovement(Widget);
		OnChapterSelectButtonFocus(Widget.Name, Widget.bHovered);
	}

	UFUNCTION()
	void OnDotIndicatorClicked(UOptionEnumDotIndicator Widget)
	{
		auto Position = GetElementPosition(Widget);

		#if TEST
		if (IsDebugging())
			PrintToScreen(f"OnDotIndicatorClicked {Widget} - {Position}", Duration = 10);
		#endif

		OnDotIndicatorClick(Widget.Name, Widget.bHovered);
	}

	UFUNCTION()
	void OnDotIndicatorFocused(UOptionEnumDotIndicator Widget)
	{
		auto Position = GetElementPosition(Widget);

		#if TEST
		if (IsDebugging())
			PrintToScreen(f"OnDotIndicatorFocused {Widget} - {Position}", Duration = 10);
		#endif

		OnDotIndicatorFocus(Widget.Name, Widget.bHovered);
	}
	
	UFUNCTION()
	private void OnLobbyButtonClicked(UMenuButtonWidget Button)
	{
		#if TEST
		if (IsDebugging())
			PrintToScreen(f"OnLobbyButtonClicked: {Button.Name}", Duration = 10);
		#endif

		OnLobbyButtonClick(Button.Name, Button.bFocusedByMouse);
	}

	UFUNCTION()
	private void OnLobbyButtonFocused(UMenuButtonWidget Button)
	{
		auto Position = GetElementPosition(Button);

		#if TEST
		if (IsDebugging())
			PrintToScreen(f"OnLobbyButtonFocused: {Button.Name} - {Position}", Duration = 10);
		#endif

		UpdateLastWidgetAndCompareVerticalMovement(Button);
		OnLobbyButtonFocus(Button.Name, Button.bFocusedByMouse, Position);
	}

	UFUNCTION()
	private void OnDefaultClick(FMenuActionData Data)
	{
		OnButtonClickedHandled(Data.Widget, Data.bMouseInput, false, false);
	}

	UFUNCTION()
	private void OnDefaultHover(FMenuActionData Data)
	{
		OnButtonFocusedHandled(Data.Widget, Data.bMouseInput, false, false);
	}

	// APPLIED

	UFUNCTION()
	private void OnOptionsEnumApplied(UOptionWidget Widget)
	{
		OnOptionsEnumApply(Widget.Name, Widget.bHovered);
	}
	
	UFUNCTION()
	private void OnSliderValueApplied(UOptionSliderWidget Widget)
	{
		OnSliderValueApply(Widget.Name, Widget.bHovered);
	}

	//

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLastFocusLost() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnButtonClick(const FName& ButtonName, const bool bFocusedByMouse) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnButtonBackClick(FName ButtonName, bool bFocusedByMouse)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnButtonProceedClick(FName ButtonName, bool bFocusedByMouse)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnButtonFocus(const FName& ButtonName, const bool bFocusedByMouse, EHazeUIPosition Position, bool bAnimated) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnButtonBackFocus(FName ButtonName, bool bFocusedByMouse, EHazeUIPosition Position, bool bAnimated)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnButtonProceedFocus(FName ButtonName, bool bFocusedByMouse, EHazeUIPosition Position, bool bAnimated)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnArrowButtonClick(const FName& ButtonName, const bool bFocusedByMouse) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnArrowButtonFocus(const FName& ButtonName, const bool bFocusedByMouse) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChapterSelectButtonClick(const FName& ButtonName, const bool bFocusedByMouse) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChapterSelectButtonFocus(const FName& ButtonName, const bool bFocusedByMouse) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDotIndicatorClick(const FName& ButtonName, const bool bFocusedByMouse) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDotIndicatorFocus(const FName& ButtonName, const bool bFocusedByMouse) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLobbyButtonClick(const FName& ButtonName, const bool bFocusedByMouse) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLobbyButtonFocus(const FName& ButtonName, const bool bFocusedByMouse, EHazeUIPosition Position) {}

	// APPLIED
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOptionsEnumApply(const FName& WidgetName, const bool bFocusedByMouse) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSliderValueApply(const FName& WidgetName, const bool bFocusedByMouse) {}
}