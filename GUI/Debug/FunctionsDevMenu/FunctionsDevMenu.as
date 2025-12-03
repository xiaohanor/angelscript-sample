UCLASS(Config = EditorPerProjectUserSettings)
class UFunctionsDevMenuConfig
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
class UFunctionsDevMenu : UHazeDevMenuEntryWidget
{
	UPROPERTY(BindWidget)
	UListView FunctionsList;

	UPROPERTY(BindWidget)
	UTextBlock FilteredCountText;

	UPROPERTY(BindWidget)
	UEditableTextBox FilterTextBox;

	UPROPERTY(BindWidget)
	UButton ClearSearchButton;

	bool bFunctionsDirty = true;
	int LevelStreamingCounter = -1;

	TArray<UFunctionDevMenuEntryData> Entries;
	TArray<UObject> EntryObjects;

	bool bWaitingForFocus = false;
	EFocusCause WaitingFocusCause;

	UFunctionsDevMenuConfig DevMenuConfig;

	float LastRefreshTime = 0;
	const float RefreshInterval = 1;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		DevMenuConfig = Cast<UFunctionsDevMenuConfig>(FindObject(GetTransientPackage(), "FunctionsDevMenuConfig"));
		if (DevMenuConfig == nullptr)
			DevMenuConfig = NewObject(GetTransientPackage(), UFunctionsDevMenuConfig, n"FunctionsDevMenuConfig", true);

		FilterTextBox.SetText(FText::FromString(DevMenuConfig.FilterString));
		OnFilterTextChanged(FText());

		FilterTextBox.OnTextChanged.AddUFunction(this, n"OnFilterTextChanged");
		ClearSearchButton.OnClicked.AddUFunction(this, n"OnClearSearch");
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

		bFunctionsDirty = true;
	}

	UFUNCTION()
	private void OnClearSearch()
	{
		DevMenuConfig.FilterString = "";
		DevMenuConfig.Save();
		
		FilterTextBox.SetText(FText());
		FilterTextBox.SetForegroundColor(FLinearColor::MakeFromHex(0xff868686));
		ClearSearchButton.SetVisibility(ESlateVisibility::Collapsed);
		bFunctionsDirty = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		// Update our list of dev functions if it's dirty
		if (bFunctionsDirty || Time::GetGameTimeSince(LastRefreshTime) > RefreshInterval || LevelStreamingCounter != Progress::LocalLevelStreamingActivationCounter)
		{
			bFunctionsDirty = false;
			LevelStreamingCounter = Progress::LocalLevelStreamingActivationCounter;
			LastRefreshTime = Time::GameTimeSeconds;

			UpdateFunctions();
		}

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
		TArray<UUserWidget> DisplayedEntries = FunctionsList.GetDisplayedEntryWidgets();
		if (DisplayedEntries.Num() != 0)
			return DisplayedEntries[0];
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

	void UpdateFunctions()
	{
		float StartTime = Time::PlatformTimeSeconds;

		FHazeDevFunctionsInWorld List;
		DevMenu::GatherAllDevFunctions(List);

		TArray<FString> FilterTerms;
		FilterTextBox.GetText().ToString().ParseIntoArray(FilterTerms, " ");

		int PreviousEntryNum = EntryObjects.Num();

		Entries.SetNum(List.Functions.Num());
		EntryObjects.SetNum(List.Functions.Num());

		int FilterHiddenFunctions = 0;

		UObject ActiveObject = nullptr;
		int EntryIndex = 0;
		for (int i = 0, Count = List.Functions.Num(); i < Count; ++i)
		{
			if (FilterTerms.Num() != 0)
			{
				bool bMatchesFilter = true;
				for (FString Term : FilterTerms)
				{
					if (List.Functions[i].DisplayName.ToString().Contains(Term))
						continue;
					if (List.Functions[i].Object.Name.ToString().Contains(Term))
						continue;
#if EDITOR
					auto Actor = Cast<AActor>(List.Functions[i].Object);
					if (Actor != nullptr && Actor.GetActorLabel().Contains(Term))
						continue;
#endif

					bMatchesFilter = false;
					break;
				}

				if (!bMatchesFilter)
				{
					FilterHiddenFunctions += 1;
					continue;
				}
			}

			if (EntryObjects[EntryIndex] == nullptr)
			{
				Entries[EntryIndex] = UFunctionDevMenuEntryData();
				EntryObjects[EntryIndex] = Entries[EntryIndex];
			}

			auto Entry = Entries[EntryIndex];
			Entry.Function = List.Functions[i];
			Entry.bDirty = true;

			if (Entry.Function.Object != ActiveObject)
			{
				Entry.bIsObjectHeader = true;
				ActiveObject = Entry.Function.Object;

				if (ActiveObject.IsA(ALevelScriptActor))
				{
					Entry.HeaderName = ActiveObject.Name.PlainNameString;
					Entry.HeaderName.RemoveFromEnd("_C");
					Entry.bHeaderIsLevel = true;
				}
				else if (ActiveObject.IsA(AActor))
				{
#if EDITOR
					Entry.HeaderName = Cast<AActor>(ActiveObject).GetActorLabel();
#else
					Entry.HeaderName = ActiveObject.Name.ToString();
					Entry.HeaderName.RemoveFromEnd("_0");
#endif
					Entry.bHeaderIsLevel = false;
				}
				else
				{
					AActor InsideActor = nullptr;
					UObject OuterObject = ActiveObject.Outer;
					while (OuterObject != nullptr)
					{
						InsideActor = Cast<AActor>(OuterObject);
						if (InsideActor != nullptr)
							break;
						else
							OuterObject = OuterObject.Outer;
					}

					Entry.bHeaderIsLevel = false;
					Entry.HeaderName = ActiveObject.Name.ToString();
					Entry.HeaderName.RemoveFromEnd("_0");

					if (InsideActor != nullptr)
					{
						Entry.HeaderName += f" ({InsideActor.ActorNameOrLabel}";
						Entry.HeaderName.RemoveFromEnd("_0");
						Entry.HeaderName += ")";
					}
				}
			}
			else
			{
				Entry.bIsObjectHeader = false;
			}

			EntryIndex += 1;
		}

		Entries.SetNum(EntryIndex);
		EntryObjects.SetNum(EntryIndex);

		FunctionsList.SetListItems(EntryObjects);

		if (PreviousEntryNum != EntryObjects.Num())
		{
			FunctionsList.RegenerateAllEntries();
		}

		if (FilterHiddenFunctions != 0)
		{
			FilteredCountText.Visibility = ESlateVisibility::HitTestInvisible;
			FilteredCountText.Text = FText::FromString(f"{FilterHiddenFunctions} functions hidden by filter...");
		}
		else
		{
			FilteredCountText.Visibility = ESlateVisibility::Collapsed;
		}

		float EndTime = Time::PlatformTimeSeconds;
		// Log(f"Gathering dev functions took {(EndTime - StartTime) * 1000.0} ms");
	}
};

class UFunctionDevMenuEntryData
{
	bool bDirty = true;
	bool bIsObjectHeader = false;
	bool bHeaderIsLevel = false;
	FString HeaderName;
	FHazeDevFunction Function;
};

UCLASS(Abstract)
class UFunctionsDevMenuEntryWidget : UHazeUserWidget
{
	UFunctionDevMenuEntryData EntryData;

	UPROPERTY(BindWidget)
	UButton FunctionButton;

	UPROPERTY(BindWidget)
	UTextBlock FunctionName;

	UPROPERTY(BindWidget)
	UTextBlock HeaderText;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		FunctionButton.OnClicked.AddUFunction(this, n"OnClicked");
	}

	UFUNCTION()
	private void OnClicked()
	{
		if (EntryData == nullptr)
			return;
		DevMenu::CallDevFunction(EntryData.Function.Object, EntryData.Function.FunctionName);
	}

	UFUNCTION()
	void SetEntryData(UFunctionDevMenuEntryData NewData)
	{
		EntryData = NewData;
		EntryData.bDirty = false;
		FunctionName.SetText(FText::FromString(NewData.Function.DisplayName.ToString()));

		if (NewData.bIsObjectHeader)
		{
			HeaderText.Visibility = ESlateVisibility::HitTestInvisible;
			HeaderText.SetText(FText::FromString(NewData.HeaderName));

			FSlateColor Color;
			
			FSlateFontInfo Font = HeaderText.GetFont();
			if (NewData.bHeaderIsLevel)
			{
				Font.Size = 14;
				Color.SpecifiedColor = FLinearColor(0.2, 1.0, 0.2);
			}
			else
			{
				Font.Size = 12;
				Color.SpecifiedColor = FLinearColor(0.5, 0.5, 0.5);
			}

			HeaderText.SetFont(Font);
			HeaderText.SetColorAndOpacity(Color);
		}
		else
		{
			HeaderText.Visibility = ESlateVisibility::Collapsed;
		}
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
		return FEventReply::Handled().SetUserFocus(FunctionButton, InFocusEvent.Cause);
	}
};