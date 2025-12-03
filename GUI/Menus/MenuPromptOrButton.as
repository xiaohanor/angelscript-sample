event void FOnMenuPromptPressed(UHazeUserWidget Widget);

enum EMenuPromptState
{
	ClickableOnly,
	ButtonPromptOnly,
	ClickableWithKeyboardPrompt,
	ClickableWithControllerPrompt,
	Hidden,
};

UCLASS(Abstract)
class UMenuPromptOrButton : UHazeUserWidget
{
	default Visibility = ESlateVisibility::Visible;

	UPROPERTY(EditAnywhere, Category = "Menu Prompt Or Button")
	FText Text;

	UPROPERTY(EditAnywhere, Category = "Menu Prompt Or Button")
	FKey PromptKey;

	UPROPERTY(EditAnywhere, Category = "Menu Prompt Or Button")
	EHazeSpecialInputButton PromptSpecialButton = EHazeSpecialInputButton::None;

	UPROPERTY(EditAnywhere, Category = "Menu Prompt Or Button")
	bool bCanBeClicked = true;

	UPROPERTY(EditAnywhere, Category = "Menu Prompt Or Button")
	bool bDisabled = false;

	UPROPERTY(EditAnywhere, Category = "Menu Prompt Or Button")
	bool bAlwaysApplyMinimumSize = true;
	UPROPERTY(EditAnywhere, Category = "Menu Prompt Or Button")
	int MinimumButtonSize = 160;

	// To support UI implemented only in BP. 
	// Yes, should have been like this from the start.
	UPROPERTY(EditAnywhere, Category = "Audio")
	bool bTriggerEffectEvents = false; 

	UPROPERTY(BindWidget)
	USizeBox RootSizeBox;

	UPROPERTY(BindWidget)
	UHazeTextWidget TextWidget;

	UPROPERTY(BindWidget)
	UWidget ButtonIconContainer;

	UPROPERTY(BindWidget)
	UWidget AlignSpacer;

	UPROPERTY(BindWidget)
	UScalableSlicedImage ClickableButton;

	UPROPERTY(BindWidget)
	UInputButtonWidget ButtonIcon;

	bool bTriggerOnMouseDown = false;
	bool bHovered = false;
	bool bIsPressed = false;
	private float RepeatTimer = 0.2;

	UPROPERTY()
	UTexture2D ButtonNormalTexture;
	UPROPERTY()
	UTexture2D ButtonHoveredTexture;
	UPROPERTY()
	UTexture2D ButtonPressedTexture;

	UPROPERTY()
	FOnMenuPromptPressed OnPressed;

	UPROPERTY()
	FOnMenuPromptPressed OnRepeat;

	UPROPERTY()
	FOnMenuPromptPressed OnFocused;

	UPROPERTY()
	FOnMenuPromptPressed OnEnabled;

	private bool bWasDisabled = false;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool bIsDesignTime)
	{
		UpdateWidgets();
	}

	void UpdateWidgets()
	{
		TextWidget.Text = Text;
		TextWidget.Update();

		if (PromptKey.IsValid() || PromptSpecialButton != EHazeSpecialInputButton::None)
		{
			ButtonIcon.OverrideKey = PromptKey;
			ButtonIcon.OverrideControllerType = EHazePlayerControllerType::Xbox;
			ButtonIcon.OverrideSpecialButton = PromptSpecialButton;
			ButtonIcon.UpdateKey();
			ButtonIconContainer.SetVisibility(ESlateVisibility::HitTestInvisible);
		}
		else
		{
			ButtonIconContainer.SetVisibility(ESlateVisibility::Collapsed);
		}

		RootSizeBox.SetMinDesiredWidth(MinimumButtonSize);
	}

	void UpdateState()
	{
		ButtonIcon.OverrideKey = PromptKey;
		ButtonIcon.OverrideControllerType = GetControllerType();
	
		if ((PromptKey.IsValid() || PromptSpecialButton != EHazeSpecialInputButton::None) && GetControllerType() != EHazePlayerControllerType::Keyboard)
		{
			ButtonIconContainer.SetVisibility(ESlateVisibility::HitTestInvisible);
			ClickableButton.SetVisibility(ESlateVisibility::Collapsed);
			AlignSpacer.SetVisibility(ESlateVisibility::HitTestInvisible);
			TextWidget.ChangeJustification(ETextJustify::Left);

			if (bAlwaysApplyMinimumSize)
				RootSizeBox.SetMinDesiredWidth(MinimumButtonSize);
			else
				RootSizeBox.SetMinDesiredWidth(0);
		}
		else
		{
			ButtonIconContainer.SetVisibility(ESlateVisibility::Collapsed);
			if (IsClickableByMouse())
			{
				ClickableButton.SetVisibility(ESlateVisibility::HitTestInvisible);
				AlignSpacer.SetVisibility(ESlateVisibility::Collapsed);
				TextWidget.ChangeJustification(ETextJustify::Center);
			}
			else
			{
				ClickableButton.SetVisibility(ESlateVisibility::Collapsed);
				AlignSpacer.SetVisibility(ESlateVisibility::HitTestInvisible);
				TextWidget.ChangeJustification(ETextJustify::Left);
			}

			RootSizeBox.SetMinDesiredWidth(MinimumButtonSize);
		}

		if (IsButtonPressed())
			ClickableButton.SetBrushFromTexture(ButtonPressedTexture);
		else if (IsButtonHovered())
			ClickableButton.SetBrushFromTexture(ButtonHoveredTexture);
		else
			ClickableButton.SetBrushFromTexture(ButtonNormalTexture);

		if (IsButtonPressed())
		{
			TextWidget.SetRenderTranslation(FVector2D(3, 3));
		}
		else
		{
			TextWidget.SetRenderTranslation(FVector2D(0, 0));
		}

		if (bDisabled)
		{
			ClickableButton.SetRenderOpacity(1.0);
			ClickableButton.SetBrushColor(FLinearColor(0.1, 0.1, 0.1));
			ButtonIcon.SetRenderOpacity(0.25);
			TextWidget.SetRenderOpacity(0.4);
			TextWidget.SetColorAndOpacity(FLinearColor(1.0, 1.0, 1.0));

			if (!bWasDisabled)
			{
				bWasDisabled = true;
				OnEnabled.Broadcast(this);
			}
		}
		else
		{
			ClickableButton.SetRenderOpacity(1.0);
			ClickableButton.SetBrushColor(FLinearColor(1.0, 1.0, 1.0));
			ButtonIcon.SetRenderOpacity(1.0);
			TextWidget.SetRenderOpacity(1.0);
			TextWidget.SetColorAndOpacity(FLinearColor(1.0, 1.0, 1.0));
			bWasDisabled = false;
		}
	}

	UFUNCTION()
	void Update()
	{
		UpdateWidgets();
		BP_Update();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Update() {}

	UFUNCTION(BlueprintPure)
	bool IsButtonHovered()
	{
		return bHovered && bCanBeClicked;
	}

	UFUNCTION(BlueprintPure)
	bool IsButtonPressed()
	{
		return bIsPressed && bCanBeClicked;
	}

	UFUNCTION(BlueprintPure)
	bool IsClickableByMouse()
	{
		return !Game::IsConsoleBuild() && bCanBeClicked;
	}

	UFUNCTION(BlueprintPure)
	bool IsUsableByController()
	{
		return PromptKey.IsValid() || PromptSpecialButton != EHazeSpecialInputButton::None;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (bIsPressed)
		{
			RepeatTimer -= InDeltaTime;
			if (RepeatTimer <= 0.0)
			{
				OnRepeat.Broadcast(this);
				RepeatTimer = 0.1;
			}
		}
		UpdateState();
	}

	EHazePlayerControllerType GetControllerType()
	{
		if (Player != nullptr)
		{
			auto InputComp = UHazeInputComponent::Get(Player);
			if (InputComp != nullptr && InputComp.ControllerType != EHazePlayerControllerType::Keyboard)
				return InputComp.ControllerType;
		}

		EHazePlayerControllerType Type = Lobby::GetMostLikelyControllerType();
		if (Type == EHazePlayerControllerType::Keyboard && !IsClickableByMouse())
			return EHazePlayerControllerType::Xbox;
		return Type;
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseEnter(FGeometry Geom, FPointerEvent MouseEvent)
	{
		if (MouseEvent.CursorDelta.IsNearlyZero())
			return;

		if (!bDisabled)
		{
			bHovered = true;
			OnFocused.Broadcast(this);

			if (bTriggerEffectEvents)
				UMenuEffectEventHandler::Trigger_OnDefaultHover(Menu::GetAudioActor(), FMenuActionData(this, true));
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseLeave(FPointerEvent MouseEvent)
	{
		bHovered = false;
		bIsPressed = false;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseMove(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.CursorDelta.IsNearlyZero())
			return FEventReply::Unhandled();

		if (!bDisabled && !bHovered)
		{
			bHovered = true;
			OnFocused.Broadcast(this);

			if (bTriggerEffectEvents)
				UMenuEffectEventHandler::Trigger_OnDefaultHover(Menu::GetAudioActor(), FMenuActionData(this, true));
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry Geom, FPointerEvent Event)
	{
		if (Event.EffectingButton == EKeys::LeftMouseButton && !bDisabled)
		{
			bIsPressed = true;
			RepeatTimer = 0.5;
			if (bTriggerOnMouseDown)
			{
				OnPressed.Broadcast(this);
				if (bTriggerEffectEvents)
					UMenuEffectEventHandler::Trigger_OnDefaultClick(Menu::GetAudioActor(), FMenuActionData(this, IsHovered()));
			}
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDoubleClick(FGeometry InMyGeometry, FPointerEvent Event)
	{
		if (Event.EffectingButton == EKeys::LeftMouseButton && !bDisabled)
		{
			bIsPressed = true;
			RepeatTimer = 0.5;
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonUp(FGeometry Geom, FPointerEvent Event)
	{
		if (Event.EffectingButton == EKeys::LeftMouseButton && bIsPressed && !bDisabled)
		{
			if (!bTriggerOnMouseDown)
			{
				OnPressed.Broadcast(this);
				if (bTriggerEffectEvents)
					UMenuEffectEventHandler::Trigger_OnDefaultClick(Menu::GetAudioActor(), FMenuActionData(this, IsHovered()));
			}
			
			bIsPressed = false;
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}
};
