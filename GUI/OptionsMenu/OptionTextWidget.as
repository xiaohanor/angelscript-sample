
// Labels and ValueText must be set by external input
UCLASS(Abstract)
class UOptionTextWidget : UOptionWidget
{
	UPROPERTY(EditAnywhere, Meta = (MultiLine))
	FText LabelDescription;

	UPROPERTY(BindWidget)
	UHazeTextWidget LabelText;
	
	UPROPERTY(BindWidget)
	UHazeTextWidget ValueText;

	UPROPERTY(BindWidget)
	UMenuSelectionHighlight SelectionHighlight;

	FText GetDescription() const override
	{
		return LabelDescription;
	}

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool bIsDesignTime)
	{
	}

	void Refresh() override
	{
		LabelText.Update();
		ValueText.Update();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (IsHoveredOrActive())
		{
			if (!SelectionHighlight.bIsHighlighted)
				NarrateFull();

			SelectionHighlight.bIsHighlighted = true;

			if (SelectionHighlight.bIsZoe || SelectionHighlight.bIsNeutral)
				LabelText.SetColorAndOpacity(FLinearColor::Black);
		}
		else
		{
			SelectionHighlight.bIsHighlighted = false;

			if (SelectionHighlight.bIsZoe || SelectionHighlight.bIsNeutral)
				LabelText.SetColorAndOpacity(FLinearColor::White);
		}
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		return FEventReply::Unhandled();
	}

	FString GetFullNarrationText() override
	{
		return LabelText.Text.ToString() + ", " + ValueText.Text.ToString() + ", " + GetDescription().ToString();
	}

	UFUNCTION()
	void NarrateFull()
	{
		Game::NarrateString(GetFullNarrationText());
	}

	UFUNCTION()
	void NarrateValue()
	{
		Game::NarrateText(ValueText.Text);
	}

}