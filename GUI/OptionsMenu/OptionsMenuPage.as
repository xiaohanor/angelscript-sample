
class UOptionsMenuPage : UHazeUserWidget
{
	default bIsFocusable = true;

	bool bShowUnblurredGameInBackground = false;

	UPROPERTY()
	FText TabName;

	UPROPERTY()
	FOnOptionFocused OnOptionFocused;

	UOptionWidget FocusedOption;
	TArray<UOptionWidget> Options;

	// Called on the CDO
	bool ShouldShowPageOnCurrentPlatform() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		// Collect all options on this page
		TArray<UWidget> Widgets;
		GetAllChildWidgetsOfClass(UOptionWidget, Widgets);

		for (auto Widget : Widgets)
			Options.Add(Cast<UOptionWidget>(Widget));

		// Respond to events on options
		for (auto Option : Options)
		{
			Option.OnOptionFocused.AddUFunction(this, n"OnFocusedOptionRow");
		}
	}

	UFUNCTION()
	protected void OnFocusedOptionRow(UOptionWidget Widget)
	{
		FocusedOption = Widget;
		OnOptionFocused.Broadcast(Widget);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		if (FocusedOption != nullptr && FocusedOption.IsVisible())
			return FEventReply::Handled().SetUserFocus(FocusedOption, InFocusEvent.Cause);
		for (auto Option : Options)
		{
			if (Option.IsVisible())
				return FEventReply::Handled().SetUserFocus(Option, InFocusEvent.Cause);
		}
		return FEventReply::Unhandled();
	}

	void ResetOptionsToDefault()
	{
		for (UOptionWidget Option : Options)
			Option.Reset();
	}

	void RefreshSettings()
	{
		for (auto Widget : Options)
			Widget.Refresh();
	}
};