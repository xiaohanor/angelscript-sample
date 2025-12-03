
UCLASS(Abstract)
class UMessageDialogWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FMessageDialog MessageDialog;
	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly)
	TSubclassOf<UMessageDialogButton> ButtonClass;

	UPROPERTY(BindWidget)
	UScrollBox MessageScrollBox;
	UPROPERTY(BindWidget)
	URichTextBlock MessageText;

	UPROPERTY(BindWidget)
	UVerticalBox ButtonBox;

	int ActiveMessageId = -1;
	bool bCancelPressed = false;
	TArray<UMessageDialogButton> Buttons;
	UMessageDialogButton FocusedButton;

	UPROPERTY(BindWidget)
	UWidget DescriptionTooltipPanel;
	UPROPERTY(BindWidget)
	UImage DescriptionBackground;
	UPROPERTY(BindWidget)
	UTextBlock DescriptionTextBlock;

	UPROPERTY(Transient, Meta = (BindWidgetAnim))
	UWidgetAnimation ShowAnim;
	UPROPERTY(Transient, Meta = (BindWidgetAnim))
	UWidgetAnimation HideAnim;

	void Show()
	{
		PlayAnimation(ShowAnim);
	}

	UFUNCTION(BlueprintOverride)
	void RemoveFromScreen()
	{
		PlayAnimation(HideAnim);
		BindToAnimationFinished(HideAnim, FWidgetAnimationDynamicEvent(this, n"OnHideFinished"));
	}

	UFUNCTION()
	private void OnHideFinished()
	{
		FinishRemovingWidget();
	}

	void UpdateMessage()
	{
		MessageText.SetText(MessageDialog.Message);
		if (MessageDialog.Message.IsEmpty())
			MessageScrollBox.Visibility = ESlateVisibility::Collapsed;
		else
			MessageScrollBox.Visibility = ESlateVisibility::HitTestInvisible;

		for (int i = 0, Count = MessageDialog.Options.Num(); i < Count; ++i)
		{
			const FMessageDialogOption& Option = MessageDialog.Options[i];
			auto Button = Cast<UMessageDialogButton>(
				Widget::CreateWidget(this, ButtonClass)
			);

			Button.DescriptionTextValue = Option.DescriptionText;
			Button.TextWidget.Text = Option.Label;
			Button.Dialog = this;
			Button.bIsFirstOption = (i == 0);
			Button.bIsLastOption = (i == Count-1);
			Button.OnClicked.UnbindObject(this);
			Button.OnClicked.AddUFunction(this, n"OnButtonClicked");

			Buttons.Add(Button);
			ButtonBox.AddChild(Button);
		}

		BP_UpdateMessage();
	}

	void UpdateTooltipPosition()
	{
		if (FocusedButton == nullptr || DescriptionTextBlock.GetText().IsEmpty() || !FocusedButton.bFocused)
		{
			DescriptionTooltipPanel.Visibility = ESlateVisibility::Hidden;
		}
		else
		{
			DescriptionTooltipPanel.Visibility = ESlateVisibility::HitTestInvisible;
			FGeometry OptionGeometry = FocusedButton.GetCachedGeometry();

			FVector2D OptionPos = OptionGeometry.LocalToAbsolute(FVector2D(0, OptionGeometry.LocalSize.Y * 0.5));
			FGeometry CanvasGeometry = DescriptionTooltipPanel.Parent.GetCachedGeometry();
			FVector2D CanvasOptionPos = CanvasGeometry.AbsoluteToLocal(OptionPos);
			FVector2D CanvasOptionSize = OptionGeometry.LocalSize;
			FVector2D TooltipSize = DescriptionTooltipPanel.GetCachedGeometry().LocalSize;

			auto TooltipSlot = Cast<UCanvasPanelSlot>(DescriptionTooltipPanel.Slot);
			FMargin Margin = TooltipSlot.Offsets;
			Margin.Top = CanvasOptionPos.Y - TooltipSize.Y*0.5;
			Margin.Left = CanvasOptionPos.X + CanvasOptionSize.X + 10;
			DescriptionBackground.SetRenderScale(FVector2D(1.0, 1.0));

			if (Margin.Left + 500 >= CanvasGeometry.LocalSize.X)
				Margin.Left = CanvasGeometry.LocalSize.X - 510;
			

			TooltipSlot.SetOffsets(Margin);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		UpdateTooltipPosition();
	}


	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		if (FocusedButton != nullptr && Buttons.Contains(FocusedButton))
			return FEventReply::Handled().SetUserFocus(FocusedButton, InFocusEvent.Cause);
		else
			return FEventReply::Handled().SetUserFocus(Buttons[0], InFocusEvent.Cause);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (InKeyEvent.Key == EKeys::Virtual_Back || InKeyEvent.Key == EKeys::Escape)
		{
			bCancelPressed = true;
			for (int i = 0, Count = MessageDialog.Options.Num(); i < Count; ++i)
			{
				if (MessageDialog.Options[i].Type == EMessageDialogOptionType::Cancel)
				{
					if (Buttons[i].HasAnyUserFocus())
					{
						Buttons[i].bPressed = true;
					}
				}
			}
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (InKeyEvent.Key == EKeys::Virtual_Back || InKeyEvent.Key == EKeys::Escape)
		{
			if (bCancelPressed)
			{
				bCancelPressed = false;
				for (int i = 0, Count = MessageDialog.Options.Num(); i < Count; ++i)
				{
					if (MessageDialog.Options[i].Type == EMessageDialogOptionType::Cancel)
					{
						if (Buttons[i].HasAnyUserFocus() || MessageDialog.bInstantCloseOnCancel)
							OnButtonClicked(Buttons[i]);
						else
							Widget::SetAllPlayerUIFocus(Buttons[i]);
						Buttons[i].bPressed = false;
						if (MessageDialog.bInstantCloseOnCancel)
							Buttons[i].bActivated = false;
					}
				}
			}
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION()
	private void OnButtonClicked(UMenuButtonWidget Button)
	{
		if (!bIsAdded)
			return;

		auto MessageButton = Cast<UMessageDialogButton>(Button);
		int Index = Buttons.FindIndex(MessageButton);
		FOnMessageDialogOptionChosen ChosenDelegate = MessageDialog.Options[Index].OnChosen;
		MessageButton.AnimateActivate();

		auto Dialogs = UMessageDialogSingleton::Get();
		Dialogs.CloseMessage();

		ChosenDelegate.ExecuteIfBound();
	}

	UFUNCTION(BlueprintEvent)
	void BP_UpdateMessage() {}
};

UCLASS(Abstract)
class UMessageDialogButton : UMenuButtonWidget
{
	UPROPERTY(BindWidget)
	UWidget MainSizeBox;
	UPROPERTY(BindWidget)
	UTextBlock TextWidget;
	UPROPERTY(BindWidget)
	UMenuSelectionHighlight SelectionHighlight;

	UPROPERTY(BindWidget)
	UImage LineUp;
	UPROPERTY(BindWidget)
	UImage LineDown;

	UPROPERTY(BindWidget)
	UWidget DotNormal;
	UPROPERTY(BindWidget)
	UImage DotSelected;

	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation ActivateAnimation;

	UPROPERTY()
	UTexture2D TextureDotActive_Neutral;
	UPROPERTY()
	UTexture2D TextureDotActive_Mio;
	UPROPERTY()
	UTexture2D TextureDotActive_Zoe;

	UPROPERTY(EditAnywhere, Category = "Pause Menu Button")
	bool bIsFirstOption = false;
	UPROPERTY(EditAnywhere, Category = "Pause Menu Button")
	bool bIsLastOption = false;

	FText DescriptionTextValue;

	UMessageDialogWidget Dialog;
	bool bActivated = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		if (Game::HazeGameInstance != nullptr)
		{
			switch (Game::GetHazeGameInstance().GetPausingPlayer())
			{
				case EHazeSelectPlayer::Mio:
					DotSelected.SetBrushFromTexture(TextureDotActive_Mio);
				break;
				case EHazeSelectPlayer::Zoe:
					DotSelected.SetBrushFromTexture(TextureDotActive_Zoe);
				break;
				default:
					DotSelected.SetBrushFromTexture(TextureDotActive_Neutral);
				break;
			}
		}
	}

	void AnimateActivate()
	{
		bActivated = true;
		PlayAnimation(ActivateAnimation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (bFocused || bActivated)
		{
			SelectionHighlight.bIsHighlighted = true;
			if (SelectionHighlight.bIsZoe || SelectionHighlight.bIsNeutral)
				TextWidget.SetColorAndOpacity(FLinearColor::Black);

			DotNormal.Visibility = ESlateVisibility::Hidden;
			DotSelected.Visibility = ESlateVisibility::HitTestInvisible;
		}
		else
		{
			SelectionHighlight.bIsHighlighted = false;
			TextWidget.SetColorAndOpacity(FLinearColor::White);

			DotNormal.Visibility = ESlateVisibility::HitTestInvisible;
			DotSelected.Visibility = ESlateVisibility::Hidden;
		}

		if (bPressed)
		{
			SelectionHighlight.SetRenderTranslation(FVector2D(3, 3));
			TextWidget.SetRenderTranslation(FVector2D(3, 3));
			DotSelected.SetRenderTranslation(FVector2D(3, 3));

			SetLineSize(LineUp, 24);
			SetLineSize(LineDown, 19);
		}
		else
		{
			SelectionHighlight.SetRenderTranslation(FVector2D(0, 0));
			TextWidget.SetRenderTranslation(FVector2D(0, 0));
			DotSelected.SetRenderTranslation(FVector2D(0, 0));

			SetLineSize(LineUp, 19);
			SetLineSize(LineDown, 19);
		}

		FSlateFontInfo Font = TextWidget.Font;
		if (bFocused || bActivated)
			Font.TypefaceFontName = n"Bold";
		else
			Font.TypefaceFontName = NAME_None;
		TextWidget.SetFont(Font);

		if (bIsFirstOption)
			LineUp.Visibility = ESlateVisibility::Hidden;
		else
			LineUp.Visibility = ESlateVisibility::HitTestInvisible;

		if (bIsLastOption)
			LineDown.Visibility = ESlateVisibility::Hidden;
		else
			LineDown.Visibility = ESlateVisibility::HitTestInvisible;
	}

	void SetLineSize(UImage Image, int Size)
	{
		FSlateBrush Brush = Image.Brush;
		if (Brush.ImageSize.Y != Size)
		{
			Brush.ImageSize.Y = Size;
			Image.SetBrush(Brush);
		}
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		if (Dialog != nullptr)
		{
			Dialog.FocusedButton = this;
			Dialog.DescriptionTextBlock.SetText(DescriptionTextValue);
		}

		if (Game::IsNarrationEnabled())
		{
			FString NarrateString = TextWidget.Text.ToString();
			NarrateString += ", ";
			NarrateString += DescriptionTextValue.ToString();
			Game::NarrateString(NarrateString);
		}

		return Super::OnFocusReceived(MyGeometry, InFocusEvent);
	}
};