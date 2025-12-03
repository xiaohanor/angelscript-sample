UCLASS(Config = EditorPerProjectUserSettings)
class UTogglesDevMenuConfig
{
	UPROPERTY(Config)
	FString FilterString;

	void Save()
	{
#if EDITOR
		SaveConfig();
#endif
	}
};

UCLASS(Abstract)
class UTogglesDevMenu : UHazeDevMenuEntryWidget
{
	UPROPERTY(BindWidget)
	UListView CategoryList;
	TArray<UToggleDevMenuEntryWidgetData> CategoriesEntriesUI;
	TArray<UObject> CategoriesEntryObjects;

	UPROPERTY(BindWidget)
	UListView TogglesList;
	TArray<UToggleDevMenuEntryWidgetData> EntriesUI;
	TArray<UObject> EntryObjects;

	UPROPERTY(BindWidget)
	UVerticalBox PresetsBox;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UTogglesDevPresetEntryWidget> PresetWidgetClass;
	TArray<UTogglesDevPresetEntryWidget> PresetWidgets;
	UPROPERTY(BindWidget)
	UWrapBox PresetsWrapBox;

	UPROPERTY(BindWidget)
	UEditableTextBox FilterTextBox;

	UPROPERTY(BindWidget)
	UButton DefaultsButton;

	UPROPERTY(BindWidget)
	UButton ClearSearchButton;

	UPROPERTY(BindWidget)
	UTextBlock WarningText;

	bool bTogglesDirty = true;
	int LevelStreamingCounter = -1;

	bool bWaitingForFocus = false;
	EFocusCause WaitingFocusCause;

	UTogglesDevMenuConfig DevMenuConfig;

	float LastRefreshTime = 0;
	const float RefreshInterval = 1;

	bool bWasPlaying = false;
	TSet<FName> TogglesAddedLastSession;

	TArray<FName> Categories;
	TArray<FName> GenericCategories;
	TArray<FName> SubCategories;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		DevMenuConfig = Cast<UTogglesDevMenuConfig>(FindObject(GetTransientPackage(), "TogglesDevMenuConfig"));
		if (DevMenuConfig == nullptr)
			DevMenuConfig = NewObject(GetTransientPackage(), UTogglesDevMenuConfig, n"TogglesDevMenuConfig", true);

		FilterTextBox.SetText(FText::FromString(DevMenuConfig.FilterString));
		OnFilterTextChanged(FText());

		FilterTextBox.OnTextChanged.AddUFunction(this, n"OnFilterTextChanged");
		ClearSearchButton.OnClicked.AddUFunction(this, n"OnClearSearch");

		DefaultsButton.OnClicked.AddUFunction(this, n"SetAllToDefault");
	}

	UFUNCTION(BlueprintOverride)
	void Destruct()
	{
#if !RELEASE
		UHazeDevToggleSubsystem::Get().TogglesAddedThisSession.Reset();
		UHazeDevToggleSubsystem::Get().TogglesCalledButNotAddedThisSession.Reset();
		DevMenu::ResetTogglePresets();
#endif		
	}

	UFUNCTION()
	private void SetAllToDefault()
	{
#if !RELEASE
		for (auto Toggle : UHazeDevToggleSubsystem::Get().Toggles)
		{
			Toggle.Value.bState = false;
		}
		for (auto ToggleGroup : UHazeDevToggleSubsystem::Get().ToggleGroups)
		{
			ToggleGroup.Value.ChosenOption = NAME_None;
		}
		UHazeDevToggleSubsystem::Get().bDirty = true;
#endif	
	}

	UFUNCTION()
	private void OnFilterTextChanged(const FText&in Text)
	{
		DevMenuConfig.FilterString = FilterTextBox.GetText().ToString();
		DevMenuConfig.Save();

		if (FilterTextBox.GetText().IsEmpty())
		{
			ClearSearchButton.SetVisibility(ESlateVisibility::Collapsed);
			FilterTextBox.SetForegroundColor(FLinearColor::MakeFromHex(0xff868686));
		}
		else
		{
			ClearSearchButton.SetVisibility(ESlateVisibility::Visible);
			FilterTextBox.SetForegroundColor(FLinearColor::MakeFromHex(0xff40ffff));
		}

		bTogglesDirty = true;
	}

	UFUNCTION()
	private void OnClearSearch()
	{
		DevMenuConfig.FilterString = "";
		DevMenuConfig.Save();
		
		FilterTextBox.SetText(FText());
		FilterTextBox.SetForegroundColor(FLinearColor::MakeFromHex(0xff868686));
		ClearSearchButton.SetVisibility(ESlateVisibility::Collapsed);
		bTogglesDirty = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		// Update our list of dev Toggles if it's dirty
		bool bHasNewToggle = false;

#if !RELEASE
		int ActiveStreamingCounter = -1;

#if EDITOR
		if (Editor::IsPlaying())
		{
			FScopeDebugPrimaryWorld ScopeWorld;
			ActiveStreamingCounter = Progress::LocalLevelStreamingActivationCounter;

			TogglesAddedLastSession.Reset();
			bWasPlaying = true;
		}
		else
		{
			if (bWasPlaying)
			{
				TogglesAddedLastSession = UHazeDevToggleSubsystem::Get().TogglesAddedThisSession;
				UHazeDevToggleSubsystem::Get().TogglesAddedThisSession.Reset();
				UHazeDevToggleSubsystem::Get().TogglesCalledButNotAddedThisSession.Reset();
				bWasPlaying = false;
			}
		}
#else
		{
			FScopeDebugPrimaryWorld ScopeWorld;
			ActiveStreamingCounter = Progress::LocalLevelStreamingActivationCounter;
		}
#endif

		bHasNewToggle = UHazeDevToggleSubsystem::Get().bDirty;
		if (bHasNewToggle || bTogglesDirty || LevelStreamingCounter != ActiveStreamingCounter) // Time::GetGameTimeSince(LastRefreshTime) > RefreshInterval ||
		{
			UHazeDevToggleSubsystem::Get().ShowGenericGameCategories();
			bTogglesDirty = false;
			LevelStreamingCounter = ActiveStreamingCounter;

			UpdateToggles();
		}
#endif

		// Focus the right UI element if we want to
		if (bWaitingForFocus)
		{
			auto NewWidget = GetFocusEntry();
			if (NewWidget != nullptr)
			{
				Widget::SetAllPlayerUIFocus(NewWidget, WaitingFocusCause);
				bWaitingForFocus = false;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		auto NewWidget = GetFocusEntry();
		if (NewWidget != nullptr)
			return FEventReply::Handled().SetUserFocus(NewWidget, InFocusEvent.Cause);
		
		bWaitingForFocus = true;
		WaitingFocusCause = InFocusEvent.Cause;
		return FEventReply::Unhandled();
	}

	UWidget GetFocusEntry()
	{
		TArray<UUserWidget> DisplayedEntries = TogglesList.GetDisplayedEntryWidgets();
		if (DisplayedEntries.Num() != 0)
			return DisplayedEntries[0];
		TArray<UUserWidget> DisplayedCategories = CategoryList.GetDisplayedEntryWidgets();
		if (DisplayedCategories.Num() != 0)
			return DisplayedCategories[0];
		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void OnAddedToFocusPath(FFocusEvent InFocusEvent)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnRemovedFromFocusPath(FFocusEvent InFocusEvent)
	{
		bWaitingForFocus = false;
	}

#if !RELEASE
	void UpdateToggles()
	{
		UHazeDevToggleSubsystem::Get().bDirty = false;
		float StartTime = Time::PlatformTimeSeconds;

		TArray<FString> SearchTerms;
		FilterTextBox.GetText().ToString().ParseIntoArray(SearchTerms, " ");
		bool bSearching = SearchTerms.Num() > 0;

		int PreviousEntryNum = EntryObjects.Num();

		Categories.Reset(16);
		SubCategories.Reset(16);
		GenericCategories.Reset(8);

		TArray<FHazeDevToggleEntry> DataEntries;
		FillDataEntries(DataEntries, SearchTerms, bSearching);

		EntriesUI.SetNum(DataEntries.Num());
		EntryObjects.SetNum(DataEntries.Num());
		DataEntries.Sort(true);

		FillToggleUIEntries(DataEntries, bSearching);
		Categories.Sort(false);
		Categories.Insert(UHazeDevToggleSubsystem::Get().LevelSpecificCategory, 0);
		GenericCategories.Sort(true);
		FillCategoriesUIEntries();

 		TogglesList.SetListItems(EntryObjects);
		CategoryList.SetListItems(CategoriesEntryObjects);

		if (PreviousEntryNum != EntryObjects.Num())
			TogglesList.RegenerateAllEntries();

		WarnHiddenToggles();

		TogglePresets(bSearching);

		float EndTime = Time::PlatformTimeSeconds;
		// Log(f"Gathering dev Toggles took {(EndTime - StartTime) * 1000.0} ms");
	}

	void FillDataEntries(TArray<FHazeDevToggleEntry>& OutArray, const TArray<FString>& SearchTerms, bool bSearching)
	{
		TMap<FName, FHazeInternalDevToggleBool> Toggles = UHazeDevToggleSubsystem::Get().Toggles;
		for (auto KeyPair : Toggles)
		{
			if (!UHazeDevToggleSubsystem::Get().TogglesAddedThisSession.Contains(KeyPair.Key) && !TogglesAddedLastSession.Contains(KeyPair.Key))
				continue;
			FHazeDevToggleEntry Data(KeyPair.Value, KeyPair.Key);
			AddToggle(OutArray, Data, SearchTerms, bSearching);
		}
		
		TMap<FName, FHazeInternalDevToggleGroup> ToggleGroups = UHazeDevToggleSubsystem::Get().ToggleGroups;
		for (auto KeyPair : ToggleGroups)
		{
			if (!KeyPair.Value.bMakeVisibleThisSession)
				continue;
			if (!UHazeDevToggleSubsystem::Get().TogglesAddedThisSession.Contains(KeyPair.Key) && !TogglesAddedLastSession.Contains(KeyPair.Key))
				continue;
			if (!ensure(KeyPair.Value.Options.Num() > 0, "Registered Dev Toggle Group " + KeyPair.Key + " has no Options!"))
				continue;
			FHazeDevToggleEntry Data(KeyPair.Value, KeyPair.Key);
			AddToggle(OutArray, Data, SearchTerms, bSearching);
		}
	}

	void AddToggle(TArray<FHazeDevToggleEntry>& OutArray, FHazeDevToggleEntry& ToggleRef, const TArray<FString>& SearchTerms, bool bSearching)
	{
		ToggleRef.AssignFuzzyScore(SearchTerms);
		bool bAddedCategroy = false;
		bool bIsGenericCategory = UHazeDevToggleSubsystem::Get().IsGenericCategory(ToggleRef.Category);
		if (bIsGenericCategory && !GenericCategories.Contains(ToggleRef.Category))
		{
			bAddedCategroy = true;
			GenericCategories.Add(ToggleRef.Category);
		}
		if (!bIsGenericCategory && !Categories.Contains(ToggleRef.Category))
		{
			bAddedCategroy = true;
			Categories.Add(ToggleRef.Category);
		}

		bool bIsLevelSpecificShown = UHazeDevToggleSubsystem::Get().ChosenCategories.Num() == 0 && !bIsGenericCategory;
		if (bIsLevelSpecificShown || UHazeDevToggleSubsystem::Get().ChosenCategories.Contains(ToggleRef.Category))
		{
			if (bAddedCategroy && !bSearching)
			{
				ToggleRef.bIsMaincategory = true;
				OutArray.Add(ToggleRef);
			}
			ToggleRef.bIsMaincategory = false;

			if (!ToggleRef.Subcategory.IsNone() && !SubCategories.Contains(ToggleRef.Subcategory) && !bSearching)
			{
				SubCategories.Add(ToggleRef.Subcategory);
				ToggleRef.bIsSubcategory = true;
				OutArray.Add(ToggleRef);
			}
			ToggleRef.bIsSubcategory = false;
			OutArray.Add(ToggleRef);
		}
	}

	void FillToggleUIEntries(const TArray<FHazeDevToggleEntry>& DataEntries, bool bSearching)
	{
#if !RELEASE
		for (int iToggle = 0; iToggle < DataEntries.Num(); ++iToggle)
		{
			if (EntryObjects[iToggle] == nullptr)
			{
				EntriesUI[iToggle] = UToggleDevMenuEntryWidgetData();
				EntryObjects[iToggle] = EntriesUI[iToggle];
			}

			const FHazeDevToggleEntry& Data = DataEntries[iToggle];
			UToggleDevMenuEntryWidgetData Entry = EntriesUI[iToggle];
			Entry.Path.TogglePath = Data.WholePath;
			Entry.Toggle = Data.BoolData;
			Entry.Group = Data.GroupData;
			Entry.bIsSubcategory = Data.bIsSubcategory;
			Entry.bIsMainCategory = Data.bIsMaincategory;
			Entry.bDirty = true;
			Entry.bIsSearching = bSearching;
			Entry.bDarkBackground = Data.GroupData.Options.Num() > 0;
			EntryObjects[iToggle] = EntriesUI[iToggle];
		}
#endif
	}

	void FillCategoriesUIEntries()
	{
#if !RELEASE
		int TotalNumNumCategories = Categories.Num();
		TotalNumNumCategories += GenericCategories.Num() + 1; // +1 for generic header
		CategoriesEntriesUI.SetNum(TotalNumNumCategories);
		CategoriesEntryObjects.SetNum(TotalNumNumCategories);

		int iCategory = 0;
		while (iCategory < Categories.Num())
		{
			if (CategoriesEntryObjects[iCategory] == nullptr)
			{
				CategoriesEntriesUI[iCategory] = UToggleDevMenuEntryWidgetData();
				CategoriesEntryObjects[iCategory] = CategoriesEntriesUI[iCategory];
			}
			UToggleDevMenuEntryWidgetData Entry = CategoriesEntriesUI[iCategory];
			Entry.Path.TogglePath = Categories[iCategory];
			Entry.Toggle = FHazeInternalDevToggleBool();
			Entry.bDirty = true;
			Entry.bIsInCategoryBox = true;
			Entry.bIsGenericHeader = false;
			Entry.bDarkBackground = false;
			CategoriesEntryObjects[iCategory] = CategoriesEntriesUI[iCategory];
			++iCategory;
		}

		{
			if (CategoriesEntryObjects[iCategory] == nullptr)
			{
				CategoriesEntriesUI[iCategory] = UToggleDevMenuEntryWidgetData();
				CategoriesEntryObjects[iCategory] = CategoriesEntriesUI[iCategory];
			}
			UToggleDevMenuEntryWidgetData Entry = CategoriesEntriesUI[iCategory];
			Entry.Path.TogglePath = n"Generic";
			Entry.Toggle = FHazeInternalDevToggleBool();
			Entry.bDirty = true;
			Entry.bIsInCategoryBox = true;
			Entry.bIsGenericHeader = true;
			Entry.bDarkBackground = false;
			CategoriesEntryObjects[iCategory] = CategoriesEntriesUI[iCategory];
			++iCategory;
		}

		GenericCategories.Sort();
		int GenericCategory = 0;
		while (iCategory < TotalNumNumCategories)
		{
			if (CategoriesEntryObjects[iCategory] == nullptr)
			{
				CategoriesEntriesUI[iCategory] = UToggleDevMenuEntryWidgetData();
				CategoriesEntryObjects[iCategory] = CategoriesEntriesUI[iCategory];
			}
			UToggleDevMenuEntryWidgetData Entry = CategoriesEntriesUI[iCategory];
			Entry.Path.TogglePath = GenericCategories[GenericCategory];
			Entry.Toggle = FHazeInternalDevToggleBool();
			Entry.bDirty = true;
			Entry.bIsInCategoryBox = true;
			Entry.bIsGenericHeader = false;
			Entry.bDarkBackground = false;
			CategoriesEntryObjects[iCategory] = CategoriesEntriesUI[iCategory];

			++GenericCategory;
			++iCategory;
		}
#endif
	}

	void WarnHiddenToggles()
	{
		WarningText.Visibility = ESlateVisibility::Collapsed;
		FString WarningMessage = "WARNING! " + UHazeDevToggleSubsystem::Get().TogglesCalledButNotAddedThisSession.Num() + " toggle(s) hidden, didn't call MakeVisible()! [Hover for info]";
		FString WarningTooltip = "Hidden Toggles: ";
		if (UHazeDevToggleSubsystem::Get().TogglesCalledButNotAddedThisSession.Num() > 0)
			WarningText.Visibility = ESlateVisibility::Visible;
		for (FName NotAdded : UHazeDevToggleSubsystem::Get().TogglesCalledButNotAddedThisSession)
			WarningTooltip += "\n " + NotAdded;
		WarningText.SetText(FText::FromString(WarningMessage));
		WarningText.SetToolTipText(FText::FromString(WarningTooltip));
	}

	void TogglePresets(bool bSearching)
	{
		TMap<FName, FHazeToggleInternalPreset> Presets = DevMenu::GetDevTogglePresets();
		int DesiredNum = Presets.Num();
		bool bShouldBeVisible = DesiredNum > 0 && !bSearching && PresetWidgetClass != nullptr;
		PresetsBox.Visibility = bShouldBeVisible ? ESlateVisibility::Visible : ESlateVisibility::Collapsed;
		if (PresetsBox.Visibility == ESlateVisibility::Collapsed)
			return;

		int ChildCount = PresetsWrapBox.ChildrenCount;
		if (ChildCount > DesiredNum)
			CollapseUnusedPresetsUI(DesiredNum);

		int iPreset = 0;
		for (auto PresetKeyValue : Presets)
		{
			FTogglesDevPresetEntryData Entry;
			Entry.Path = PresetKeyValue.Key;
			Entry.Name = PresetKeyValue.Value.PresetName;
			Entry.bDirty = true;
			if (iPreset >= PresetsWrapBox.AllChildren.Num())
			{
				PresetWidgets.Add(Widget::CreateWidget(PresetsWrapBox, PresetWidgetClass));
				PresetsWrapBox.AddChild(PresetWidgets[iPreset]);
			}
			PresetWidgets[iPreset].Visibility = ESlateVisibility::Visible;
			PresetWidgets[iPreset].SetEntryData(Entry);
			++iPreset;
		}
	}

	void CollapseUnusedPresetsUI(int DesiredChildren = 0)
	{
		int ChildCount = PresetsWrapBox.ChildrenCount;
		for (int iChild = DesiredChildren; iChild < ChildCount; ++iChild)
			PresetsWrapBox.AllChildren[iChild].Visibility = ESlateVisibility::Collapsed;
	}
#endif
};
