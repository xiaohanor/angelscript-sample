
event void FOnOptionButtonClicked();

UCLASS(Abstract)
class UOptionButtonWidget : UOptionWidget
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bPressed = false;

	UPROPERTY()
	FOnOptionButtonClicked OnClicked;

	UPROPERTY(EditAnywhere)
	FText ButtonText;

	UPROPERTY(BindWidget)
	USizeBox MainSizeBox;
	UPROPERTY(BindWidget)
	UMenuPromptOrButton Prompt;
	UPROPERTY(BindWidget)
	UMenuSelectionHighlight SelectionHighlight;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool IsDesignTime)
	{
		Prompt.OnPressed.AddUFunction(this, n"OnButtonClicked");
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		Prompt.Text = ButtonText;
		Prompt.Update();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (Prompt.GetControllerType() == EHazePlayerControllerType::Keyboard)
		{
			Prompt.ButtonIconContainer.SetVisibility(ESlateVisibility::Collapsed);
			MainSizeBox.SetHeightOverride(75.0);
			Prompt.TextWidget.SetColorAndOpacity(FLinearColor::White);

			if (bFocusedByNavigation)
				Prompt.bHovered = true;
			else if (!bFocused)
				Prompt.bHovered = false;
		}
		else
		{
			MainSizeBox.SetHeightOverride(53.0);
			SelectionHighlight.Visibility = ESlateVisibility::Visible;

			if (IsHoveredOrActive())
			{
				SelectionHighlight.bIsHighlighted = true;
				Prompt.ButtonIconContainer.SetRenderOpacity(1.0);

				if (SelectionHighlight.bIsZoe || SelectionHighlight.bIsNeutral)
				{
					Prompt.TextWidget.SetColorAndOpacity(FLinearColor::Black);
				}
			}
			else
			{
				SelectionHighlight.bIsHighlighted = false;
				Prompt.ButtonIconContainer.SetRenderOpacity(0.0);

				if (SelectionHighlight.bIsZoe || SelectionHighlight.bIsNeutral)
				{
					Prompt.TextWidget.SetColorAndOpacity(FLinearColor::White);
				}
			}
		}
	}

	UFUNCTION()
	private void OnButtonClicked(UHazeUserWidget Widget)
	{
		OnClicked.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (InKeyEvent.IsRepeat())
			return FEventReply::Unhandled();

		if (InKeyEvent.Key == EKeys::Enter || InKeyEvent.Key == EKeys::Virtual_Accept)
		{
			bPressed = true;
			Prompt.bIsPressed = true;
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (InKeyEvent.IsRepeat())
			return FEventReply::Unhandled();

		if (InKeyEvent.Key == EKeys::Enter || InKeyEvent.Key == EKeys::Virtual_Accept)
		{
			if (bPressed)
			{
				bPressed = false;
				Prompt.bIsPressed = false;
				OnClicked.Broadcast();
			}
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}
}