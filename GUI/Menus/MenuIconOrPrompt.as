class UMenuIconOrPrompt : UHazeUserWidget
{
	default Visibility = ESlateVisibility::Visible;

	UPROPERTY(EditAnywhere, Category = "Menu Prompt Or Icon Button")
	UTexture2D IconButtonTexture;

	UPROPERTY(EditAnywhere, Category = "Menu Prompt Or Icon Button")
	FKey PromptKey;

	UPROPERTY(EditAnywhere, Category = "Menu Prompt Or Icon Button")
	bool bCanBeClicked = true;

	UPROPERTY(BindWidget)
	UWidget ButtonIconContainer;

	UPROPERTY(BindWidget)
	UBorder ClickableButton;

	UPROPERTY(BindWidget)
	UInputButtonWidget ButtonIcon;

	bool bTriggerOnMouseDown = false;
	private bool bHovered = false;
	private bool bIsPressed = false;
	private float RepeatTimer = 0.2;

	UPROPERTY()
	FOnMenuPromptPressed OnPressed;

	UPROPERTY()
	FOnMenuPromptPressed OnRepeat;

	UPROPERTY()
	FOnMenuPromptPressed OnFocused;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool bIsDesignTime)
	{
		UpdateWidgets();
	}

	void UpdateWidgets()
	{
		ClickableButton.SetBrushFromTexture(IconButtonTexture);
		if (PromptKey.IsValid())
		{
			ButtonIcon.OverrideKey = PromptKey;
			ButtonIcon.OverrideControllerType = EHazePlayerControllerType::Xbox;
			ButtonIcon.UpdateKey();
			ButtonIconContainer.SetVisibility(ESlateVisibility::HitTestInvisible);
		}
		else
		{
			ButtonIconContainer.SetVisibility(ESlateVisibility::Hidden);
		}
	}

	void UpdateState()
	{
		ButtonIcon.OverrideKey = PromptKey;
		ButtonIcon.OverrideControllerType = GetControllerType();
	
		if (PromptKey.IsValid() && GetControllerType() != EHazePlayerControllerType::Keyboard)
		{
			ButtonIconContainer.SetVisibility(ESlateVisibility::HitTestInvisible);
			ClickableButton.SetVisibility(ESlateVisibility::Hidden);
		}
		else
		{
			ButtonIconContainer.SetVisibility(ESlateVisibility::Hidden);
			if (IsClickableByMouse() && IconButtonTexture != nullptr)
				ClickableButton.SetVisibility(ESlateVisibility::HitTestInvisible);
			else
				ClickableButton.SetVisibility(ESlateVisibility::Hidden);
		}

		if (IsButtonPressed())
			ClickableButton.SetBrushColor(FLinearColor::MakeFromHex(0xff78612f));
		else if (IsButtonHovered())
			ClickableButton.SetBrushColor(FLinearColor::MakeFromHex(0xffe53504));
		else
			ClickableButton.SetBrushColor(FLinearColor::MakeFromHex(0xff656565));
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
		return PromptKey.IsValid();
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
		bHovered = true;
		OnFocused.Broadcast(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseLeave(FPointerEvent MouseEvent)
	{
		bHovered = false;
		bIsPressed = false;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry Geom, FPointerEvent Event)
	{
		if (Event.EffectingButton == EKeys::LeftMouseButton)
		{
			bIsPressed = true;
			RepeatTimer = 0.5;
			if (bTriggerOnMouseDown)
				OnPressed.Broadcast(this);
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDoubleClick(FGeometry InMyGeometry, FPointerEvent Event)
	{
		if (Event.EffectingButton == EKeys::LeftMouseButton)
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
		if (Event.EffectingButton == EKeys::LeftMouseButton && bIsPressed)
		{
			bIsPressed = false;
			if (!bTriggerOnMouseDown)
				OnPressed.Broadcast(this);
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}
};
