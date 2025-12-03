
event void FOnSliderValueApplied(UOptionSliderWidget Widget);

UCLASS(Abstract)
class UOptionSliderWidget : UOptionWidget
{
	default bCustomNavigation = true;

	UPROPERTY(EditAnywhere, Category = "Option")
	FName OptionId;

	UPROPERTY(EditAnywhere)
	bool bAutoApply = true;

	UPROPERTY(EditAnywhere)
	bool bApplyOnFocusLost = false;

	UPROPERTY(EditAnywhere)
	float StepSize = 1.0;

	UPROPERTY(EditAnywhere)
	float DisplayValueMultiplier = 1.0;

	UPROPERTY(EditAnywhere)
	FString ValueSuffix;

	UPROPERTY(BindWidget)
	UHazeTextWidget LabelText;
	
	UPROPERTY(BindWidget)
	UHazeTextWidget ValueText;

	UPROPERTY(BindWidget)
	USlider ValueSlider;

	UPROPERTY(BindWidget)
	UMenuArrowButtonWidget LeftArrowButton;

	UPROPERTY(BindWidget)
	UMenuArrowButtonWidget RightArrowButton;

	UPROPERTY(BindWidget)
	UMenuSelectionHighlight SelectionHighlight;

	FOnSliderValueApplied OnValueApplied;

	UHazeNumberSetting Setting;
	float32 CurrentValue = 0.0;
	float ApplyTime = 0.0;

	void Apply() override
	{
		GameSettings::SetGameSettingsValue(OptionId, f"{CurrentValue}");
	}

	void Reset() override
	{
		if (Setting != nullptr)
		{
			CurrentValue = float32(String::Conv_StringToDouble(Setting.DefaultValue));
			UpdateValue();
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
		UHazeGameSettingBase Desc;
		if (!GameSettings::GetGameSettingsDescription(OptionId, Desc))
			return;

		Setting = Cast<UHazeNumberSetting>(Desc);
		if (Setting == nullptr)
			return;

		LabelText.Text = Setting.DisplayName;
		LabelText.Update();

		CurrentValue = float32(String::Conv_StringToDouble(Setting.DefaultValue));
		GameSettings::GetGameSettingsValueAsNumber(OptionId, CurrentValue);

		ValueSlider.MinValue = Setting.MinValue * DisplayValueMultiplier;
		ValueSlider.MaxValue = Setting.MaxValue * DisplayValueMultiplier;
		ValueSlider.StepSize = StepSize;

		if (SelectionHighlight.bIsNeutral)
			ValueSlider.SliderHandleColor = FLinearColor(0, 0.5, 1, 1);
		else if (SelectionHighlight.bIsZoe)
			ValueSlider.SliderHandleColor = FLinearColor(0.45, 1.00, 0.00);
		else
			ValueSlider.SliderHandleColor = PlayerColor::Mio;

		UpdateValue();
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		LeftArrowButton.OnClicked.AddUFunction(this, n"OnLeftArrowClicked");
		RightArrowButton.OnClicked.AddUFunction(this, n"OnRightArrowClicked");

		ValueSlider.OnValueChanged.AddUFunction(this, n"OnSliderChanged");

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

		if (ApplyTime != 0.0 && Time::PlatformTimeSeconds > ApplyTime)
		{
			ApplyTime = 0.0;
			Apply();
		}
	}

	UFUNCTION()
	private void OnSliderChanged(float32 Value)
	{
		CurrentValue = float32(ValueSlider.Value / DisplayValueMultiplier);
		UpdateValue();

		if (bAutoApply)
			Apply();
		else
			ApplyTime = Time::PlatformTimeSeconds + 1.0;
		
		OnValueApplied.Broadcast(this);
		NarrateValue();
	}

	UFUNCTION()
	private void OnRightArrowClicked(UMenuArrowButtonWidget Widget)
	{
		IncreaseValue();
	}

	UFUNCTION()
	private void OnLeftArrowClicked(UMenuArrowButtonWidget Widget)
	{
		ReduceValue();
	}

	void Refresh() override
	{
		if (Setting == nullptr)
			return;
		CurrentValue = float32(String::Conv_StringToDouble(Setting.DefaultValue));
		GameSettings::GetGameSettingsValueAsNumber(OptionId, CurrentValue);
		UpdateValue();
	}

	void UpdateValue()
	{
		if (Setting == nullptr)
			return;
		ValueSlider.Value = CurrentValue * DisplayValueMultiplier;
		ValueText.Text = FText::FromString(f"{CurrentValue * DisplayValueMultiplier :.0}{ValueSuffix}");
		ValueText.Update();
		UpdateArrows();
	}

	void UpdateArrows()
	{
		if (CurrentValue > Setting.MinValue)
			LeftArrowButton.bDisabled = false;
		else
			LeftArrowButton.bDisabled = true;

		if (CurrentValue < Setting.MaxValue)
			RightArrowButton.bDisabled = false;
		else
			RightArrowButton.bDisabled = true;
	}

	void ReduceValue()
	{
		int PreviousStep = Math::FloorToInt((CurrentValue - Setting.MinValue) / StepSize);

		float PreviousStepValue = Setting.MinValue + (PreviousStep * StepSize);
		float WantedValue = PreviousStepValue;

		if (Math::IsNearlyEqual(PreviousStepValue, CurrentValue, StepSize*0.1))
		{
			// We're pretty much at this step value, so jump one step value down
			WantedValue -= StepSize;
		}

		CurrentValue = float32(Math::Clamp(WantedValue, Setting.MinValue, Setting.MaxValue));
		UpdateValue();
		if (bAutoApply)
			Apply();

		NarrateValue();
	}

	void IncreaseValue()
	{
		int NextStep = Math::CeilToInt((CurrentValue - Setting.MinValue) / StepSize);

		float NextStepValue = Setting.MinValue + (NextStep * StepSize);
		float WantedValue = NextStepValue;

		if (Math::IsNearlyEqual(NextStepValue, CurrentValue, StepSize*0.1))
		{
			// We're pretty much at this step value, so jump one step value up
			WantedValue += StepSize;
		}

		CurrentValue = float32(Math::Clamp(WantedValue, Setting.MinValue, Setting.MaxValue));
		UpdateValue();
		if (bAutoApply)
			Apply();

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
			ReduceValue();
			OutRule = EUINavigationRule::Stop;
			return this;
		}
		else if (Event.NavigationType == EUINavigation::Right)
		{
			IncreaseValue();
			OutRule = EUINavigationRule::Stop;
			return this;
		}

		OutRule = EUINavigationRule::Escape;
		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemovedFromFocusPath(FFocusEvent InFocusEvent)
	{
		if (bApplyOnFocusLost)
			Apply();
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