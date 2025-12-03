
event void FOnEnumOptionApplied(UOptionWidget Widget);

UCLASS(Abstract)
class UOptionEnumWidget : UOptionWidget
{
	default bCustomNavigation = true;

	UPROPERTY(EditAnywhere, Category = "Option")
	FName OptionId;

	UPROPERTY(EditAnywhere)
	bool bAutoApply = true;

	UPROPERTY(EditAnywhere)
	bool bShowPips = true;

	UPROPERTY(BindWidget)
	UHazeTextWidget LabelText;
	
	UPROPERTY(BindWidget)
	UHazeTextWidget ValueText;

	UPROPERTY(BindWidget)
	UHorizontalBox DotIndicatorBox;

	UPROPERTY(BindWidget)
	UMenuArrowButtonWidget LeftArrowButton;

	UPROPERTY(BindWidget)
	UMenuArrowButtonWidget RightArrowButton;

	UPROPERTY(BindWidget)
	UMenuSelectionHighlight SelectionHighlight;

	UPROPERTY()
	TSubclassOf<UOptionEnumDotIndicator> DotIndicatorClass;

	FOnEnumOptionApplied OnOptionApplied;
	FOnEnumOptionApplied OnCustomLeftAndRight;

	UHazeGameSettingBase Setting;
	FString CurrentValue;
	TArray<UOptionEnumDotIndicator> DotWidgets;

	void Apply() override
	{
		if (!GameSettings::SetGameSettingsValue(OptionId, CurrentValue))
		{
			Refresh();
		}
		else
		{
			OnOptionApplied.Broadcast(this);
		}
	}

	void Reset() override
	{
		if (Setting != nullptr)
		{
			CurrentValue = Setting.DefaultValue;
			UpdateValue();
			if (bAutoApply)
				Apply();
		}
	}

	FText GetDescription() const override
	{
		if (Setting == nullptr)
			return FText();
		return Setting.Description;
	}

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool bIsDesignTime)
	{
		UHazeGameSettingBase SettingDesc;
		if (!GameSettings::GetGameSettingsDescription(OptionId, SettingDesc))
			return;

		Setting = SettingDesc;

		LabelText.Text = Setting.DisplayName;
		LabelText.Update();

		CurrentValue = Setting.DefaultValue;
		GameSettings::GetGameSettingsValue(OptionId, CurrentValue);

		CreateDots();
		UpdateValue();
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		LeftArrowButton.OnClicked.AddUFunction(this, n"OnLeftArrowClicked");
		RightArrowButton.OnClicked.AddUFunction(this, n"OnRightArrowClicked");

		if (Setting == nullptr)
			Visibility = ESlateVisibility::Collapsed;
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

	void Refresh() override
	{
		if (Setting == nullptr)
			return;
		CurrentValue = Setting.DefaultValue;
		GameSettings::GetGameSettingsValue(OptionId, CurrentValue);
		CreateDots();
		UpdateValue();
	}

	void CreateDots()
	{
		int DotCount = Setting.Options.Num();
		if (!bShowPips)
			DotCount = 0;

		// Create new dots
		for (int i = DotWidgets.Num(); i < DotCount; ++i)
		{
			UOptionEnumDotIndicator Dot = Widget::CreateWidget(this, DotIndicatorClass);
			Dot.EnumOption = this;
			Dot.OptionIndex = i;
			DotIndicatorBox.AddChild(Dot);
			DotWidgets.Add(Dot);
		}

		// Remove extraneous dots
		for (int i = DotCount, Count = DotWidgets.Num(); i < Count; ++i)
		{
			DotIndicatorBox.RemoveChild(DotWidgets.Last());
			DotWidgets.RemoveAt(DotWidgets.Num() - 1);
		}
	}

	UFUNCTION()
	private void OnRightArrowClicked(UMenuArrowButtonWidget Widget)
	{
		SelectNextValue();
	}

	UFUNCTION()
	private void OnLeftArrowClicked(UMenuArrowButtonWidget Widget)
	{
		SelectPreviousValue();
	}

	void UpdateValue()
	{
		int SelectedIndex = -1;
		bool bHasValue = false;
		for (int OptionIndex = 0, OptionCount = Setting.Options.Num(); OptionIndex < OptionCount; ++OptionIndex)
		{
			const FHazeGameSettingOption& Option = Setting.Options[OptionIndex];
			if (Option.Value == CurrentValue)
			{
				bHasValue = true;
				SelectedIndex = OptionIndex;

				ValueText.Text = Option.Name;
				ValueText.Update();
				break;
			}
		}

		if (!bHasValue && CurrentValue != Setting.DefaultValue)
		{
			CurrentValue = Setting.DefaultValue;
			UpdateValue();
			return;
		}

		for (int i = 0, DotCount = DotWidgets.Num(); i < DotCount; ++i)
		{
			if (i == SelectedIndex)
				DotWidgets[i].bSelected = true;
			else
				DotWidgets[i].bSelected = false;

			DotWidgets[i].UpdateValue();
		}

		UpdateArrows();
	}

	void UpdateArrows()
	{
		if (GetPreviousValueIndex() != -1)
		{
			LeftArrowButton.bDisabled = false;
			LeftArrowButton.Visibility = ESlateVisibility::Visible;
		}
		else
		{
			LeftArrowButton.bDisabled = true;
			LeftArrowButton.Visibility = ESlateVisibility::Hidden;
		}

		if (GetNextValueIndex() != -1)
		{
			RightArrowButton.bDisabled = false;
			RightArrowButton.Visibility = ESlateVisibility::Visible;
		}
		else
		{
			RightArrowButton.bDisabled = true;
			RightArrowButton.Visibility = ESlateVisibility::Hidden;
		}
	}

	int GetPreviousValueIndex()
	{
		if (Setting == nullptr)
			return -1;

		for (int i = 0, Count = Setting.Options.Num(); i < Count; ++i)
		{
			const FHazeGameSettingOption& Option = Setting.Options[i];
			if (Option.Value == CurrentValue)
				return i - 1;
		}

		return -1;
	}

	int GetNextValueIndex()
	{
		if (Setting == nullptr)
			return -1;

		for (int i = 0, Count = Setting.Options.Num(); i < Count; ++i)
		{
			const FHazeGameSettingOption& Option = Setting.Options[i];
			if (Option.Value == CurrentValue)
			{
				if (i + 1 < Count)
					return i + 1;
				else
					return -1;
			}
		}

		return -1;
	}

	void SelectPreviousValue()
	{
		int Index = GetPreviousValueIndex();
		if (Index != -1)
		{
			CurrentValue = Setting.Options[Index].Value;
			UpdateValue();
			if (bAutoApply)
				Apply();
		}

		NarrateValue();
	}

	void SelectNextValue()
	{
		int Index = GetNextValueIndex();
		if (Index != -1)
		{
			CurrentValue = Setting.Options[Index].Value;
			UpdateValue();
			if (bAutoApply)
				Apply();
		}

		NarrateValue();
	}

	void SelectValueIndex(int Index)
	{
		if (Setting.Options.IsValidIndex(Index))
		{
			CurrentValue = Setting.Options[Index].Value;
			UpdateValue();
			if (bAutoApply)
				Apply();
		}

		NarrateValue();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	UWidget OnCustomNavigation(FGeometry Geometry, FNavigationEvent Event, EUINavigationRule& OutRule)
	{
		if (Event.NavigationType == EUINavigation::Left)
		{
			bool bPlaySound = GetPreviousValueIndex() != -1;
			SelectPreviousValue();

			if (bPlaySound)
				OnCustomLeftAndRight.Broadcast(this);

			OutRule = EUINavigationRule::Stop;
			return this;
		}
		else if (Event.NavigationType == EUINavigation::Right)
		{
			bool bPlaySound = GetNextValueIndex() != -1;
			SelectNextValue();

			if (bPlaySound)
				OnCustomLeftAndRight.Broadcast(this);

			OutRule = EUINavigationRule::Stop;
			return this;
		}

		OutRule = EUINavigationRule::Escape;
		return nullptr;
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

event void FOnOptionEnumDotApplied(UOptionEnumDotIndicator Widget);

class UOptionEnumDotIndicator : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UBorder SelectedWidget;
	UPROPERTY(BindWidget)
	UBorder UnselectedWidget;
	UPROPERTY(BindWidget)
	UBorder HoveredWidget;

	bool bSelected = false;
	bool bPressed = false;
	int OptionIndex = 0;
	UOptionEnumWidget EnumOption;
	bool bHovered;

	FOnOptionEnumDotApplied OnClicked;
	FOnOptionEnumDotApplied OnFocused;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		UHazeGameInstance HazeGameInstance = Game::HazeGameInstance;
		if (HazeGameInstance != nullptr)
		{
			switch (HazeGameInstance.PausingPlayer)
			{
				case EHazeSelectPlayer::Mio:
					SelectedWidget.SetBrushColor(PlayerColor::Mio);
				break;
				case EHazeSelectPlayer::Zoe:
					SelectedWidget.SetBrushColor(FLinearColor(0.45, 1.00, 0.00));
				break;
				default:
					SelectedWidget.SetBrushColor(FLinearColor(0, 0.5, 1, 1));
				break;
			}
		}
	}

	void UpdateValue()
	{
		if (bSelected)
		{
			SelectedWidget.Visibility = ESlateVisibility::Visible;
			UnselectedWidget.Visibility = ESlateVisibility::Hidden;
		}
		else
		{
			SelectedWidget.Visibility = ESlateVisibility::Hidden;
			UnselectedWidget.Visibility = ESlateVisibility::Visible;
		}

		if (bHovered)
		{
			HoveredWidget.Visibility = ESlateVisibility::Visible;
		}
		else
		{
			HoveredWidget.Visibility = ESlateVisibility::Hidden;
		}

		if (bPressed)
		{
			SetRenderTranslation(FVector2D(2, 2));
		}
		else
		{
			SetRenderTranslation(FVector2D(0, 0));
		}
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.EffectingButton == EKeys::LeftMouseButton)
		{
			bPressed = true;
			UpdateValue();
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}


	UFUNCTION(BlueprintOverride)
	void OnMouseEnter(FGeometry Geometry, FPointerEvent MouseEvent)
	{
		bHovered = true;
		UpdateValue();
		OnFocused.Broadcast(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseLeave(FPointerEvent MouseEvent)
	{
		bHovered = false;
		bPressed = false;
		UpdateValue();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonUp(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.EffectingButton == EKeys::LeftMouseButton)
		{
			if (bPressed)
			{
				EnumOption.SelectValueIndex(OptionIndex);
				bPressed = false;
				UpdateValue();
				OnClicked.Broadcast(this);
			}

			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}
}