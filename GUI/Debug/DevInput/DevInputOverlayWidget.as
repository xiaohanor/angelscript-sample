
UCLASS(Config = EditorPerProjectUserSettings)
class UDevInputConfig
{
	UPROPERTY(Config)
	bool bPauseDuringDevInput = false;
};

namespace UDevInputConfig
{
	UDevInputConfig Get()
	{
		return Cast<UDevInputConfig>(UDevInputConfig.DefaultObject);
	}
}

UCLASS(Abstract)
class UDevInputOverlayWidget : UHazeDevInputOverlayWidget
{
	UPROPERTY(BindWidget)
	UHazeInputButton ScrollLeftButton;

	UPROPERTY(BindWidget)
	UHazeInputButton ScrollRightButton;

	UPROPERTY(BindWidget)
	UHorizontalBox TabContainer;

	UPROPERTY()
	TSubclassOf<UDevInputOverlayTabWidget> TabWidgetClass;

	TArray<UDevInputOverlayTabWidget> Tabs;
	int ActiveTabIndex = 0;

	// This is filled on the CDO
	float LastOpenedTime = 0.0;
	bool bAppliedPause = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		// Not using gamepad, make the scroll buttons into keyboard buttons
		if (!bGamepad)
		{
			ScrollLeftButton.OverrideKey = EKeys::A;
			ScrollLeftButton.OverrideControllerType = EHazePlayerControllerType::Keyboard;
			ScrollRightButton.OverrideKey = EKeys::D;
			ScrollRightButton.OverrideControllerType = EHazePlayerControllerType::Keyboard;
		}
		else
		{
			ScrollLeftButton.OverrideKey = EKeys::Gamepad_LeftTrigger;
			ScrollRightButton.OverrideKey = EKeys::Gamepad_RightTrigger;
		}

		auto CDO = Cast<UDevInputOverlayWidget>(Class.GetDefaultObject());
		bool bRetainCategory = CDO.LastOpenedTime >= Time::PlatformTimeSeconds - 10.0;
		CDO.LastOpenedTime = Time::PlatformTimeSeconds;

		// Figure out which tabs to display
		ActiveTabIndex = 0;

		int CategoryCount = DevInputComponent.Categories.Num();
		for (int CategoryIndex = 0; CategoryIndex < CategoryCount; ++CategoryIndex)
		{
			FName CategoryName = DevInputComponent.Categories[CategoryIndex];
			if (DevInputComponent.HasInputsInCategory(CategoryName))
			{
				auto TabWidget = Cast<UDevInputOverlayTabWidget>(
					Widget::CreateWidget(this, TabWidgetClass));
				TabWidget.CategoryName = CategoryName;
				TabWidget.CategoryIndex = CategoryIndex;
				TabWidget.TabText.SetText(FText::FromName(TabWidget.CategoryName));

				if (bRetainCategory && CategoryIndex == DevInputComponent.SelectedCategoryIndex)
					ActiveTabIndex = Tabs.Num();

				Tabs.Add(TabWidget);
				TabContainer.AddChild(TabWidget);
			}
		}

		if (Tabs.IsValidIndex(ActiveTabIndex))
			DevInputComponent.SelectedCategoryIndex = Tabs[ActiveTabIndex].CategoryIndex;

		UpdateTabs();
		UpdateContent();

		if (UDevInputConfig::Get().bPauseDuringDevInput)
		{
			Game::SetGamePaused(this, true);
			bAppliedPause = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Destruct()
	{
		auto CDO = Cast<UDevInputOverlayWidget>(Class.GetDefaultObject());
		CDO.LastOpenedTime = Time::PlatformTimeSeconds;

		if (bAppliedPause)
			Game::SetGamePaused(this, false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (!Widget::IsAnyUserFocusGameViewportOrNone())
			DevInputComponent.CloseAndFlushInput();

		auto Config = UDevInputConfig::Get();
		if (Config.bPauseDuringDevInput != bAppliedPause)
		{
			if (Config.bPauseDuringDevInput)
			{
				Game::SetGamePaused(this, true);
				bAppliedPause = true;
			}
			else
			{
				Game::SetGamePaused(this, false);
				bAppliedPause = false;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool HandleDevKeyDown(FKey Key)
	{
		if (Key == EKeys::Gamepad_LeftTrigger ||
			Key == EKeys::A)
		{
			SwitchToTabIndex(GetPreviousCategoryTabIndex());
			OnNavigateLeft();

			return true;
		}
		if (Key == EKeys::Gamepad_RightTrigger ||
			Key == EKeys::D)
		{
			SwitchToTabIndex(GetNextCategoryTabIndex());
			OnNavigateRight();

			return true;
		}

		return false;
	}

	void UpdateTabs()
	{
		int TabCount = Tabs.Num();
		for (int i = 0; i < TabCount; ++i)
			Tabs[i].SetSelected(i == ActiveTabIndex);
	}

	void UpdateContent()
	{
		int CategoryIndex = DevInputComponent.SelectedCategoryIndex;

		ClearInputEntries();
		for(auto Entry : DevInputComponent.GetInputsInCategory(GetCategoryWrapped(CategoryIndex)))
		{
			bool bHasKeys = false;
			for(auto Key : Entry.Keys)
			{
				if (Key.IsGamepadKey() == bGamepad)
					bHasKeys = true;
			}

			// If we're opening the overlay with a gamepad, don't show debug shortcuts
			// that aren't accessible by gamepad at all.
			if (!bHasKeys)
				continue;

			auto EntryWidget = CreateEntry();
			EntryWidget.SetFromInputInfo(bGamepad, Entry);
		}
	}

	int GetNextCategoryTabIndex()
	{
		return Math::WrapIndex(ActiveTabIndex + 1, 0, Tabs.Num());
	}

	int GetPreviousCategoryTabIndex()
	{
		return Math::WrapIndex(ActiveTabIndex - 1, 0, Tabs.Num());
	}

	FName GetCategoryWrapped(int Index)
	{
		if (DevInputComponent.Categories.Num() == 0)
			return NAME_None;

		int WrappedIndex = Math::WrapIndex(Index, 0, DevInputComponent.Categories.Num());
		return DevInputComponent.Categories[WrappedIndex];
	}

	void SwitchToTabIndex(int TabIndex)
	{
		if (!Tabs.IsValidIndex(TabIndex))
			return;

		auto Tab = Tabs[TabIndex];
		DevInputComponent.SetCurrentCategoryIndex(Tab.CategoryIndex);
		ActiveTabIndex = TabIndex;

		UpdateTabs();
		UpdateContent();
	}

	UFUNCTION(BlueprintEvent)
	void ClearInputEntries() {}

	UFUNCTION(BlueprintEvent)
	UDevInputOverlayEntryWidget CreateEntry() { return nullptr; }

	UFUNCTION(BlueprintEvent)
	void OnNavigateLeft() {}

	UFUNCTION(BlueprintEvent)
	void OnNavigateRight() {}
}

UCLASS(Abstract)
class UDevInputOverlayTabWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	USizeBox MainBox;
	UPROPERTY(BindWidget)
	UBorder BackgroundBorder;
	UPROPERTY(BindWidget)
	UTextBlock TabText;

	FName CategoryName;
	int CategoryIndex = 0;

	bool bSelected = false;

	void SetSelected(bool bNewSelected)
	{
		bSelected = bNewSelected;

		FSlateBrush Brush;
		Brush.DrawAs = ESlateBrushDrawType::RoundedBox;
		Brush.OutlineSettings.CornerRadii = FVector4(20.0, 20.0, 0.0, 0.0);
		Brush.OutlineSettings.RoundingType = ESlateBrushRoundingType::FixedRadius;

		FSlateFontInfo Font = TabText.GetFont();;

		auto MainSlot = Cast<USizeBoxSlot>(MainBox.GetContentSlot());

		if (bSelected)
		{
			Brush.TintColor = FLinearColor::MakeFromHex(0xff25250b);
			Brush.OutlineSettings.Width = 2.0;
			Brush.OutlineSettings.Color = FLinearColor::MakeFromHex(0xfffffb00);

			MainSlot.SetPadding(FMargin(5.0, 0.0));

			Font.Size = 18;
			TabText.SetColorAndOpacity(FLinearColor::MakeFromHex(0xffffffff));
		}
		else
		{
			Brush.OutlineSettings.Width = 1.0;
			Brush.OutlineSettings.Color = FLinearColor::Black;
			Brush.TintColor = FLinearColor::MakeFromHex(0xff101010);

			MainSlot.SetPadding(FMargin(-5.0, 10.0, -5.0, 0.0));

			Font.Size = 10;
			TabText.SetColorAndOpacity(FLinearColor::MakeFromHex(0xff777777));
		}

		BackgroundBorder.SetBrush(Brush);
		TabText.SetFont(Font);
	}
}