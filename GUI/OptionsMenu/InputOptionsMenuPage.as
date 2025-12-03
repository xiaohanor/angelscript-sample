

TArray<FKey> MakeInvalidKeys()
{
	TArray<FKey> InvalidKeys;
	InvalidKeys.Add(EKeys::Gamepad_LeftStick_Up);
	InvalidKeys.Add(EKeys::Gamepad_LeftStick_Down);
	InvalidKeys.Add(EKeys::Gamepad_LeftStick_Left);
	InvalidKeys.Add(EKeys::Gamepad_LeftStick_Right);
	InvalidKeys.Add(EKeys::Gamepad_RightStick_Up);
	InvalidKeys.Add(EKeys::Gamepad_RightStick_Down);
	InvalidKeys.Add(EKeys::Gamepad_RightStick_Left);
	InvalidKeys.Add(EKeys::Gamepad_RightStick_Right);
	return InvalidKeys;
}

const TArray<FKey> INVALID_KEYS = MakeInvalidKeys();

class UInputOptionsMenuPage : UOptionsMenuPage
{
	UPROPERTY(BindWidget)
	UScrollBox ScrollList;
	UPROPERTY(BindWidget)
	UOptionButtonWidget ResetButton;
	UPROPERTY(BindWidget)
	UWidget KeyboardInputLabel;
	UPROPERTY(BindWidget)
	UWidget KeyboardInputHeading;

	UPROPERTY()
	TSubclassOf<UKeybindOptionWidget> KeybindWidget;

	TArray<UHazeKeyBindSetting> KeybindSettings;
	TArray<UKeybindOptionWidget> KeybindWidgets;
	UKeybindOptionWidget FocusedKeybind;
	EHazeKeybindType FocusedKeybindType = EHazeKeybindType::Keyboard;

	UKeybindOptionWidget ChangingBind;
	UKeybindInputBox ChangingInput;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		Super::Construct();

		GameSettings::GetAllKeyBindingSettingsDescriptions(KeybindSettings);

		// Create widgets for all mappable keybinds
		for (UHazeKeyBindSetting Keybind : KeybindSettings)
		{
			auto Widget = Cast<UKeybindOptionWidget>(Widget::CreateWidget(this, KeybindWidget));
			Widget.MenuPage = this;
			Widget.Setting = Keybind;
			Widget.OnKeybindFocused.AddUFunction(this, n"OnFocusedKeybindRow");

			ScrollList.AddChild(Widget);
			Widget.Init();

			KeybindWidgets.Add(Widget);
		}

		ResetButton.RemoveFromParent();
		ScrollList.AddChild(ResetButton);
		ResetButton.OnClicked.AddUFunction(this, n"OnResetClicked");

		FMargin ResetPadding;
		ResetPadding.Top = 20.0;
		Cast<UScrollBoxSlot>(ResetButton.Slot).SetPadding(ResetPadding);

		UpdateInvalidBinds(EHazeKeybindType::Keyboard);
		UpdateInvalidBinds(EHazeKeybindType::MioController);
		UpdateInvalidBinds(EHazeKeybindType::ZoeController);

		if (!ShouldShowKeyboardBinds())
		{
			KeyboardInputHeading.Visibility = ESlateVisibility::Hidden;
			FocusedKeybindType = EHazeKeybindType::MioController;
		}
	}

	bool ShouldShowKeyboardBinds() const
	{
		return !Game::IsConsoleBuild();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		if (FocusedOption != nullptr && FocusedOption.IsVisible())
			return FEventReply::Handled().SetUserFocus(FocusedOption, InFocusEvent.Cause);

		// On console none of the first few 'real' options are available, so we need to focus a keybind first
		// OBS! Change this if we add any options to the top of the page that are available on console!
		if (Game::IsConsoleBuild())
		{
			for (auto BindWidget : KeybindWidgets)
			{
				if (BindWidget.IsVisible())
					return FEventReply::Handled().SetUserFocus(BindWidget, InFocusEvent.Cause);
			}
		}
		else
		{
			for (auto Option : Options)
			{
				if (Option.IsVisible())
					return FEventReply::Handled().SetUserFocus(Option, InFocusEvent.Cause);
			}
		}

		return FEventReply::Unhandled();
	}

	void ResetOptionsToDefault() override
	{
		Super::ResetOptionsToDefault();
		OnResetConfirm();
	}

	UFUNCTION()
	private void OnResetClicked()
	{
		FMessageDialog Dialog;
		Dialog.Message = NSLOCTEXT("OptionsMenu", "ResetInputMessage", "This will reset all customized input bindings.");
		Dialog.AddOption(
			NSLOCTEXT("OptionsMenu", "ConfirmResetInput", "Reset All Bindings"),
			FOnMessageDialogOptionChosen(this, n"OnResetConfirm")
		);
		Dialog.AddCancelOption();
		ShowPopupMessage(Dialog, this);
	}

	UFUNCTION()
	void OnResetConfirm()
	{
		for (int i = 0; i < 3; ++i)
		{
			for (auto Bind : KeybindWidgets)
			{
				auto Input = Bind.GetInputBox(EHazeKeybindType(i));
				if (Input != nullptr)
					Input.ResetBind();
			}
		}
		GameSettings::ApplyGameSettingsKeyBindings();

		for (int i = 0; i < 3; ++i)
			UpdateInvalidBinds(EHazeKeybindType(i));
	}

	void RefreshSettings() override
	{
		Super::RefreshSettings();

		for (auto Bind : KeybindWidgets)
			Bind.Refresh();
	}

	UFUNCTION(BlueprintOverride)
	void Destruct()
	{
		if (ChangingBind != nullptr)
			StopChangingBind();
	}

	UFUNCTION()
	private void OnFocusedKeybindRow(UKeybindOptionWidget Widget)
	{
		FocusedKeybind = Widget;
		FocusedOption = nullptr;
		OnOptionFocused.Broadcast(nullptr);

		if (Widget != nullptr && Widget.GetInputBox(FocusedKeybindType) == nullptr)
		{
			for (int i = 0; i < 3; ++i)
			{
				if (Widget.GetInputBox(EHazeKeybindType(i)) != nullptr)
					FocusedKeybindType = EHazeKeybindType(i);
			}
		}
	}

	void OnFocusedOptionRow(UOptionWidget Widget) override
	{
		Super::OnFocusedOptionRow(Widget);
		FocusedKeybind = nullptr;
	}

	void StartChangingBind(UKeybindOptionWidget Option, UKeybindInputBox Input)
	{
		if (ChangingBind != nullptr)
			StopChangingBind();

		ChangingBind = Option;
		ChangingInput = Input;

		Input.StartChanging();
		
		Game::HazeGameInstance.bIsCapturingKeybind = true;
	}

	void StopChangingBind()
	{
		if (ChangingBind == nullptr)
			return;

		ChangingInput.StopChanging();

		ChangingBind = nullptr;
		ChangingInput = nullptr;

		Game::HazeGameInstance.bIsCapturingKeybind = false;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnPreviewKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (ChangingBind != nullptr)
		{
			if (ChangingInput.ShouldCancelBind(InKeyEvent.Key))
			{
				StopChangingBind();
				return FEventReply::Handled();
			}

			if (ChangingInput.IsValidBind(InKeyEvent.Key))
			{
				ChangingInput.SetBind(InKeyEvent.Key);
				UpdateInvalidBinds(ChangingInput.Type);
				StopChangingBind();
			}

			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnPreviewMouseButtonDown(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (ChangingBind != nullptr)
		{
			if (ChangingInput.IsValidBind(MouseEvent.EffectingButton))
			{
				ChangingInput.SetBind(MouseEvent.EffectingButton);
				UpdateInvalidBinds(ChangingInput.Type);
				StopChangingBind();
			}

			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	void RemoveExistingBind(EHazeKeybindType Type, FKey Key)
	{
		for (auto Bind : KeybindWidgets)
		{
			auto Input = Bind.GetInputBox(Type);
			if (Input != nullptr && Input.BoundKey == Key)
				Input.SetBind(FKey());
		}
	}

	void UpdateInvalidBinds(EHazeKeybindType Type)
	{
		TMap<FKey, FName> KeyToSetting;
		TArray<FName> InvalidSettings;

		for (auto Bind : KeybindWidgets)
		{
			auto Input = Bind.GetInputBox(Type);
			if (Input != nullptr && Input.BoundKey.IsValid())
			{
				FName Setting = Input.Setting.Id;
				if (KeyToSetting.Contains(Input.BoundKey))
				{
					FName PrevSetting = KeyToSetting[Input.BoundKey];
					if (!InputOptions::IsAllowedOverlappingBind(PrevSetting, Setting) && !InputOptions::IsAllowedOverlappingBind(Setting, PrevSetting))
					{
						// Both keys become invalid if the overlap is not allowed
						InvalidSettings.Add(PrevSetting);
						InvalidSettings.Add(Setting);
					}
				}

				KeyToSetting.Add(Input.BoundKey, Setting);
			}
		}

		for (auto Bind : KeybindWidgets)
		{
			auto Input = Bind.GetInputBox(Type);
			if (Input != nullptr)
			{
				if (!Input.BoundKey.IsValid())
					Input.bInvalid = true;
				else if (InvalidSettings.Contains(Input.Setting.Id))
					Input.bInvalid = true;
				else
					Input.bInvalid = false;
			}
		}
	}
};

event void FOnKeybindFocused(UKeybindOptionWidget Widget);

UCLASS(Abstract)
class UKeybindOptionWidget : UHazeUserWidget
{
	default bCustomNavigation = true;

	UInputOptionsMenuPage MenuPage;
	UHazeKeyBindSetting Setting;
	FOnKeybindFocused OnKeybindFocused;
	FOnKeybindFocused OnMouseHovered;
	FOnKeybindFocused OnClicked;

	UPROPERTY(BindWidget)
	UMenuSelectionHighlight SelectionHighlight;

	UPROPERTY(BindWidget)
	UHazeTextWidget LabelText;

	UPROPERTY(BindWidget)
	UKeybindInputBox KeyboardInput;

	UPROPERTY(BindWidget)
	UKeybindInputBox MioInput;

	UPROPERTY(BindWidget)
	UKeybindInputBox ZoeInput;

	FKey KeyboardKey;
	FKey MioKey;
	FKey ZoeKey;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
	}

	void Init()
	{
		LabelText.Text = Setting.DisplayName;
		LabelText.Update();

		KeyboardInput.InputButton.OverrideControllerType = EHazePlayerControllerType::Keyboard;

		KeyboardInput.UpdateInput(Setting, EHazeKeybindType::Keyboard);
		MioInput.UpdateInput(Setting, EHazeKeybindType::MioController);
		ZoeInput.UpdateInput(Setting, EHazeKeybindType::ZoeController);

		if (!Setting.bHasControllerBind)
		{
			MioInput.SetVisibility(ESlateVisibility::Hidden);
			ZoeInput.SetVisibility(ESlateVisibility::Hidden);
		}

		KeyboardInput.OnClicked.AddUFunction(this, n"OnInputBoxClicked");
		MioInput.OnClicked.AddUFunction(this, n"OnInputBoxClicked");
		ZoeInput.OnClicked.AddUFunction(this, n"OnInputBoxClicked");

		if (!MenuPage.ShouldShowKeyboardBinds())
		{
			KeyboardInput.Visibility = ESlateVisibility::Hidden;
			if (!Setting.bHasControllerBind)
				SetVisibility(ESlateVisibility::Collapsed);
		}
	}

	void Refresh()
	{
		KeyboardInput.UpdateInput(Setting, EHazeKeybindType::Keyboard);
		KeyboardInput.bInvalid = false;
		MioInput.UpdateInput(Setting, EHazeKeybindType::MioController);
		MioInput.bInvalid = false;
		ZoeInput.UpdateInput(Setting, EHazeKeybindType::ZoeController);
		ZoeInput.bInvalid = false;
	}

	UKeybindInputBox GetInputBox(EHazeKeybindType Type)
	{
		switch (Type)
		{
			case EHazeKeybindType::Keyboard:
				return KeyboardInput;
			case EHazeKeybindType::MioController:
			{
				if (Setting.bHasControllerBind)
					return MioInput;
				else
					return nullptr;
			}
			case EHazeKeybindType::ZoeController:
			{
				if (Setting.bHasControllerBind)
					return ZoeInput;
				else
					return nullptr;
			}
		}
	}

	UFUNCTION()
	private void OnInputBoxClicked(UKeybindInputBox InputBox)
	{
		MenuPage.StartChangingBind(this, InputBox);
		OnClicked.Broadcast(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		MioInput.UpdateController(Game::Mio);
		ZoeInput.UpdateController(Game::Zoe);

		if (IsHoveredOrActive())
		{
			SelectionHighlight.bIsHighlighted = true;

			if (SelectionHighlight.bIsZoe || SelectionHighlight.bIsNeutral)
			{
				LabelText.SetColorAndOpacity(FLinearColor::Black);
			}
		}
		else
		{
			SelectionHighlight.bIsHighlighted = false;

			if (SelectionHighlight.bIsZoe || SelectionHighlight.bIsNeutral)
			{
				LabelText.SetColorAndOpacity(FLinearColor::White);
			}
		}
	}

	UPROPERTY(BlueprintReadOnly)
	bool bFocused = false;

	UPROPERTY(BlueprintReadOnly)
	bool bFocusedByMouse = false;

	UPROPERTY(BlueprintReadOnly)
	bool bHovered = false;

	UFUNCTION(BlueprintPure)
	bool IsHoveredOrActive()
	{
		if (bHovered && bFocused)
			return true;
		if (bFocused && !bFocusedByMouse)
			return true;
		return false;
	}

	void UpdateInputsActive()
	{
		KeyboardInput.UpdateActive(bFocused, bFocusedByMouse, MenuPage.FocusedKeybindType);
		ZoeInput.UpdateActive(bFocused, bFocusedByMouse, MenuPage.FocusedKeybindType);
		MioInput.UpdateActive(bFocused, bFocusedByMouse, MenuPage.FocusedKeybindType);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		bFocused = true;
		bFocusedByMouse = (InFocusEvent.Cause == EFocusCause::Mouse);
		OnKeybindFocused.Broadcast(this);
		UpdateInputsActive();
		return FEventReply::Handled();
	}

	UFUNCTION(BlueprintOverride)
	void OnFocusLost(FFocusEvent InFocusEvent)
	{
		bFocused = false;
		UpdateInputsActive();
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseEnter(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.CursorDelta.IsNearlyZero())
			return;
		bHovered = true;

		if (HasAnyUserFocus())
			OnMouseHovered.Broadcast(this);

		Widget::SetAllPlayerUIFocus(this, EFocusCause::Mouse);
	}

	EHazeKeybindType GetFocusedKeybindType()
	{
		if (KeyboardInput.bHovered)
			return KeyboardInput.Type;
		if (MioInput.bHovered)
			return MioInput.Type;
		if (ZoeInput.bHovered)
			return ZoeInput.Type;
		return MenuPage.FocusedKeybindType;
	}

	UFUNCTION(BlueprintOverride)
	UWidget OnCustomNavigation(FGeometry Geometry, FNavigationEvent Event, EUINavigationRule& OutRule)
	{
		if (Event.NavigationType == EUINavigation::Left)
		{
			int MinBindType = MenuPage.ShouldShowKeyboardBinds() ? 0 : 1;
			auto NewKeybindType = EHazeKeybindType(Math::Clamp(int(GetFocusedKeybindType())-1, MinBindType, 2));
			if (GetInputBox(NewKeybindType) != nullptr)
				MenuPage.FocusedKeybindType = NewKeybindType;
			bFocusedByMouse = false;
			UpdateInputsActive();
			OutRule = EUINavigationRule::Stop;
			return this;
		}
		else if (Event.NavigationType == EUINavigation::Right)
		{
			int MinBindType = MenuPage.ShouldShowKeyboardBinds() ? 0 : 1;
			auto NewKeybindType = EHazeKeybindType(Math::Clamp(int(GetFocusedKeybindType())+1, MinBindType, 2));
			if (GetInputBox(NewKeybindType) != nullptr)
				MenuPage.FocusedKeybindType = NewKeybindType;
			bFocusedByMouse = false;
			UpdateInputsActive();
			OutRule = EUINavigationRule::Stop;
			return this;
		}

		OutRule = EUINavigationRule::Escape;
		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (InKeyEvent.Key == EKeys::Enter || InKeyEvent.Key == EKeys::Virtual_Accept)
		{
			if (bFocused && MenuPage.ChangingBind == nullptr)
			{
				auto Input = GetInputBox(MenuPage.FocusedKeybindType);
				if (Input != nullptr)
				{
					MenuPage.StartChangingBind(this, Input);
					OnClicked.Broadcast(this);
					return FEventReply::Handled();
				}
			}
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseLeave(FPointerEvent MouseEvent)
	{
		bHovered = false;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseMove(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.CursorDelta.IsNearlyZero())
			return FEventReply::Unhandled();
		return FEventReply::Unhandled().SetUserFocus(this, EFocusCause::Mouse);
	}
};

event void FOnKeybindInputBoxClicked(UKeybindInputBox InputBox);
event void FOnKeybindInputChange(UKeybindInputBox InputBox, bool bStart);

class UKeybindInputBox : UHazeUserWidget
{
	UHazeKeyBindSetting Setting;
	EHazeKeybindType Type;
	FKey BoundKey;
	FOnKeybindInputBoxClicked OnClicked;
	FOnKeybindInputChange OnInputChange;

	UPROPERTY(BindWidget)
	UBorder BackgroundBrush;
	UPROPERTY(BindWidget)
	UInputButtonWidget InputButton;
	UPROPERTY(BindWidget)
	UWidget Prompt;

	UPROPERTY()
	bool bHovered = false;
	UPROPERTY()
	bool bPressed = false;
	UPROPERTY()
	bool bChanging = false;
	UPROPERTY()
	bool bInvalid = false;
	UPROPERTY()
	bool bActive = false;

	UFUNCTION(BlueprintPure)
	bool IsHoveredOrActive()
	{
		if (bHovered)
			return true;
		if (bActive)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (bChanging)
		{
			float Alpha = Math::MakePulsatingValue(Time::RealTimeSeconds, 0.85);
			FLinearColor NormalColor = FLinearColor(1, 1, 1, 0.5);
			FLinearColor BlinkColor = FLinearColor(1, 1, 1, 1);
			BackgroundBrush.SetBrushColor(Math::Lerp(NormalColor, BlinkColor, Alpha));
		}
		else if (bInvalid)
		{
			if (IsHoveredOrActive())
				BackgroundBrush.SetBrushColor(FLinearColor(1.00, 0.20, 0.20, 0.6));
			else
				BackgroundBrush.SetBrushColor(FLinearColor(1.00, 0.00, 0.00, 0.5));
		}
		else
		{
			if (IsHoveredOrActive())
				BackgroundBrush.SetBrushColor(FLinearColor(1, 1, 1, 0.9));
			else
				BackgroundBrush.SetBrushColor(FLinearColor(0.13, 0.13, 0.13, 0.4));
		}
	}

	void UpdateInput(UHazeKeyBindSetting KeybindSetting, EHazeKeybindType KeybindType)
	{
		Setting = KeybindSetting;
		Type = KeybindType;

		FKey Key;
		GameSettings::GetKeybindValue(Setting.Id, Type, Key);

		InputButton.OverrideKey = Key;
		BoundKey = Key;

		if (Key.IsValid() && !bChanging)
			InputButton.SetVisibility(ESlateVisibility::HitTestInvisible);
		else
			InputButton.SetVisibility(ESlateVisibility::Hidden);

		if (Type == EHazeKeybindType::MioController)
		{
			InputButton.OverridePlayer = EHazeSelectPlayer::Mio;
			InputButton.OnChangeButtonColor(PlayerColor::Mio);
		}
		else if (Type == EHazeKeybindType::ZoeController)
		{
			InputButton.OverridePlayer = EHazeSelectPlayer::Zoe;
			InputButton.OnChangeButtonColor(PlayerColor::Zoe);
		}
	}

	void UpdateActive(bool bFocused, bool bFocusedByMouse, EHazeKeybindType FocusedType)
	{
		if (bFocused && !bFocusedByMouse && FocusedType == Type)
			bActive = true;
		else
			bActive = false;

		if (bFocused && !bFocusedByMouse)
			bHovered = false;
	}

	void StartChanging()
	{
		if (!bChanging)
		{
			OnInputChange.Broadcast(this, true);
		}

		bChanging = true;
		InputButton.SetVisibility(ESlateVisibility::Hidden);
		Prompt.SetVisibility(ESlateVisibility::HitTestInvisible);
	}

	void StopChanging()
	{
		if (bChanging)
		{
			OnInputChange.Broadcast(this, false);
		}

		bChanging = false;
		InputButton.SetVisibility(ESlateVisibility::HitTestInvisible);
		Prompt.SetVisibility(ESlateVisibility::Hidden);
		UpdateInput(Setting, Type);
	}

	bool ShouldCancelBind(FKey Key) const
	{
		if (Key.IsAxis1D() || Key.IsAxis2D() || Key.IsAxis3D())
			return false;
		if (Key.IsTouch())
			return false;
		if (Type == EHazeKeybindType::Keyboard)
		{
			if (Key.IsGamepadKey())
				return true;
			if (Key == EKeys::Escape)
				return true;
		}
		else
		{
			if (!Key.IsGamepadKey())
				return true;
			if (Key == EKeys::Gamepad_Special_Left)
				return true;
			if (Key == EKeys::Gamepad_Special_Right)
				return true;
		}

		return false;
	}

	bool IsValidBind(FKey Key) const
	{
		if (Key.IsAxis1D() || Key.IsAxis2D() || Key.IsAxis3D())
			return false;
		if (Key.IsTouch())
			return false;
		if (INVALID_KEYS.Contains(Key))
			return false;
		if (Type == EHazeKeybindType::Keyboard)
		{
			if (Key.IsGamepadKey())
				return false;
			if (Key == EKeys::Escape)
				return false;
			return true;
		}
		else
		{
			if (!Key.IsGamepadKey())
				return false;
			if (Key == EKeys::Gamepad_Special_Left)
				return false;
			if (Key == EKeys::Gamepad_Special_Right)
				return false;
			return true;
		}
	}

	void SetBind(FKey Key)
	{
		GameSettings::SetKeybindValue(Setting.Id, Type, Key);
		GameSettings::ApplyGameSettingsKeyBindings();
		UpdateInput(Setting, Type);
	}

	void ResetBind()
	{
		FKey DefaultKey = Setting.KeyboardDefault;
		if (Type != EHazeKeybindType::Keyboard)
			DefaultKey = Setting.ControllerDefault;

		GameSettings::SetKeybindValue(Setting.Id, Type, DefaultKey);
		UpdateInput(Setting, Type);
		bInvalid = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseEnter(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.CursorDelta.IsNearlyZero())
			return;
		bHovered = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseLeave(FPointerEvent MouseEvent)
	{
		bHovered = false;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.EffectingButton == EKeys::LeftMouseButton && !MouseEvent.IsRepeat())
		{
			bPressed = true;
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonUp(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.EffectingButton == EKeys::LeftMouseButton && !MouseEvent.IsRepeat())
		{
			if (bPressed)
			{
				bPressed = false;
				OnClicked.Broadcast(this);
			}
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	void UpdateController(AHazePlayerCharacter InputPlayer)
	{
		if (InputPlayer != nullptr)
		{
			if (InputPlayer.HasControl())
			{
				auto InputComp = UHazeInputComponent::Get(InputPlayer);
				InputButton.OverrideControllerType = InputComp.GetControllerType();
			}
			else
			{
				auto InputComp = UHazeInputComponent::Get(InputPlayer.OtherPlayer);
				InputButton.OverrideControllerType = InputComp.GetControllerType();
			}
		}
		
		if (InputPlayer == nullptr || InputButton.OverrideControllerType == EHazePlayerControllerType::Keyboard)
		{
			auto LikelyType = Lobby::GetMostLikelyControllerType();
			if (LikelyType != EHazePlayerControllerType::Keyboard)
				InputButton.OverrideControllerType = LikelyType;
			if (InputButton.OverrideControllerType == EHazePlayerControllerType::None || InputButton.OverrideControllerType == EHazePlayerControllerType::Keyboard)
				InputButton.OverrideControllerType = EHazePlayerControllerType::Xbox;
		}
	}
};

namespace InputOptions
{
	bool IsAllowedOverlappingBind(FName PrevSetting, FName Setting)
	{
		// Some keybinds are allowed to be bound to the same button.
		// We just hardcode these settings here for now since we only need it for UI purposes.
		if (PrevSetting == n"MoveUp" || PrevSetting == n"MoveDown")
		{
			if (Setting == n"MovementJump" || Setting == n"Cancel")
				return true;
		}

		return false;
	}
}