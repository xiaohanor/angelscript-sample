
class UToggleDevMenuEntryWidgetData
{
	FHazeDevToggleBool Path;
	FHazeInternalDevToggleBool Toggle;
	FHazeInternalDevToggleGroup Group;
	bool bIsInCategoryBox = false;
	bool bIsMainCategory = false;
	bool bIsSubcategory = false;
	bool bIsSearching = false;
	bool bDirty = true;
	bool bIsGenericHeader = false;
	bool bDarkBackground = false;
};

UCLASS(Abstract)
class UTogglesDevMenuEntryWidget : UHazeUserWidget
{
	UToggleDevMenuEntryWidgetData EntryData;
	bool bHasOptions = false;

	UPROPERTY(BindWidget)
	UHorizontalBox TogglesBox;
	UPROPERTY(BindWidget)
	USizeBox MainCategoryPaddingBox;
	UPROPERTY(BindWidget)
	USizeBox SubcategoryPaddingBox;
	UPROPERTY(BindWidget)
	UButton ToggleButton;
	UPROPERTY(BindWidget)
	UTextBlock ToggleValue;
	UPROPERTY(BindWidget)
	UTextBlock ToggleName;

	UPROPERTY(BindWidget)
	UBorder BackgroundBorder;

	UPROPERTY(BindWidget)
	USizeBox CategoryBox;
	UPROPERTY(BindWidget)
	UButton CategoryButton;
	UPROPERTY(BindWidget)
	UTextBlock CategoryText;

	UPROPERTY(BindWidget)
	UHorizontalBox OptionsBox;
	UPROPERTY(BindWidget)
	UWrapBox OptionsWrapBox;

	TArray<UTogglesDevMenuOptionTileWidget> TileWidgets;
	UPROPERTY(EditAnywhere)
	TSubclassOf<UTogglesDevMenuOptionTileWidget> TileWidgetClass;

	float32 OGFontSize = 0.0;

	UPROPERTY(EditDefaultsOnly)
	FLinearColor NormalColor;
	UPROPERTY(EditDefaultsOnly)
	FLinearColor DarkColor;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		ToggleButton.OnClicked.AddUFunction(this, n"OnClicked");
		CategoryButton.OnClicked.AddUFunction(this, n"SelectCategory");
	}

	UFUNCTION()
	private void SelectCategory()
	{
#if !RELEASE
		if (GetCategory() == UHazeDevToggleSubsystem::Get().LevelSpecificCategory)
			UHazeDevToggleSubsystem::Get().ChosenCategories.Reset();
		else
		{
			if (UHazeDevToggleSubsystem::Get().ChosenCategories.Contains(GetCategory()))
				UHazeDevToggleSubsystem::Get().ChosenCategories.Remove(GetCategory());
			else
				UHazeDevToggleSubsystem::Get().ChosenCategories.Add(GetCategory());
		}
		UHazeDevToggleSubsystem::Get().bDirty = true;
		EntryData.bDirty = true;
#endif
	}

	UFUNCTION()
	private void OnClicked()
	{
		if (EntryData == nullptr)
			return;
		EntryData.Toggle.bState = !EntryData.Toggle.bState;
#if !RELEASE
		UHazeDevToggleSubsystem::Get().Toggles[EntryData.Path.TogglePath].bState = EntryData.Toggle.bState;
		UHazeDevToggleSubsystem::Get().bDirty = true;
		UHazeDevToggleSubsystem::Get().Toggles[EntryData.Path.TogglePath].OnChanged.Broadcast(EntryData.Toggle.bState);
#endif
		EntryData.bDirty = true;
	}

	UFUNCTION()
	void SetEntryData(UToggleDevMenuEntryWidgetData NewData)
	{
		EntryData = NewData;
		EntryData.bDirty = false;

		FLinearColor BackgroundColor = EntryData.bDarkBackground ? DarkColor : NormalColor;
		BackgroundBorder.BrushColor = BackgroundColor;

		bHasOptions = EntryData.Group.Options.Num() > 0 && TileWidgetClass != nullptr;
		bool bIsCategory = EntryData.bIsGenericHeader || EntryData.bIsMainCategory || EntryData.bIsSubcategory;
		if (bHasOptions && !bIsCategory)
		{
			SubcategoryPaddingBox.Visibility = ESlateVisibility::Collapsed;
			MainCategoryPaddingBox.Visibility = ESlateVisibility::Visible;
			SetOptionsVisibility(true);
			SetToggleVisibility(true);
			SetCategoryVisibility(false);
			FillOptionsData();
			return;
		}

		if (EntryData.bIsGenericHeader)
		{
			SubcategoryPaddingBox.Visibility = ESlateVisibility::Collapsed;
			MainCategoryPaddingBox.Visibility = ESlateVisibility::Collapsed;
			SetCategoryVisibility(false);
			SetOptionsVisibility(false);
			SetToggleVisibility(true);
			SetGenericHeaderData();
		}
		else if (EntryData.bIsInCategoryBox)
		{
			SetCategoryVisibility(true);
			SetToggleVisibility(false);
			SetOptionsVisibility(false);
			SetCategoryData();
		}
		else
		{
			SubcategoryPaddingBox.Visibility = ESlateVisibility::Collapsed;
			MainCategoryPaddingBox.Visibility = ESlateVisibility::Collapsed;
			SetCategoryVisibility(false);
			SetOptionsVisibility(false);
			SetToggleVisibility(true);
			SetToggleData();
		}
	}

	FName GetCategory()
	{
#if !RELEASE
		return EntryData.Path.TogglePath;
#else
		return FName();
#endif
	}

	void SetCategoryData()
	{
		bool bCategoryIsSelected = false;
		bool bCategoryIsShown = false;
		bool bIsGenericCategory = false;
#if !RELEASE
		bIsGenericCategory = UHazeDevToggleSubsystem::Get().IsGenericCategory(GetCategory());
		if (UHazeDevToggleSubsystem::Get().ChosenCategories.Contains(GetCategory()))
		{
			bCategoryIsSelected = true;
			bCategoryIsShown = true;
		}
		else if (UHazeDevToggleSubsystem::Get().ChosenCategories.Num() == 0)
		{
			bCategoryIsSelected = GetCategory() == UHazeDevToggleSubsystem::Get().LevelSpecificCategory;
			bCategoryIsShown = !bIsGenericCategory;
		}

		CategoryText.SetText(FText::FromName(EntryData.Path.TogglePath));
#endif

		FLinearColor BackgroundColor = ColorDebug::Gray * 0.5;
		FLinearColor TextColor = ColorDebug::Gray;
		// if (bIsGenericCategory)
		// {
		// 	BackgroundColor = ColorDebug::Gray * 0.2;
		// }
		if (bCategoryIsSelected)
		{
			BackgroundColor = ColorDebug::Verdant * 0.5;
			TextColor = ColorDebug::Seafoam;
		}
		else if (bCategoryIsShown)
		{
			BackgroundColor = ColorDebug::Verdant * 0.3;
			TextColor = ColorDebug::Seafoam * 0.9;
		}
		CategoryButton.SetBackgroundColor(BackgroundColor);
		CategoryText.SetColorAndOpacity(TextColor);
	}

	void SetGenericHeaderData()
	{
		UpdateFont(false);
		ToggleName.SetText(FText::FromString("Generic Game"));
		ToggleName.SetColorAndOpacity(ColorDebug::White * 0.8);
		ToggleName.ToolTipText = FText::FromString("Add your own Generic categories in UHazeDevToggleSubsystem IsGenericCategory()");
	}

	void SetToggleData()
	{
#if !RELEASE
		TArray<FString> Terms;
		EntryData.Path.TogglePath.ToString().ParseIntoArray(Terms, "/");
		ToggleName.SetColorAndOpacity(ColorDebug::White);
		UpdateFont(false);
		if (EntryData.bIsMainCategory)
			ToggleName.SetText(FText::FromString(Terms[0]));
		else if (EntryData.bIsSubcategory)
			ToggleName.SetText(FText::FromString(Terms[1]));
		else
			ToggleName.SetText(FText::FromString(Terms.Last()));

		bool bHasSubcategory = !EntryData.bIsSearching && !EntryData.bIsMainCategory && !EntryData.bIsSubcategory && Terms.Num() == 3;
		if (bHasSubcategory)
			SubcategoryPaddingBox.Visibility = ESlateVisibility::Visible;

		bool bHasMainCategory = !EntryData.bIsSearching && !EntryData.bIsMainCategory;
		if (bHasMainCategory)
			MainCategoryPaddingBox.Visibility = ESlateVisibility::Visible;
	
		ToggleButton.SetBackgroundColor(EntryData.Toggle.bState ? ColorDebug::Verdant * 0.7: ColorDebug::Carmine * 0.5);
		FString TooltipText = EntryData.Toggle.Tooltip;
		bool bIsCategory = EntryData.bIsMainCategory || EntryData.bIsSubcategory;
		if (bIsCategory)
			TooltipText = "";
		ToggleButton.ToolTipText = FText::FromString(TooltipText);
		ToggleName.ToolTipText = FText::FromString(TooltipText);

		ToggleValue.SetColorAndOpacity(EntryData.Toggle.bState ? ColorDebug::Seafoam : ColorDebug::Blush);
		ToggleValue.SetText(EntryData.Toggle.bState ? FText::FromString("ON") : FText::FromString("OFF"));
#endif
	}

	void FillOptionsData()
	{
#if !RELEASE
		TArray<FString> Terms;
		EntryData.Path.TogglePath.ToString().ParseIntoArray(Terms, "/");
		ToggleName.SetText(FText::FromString(Terms.Last()));
		UpdateFont(true);

		ToggleName.ToolTipText = FText::FromString(EntryData.Group.Tooltip);

		FName DefaultOption = EntryData.Group.Options[0];
		EntryData.Group.Options.Sort();

		int DesiredNum = EntryData.Group.Options.Num();
		int ChildCount = OptionsWrapBox.ChildrenCount;
		if (ChildCount > DesiredNum)
			CollapseUnusedOptionsUI(DesiredNum);

		for (int iOption = 0; iOption < EntryData.Group.Options.Num(); ++iOption)
		{
			FName OptionName = EntryData.Group.Options[iOption];
			FTogglesDevMenuOptionTileWidgetEntryData Entry;
			Entry.OptionName = OptionName;
			Entry.GroupPath = EntryData.Path.TogglePath;
			bool bIsSelectedByDefault = EntryData.Group.ChosenOption == NAME_None && OptionName == DefaultOption;
			Entry.bOptionIsSelected = EntryData.Group.ChosenOption == OptionName || bIsSelectedByDefault;
			Entry.bDirty = true;

			if (iOption >= OptionsWrapBox.AllChildren.Num())
			{
				UTogglesDevMenuOptionTileWidget TileWidget = Widget::CreateWidget(this, TileWidgetClass);
				OptionsWrapBox.AddChild(TileWidget);
				TileWidgets.Add(TileWidget);
			}
			TileWidgets[iOption].Visibility = ESlateVisibility::Visible;
			TileWidgets[iOption].SetEntryData(Entry);
		}
#endif
	}
	
	void UpdateFont(bool bIsIsOption)
	{
		auto Font = ToggleName.Font;
		if (OGFontSize < KINDA_SMALL_NUMBER)
			OGFontSize = Font.Size;

		Font.Size = OGFontSize;
		Font.SkewAmount = 0.0;

		if (bIsIsOption)
		{
			//Font.SkewAmount = 0.2;
			Font.Size *= 0.9;
		}
		ToggleName.Font = Font;
	}

	void SetToggleVisibility(bool bEnabled)
	{
		ESlateVisibility NewVisibility = bEnabled ? ESlateVisibility::Visible : ESlateVisibility::Collapsed;
		TogglesBox.Visibility = NewVisibility;
		ToggleButton.Visibility = (bHasOptions || EntryData.bIsGenericHeader || EntryData.bIsMainCategory || EntryData.bIsSubcategory) ? ESlateVisibility::Collapsed : ESlateVisibility::Visible;
	}

	void SetCategoryVisibility(bool bEnabled)
	{
		ESlateVisibility NewVisibility = bEnabled ? ESlateVisibility::Visible : ESlateVisibility::Collapsed;
		CategoryBox.Visibility = NewVisibility;
	}

	void SetOptionsVisibility(bool bEnabled)
	{
		ESlateVisibility NewVisibility = bEnabled ? ESlateVisibility::Visible : ESlateVisibility::Collapsed;
		OptionsBox.Visibility = NewVisibility;
	}

	void CollapseUnusedOptionsUI(int DesiredChildren = 0)
	{
		int ChildCount = OptionsWrapBox.ChildrenCount;
		for (int iChild = DesiredChildren; iChild < ChildCount; ++iChild)
			OptionsWrapBox.AllChildren[iChild].Visibility = ESlateVisibility::Collapsed;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (EntryData.bDirty)
			SetEntryData(EntryData);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		return FEventReply::Handled().SetUserFocus(ToggleButton, InFocusEvent.Cause);
	}
};

struct FTogglesDevMenuOptionTileWidgetEntryData
{
	FName GroupPath;
	FName OptionName;
	bool bOptionIsSelected = false;
	bool bDirty = true;
}

UCLASS(Abstract)
class  UTogglesDevMenuOptionTileWidget : UHazeUserWidget
{
	FTogglesDevMenuOptionTileWidgetEntryData TileData;

	UPROPERTY(BindWidget)
	UButton TileButton;
	UPROPERTY(BindWidget)
	UTextBlock TileName;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		TileButton.OnClicked.AddUFunction(this, n"OnClicked");
	}

	UFUNCTION()
	private void OnClicked()
	{
#if !RELEASE
		FHazeInternalDevToggleGroup& InternalGroup = UHazeDevToggleSubsystem::Get().ToggleGroups[TileData.GroupPath];
		InternalGroup.ChosenOption = TileData.OptionName;
		InternalGroup.OnChanged.Broadcast(TileData.OptionName);
		UHazeDevToggleSubsystem::Get().bDirty = true;
#endif
		TileData.bDirty = true;
	}

	UFUNCTION()
	void SetEntryData(FTogglesDevMenuOptionTileWidgetEntryData NewData)
	{
		TileData = NewData;
		TileData.bDirty = false;
		FString AsString = TileData.OptionName.ToString();
		TileName.SetText(FText::FromString(AsString));

		TileButton.SetBackgroundColor(TileData.bOptionIsSelected ? ColorDebug::Verdant * 0.7: ColorDebug::Gray * 0.5);
		TileName.SetColorAndOpacity(TileData.bOptionIsSelected ? ColorDebug::Fern : ColorDebug::Gray);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		return FEventReply::Handled().SetUserFocus(TileButton, InFocusEvent.Cause);
	}
}