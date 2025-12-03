event void FOnTemporalValueClicked(FString ValuePath);

class UTemporalLogValueListWidget : UHazeUserWidget
{
	UPROPERTY()
	UListView ListView;

	UPROPERTY()
	FOnTemporalValueClicked OnValueClicked;

	UPROPERTY()
	bool bClickable = false;

	TArray<UObject> EntryObjects;
	TArray<UTemporalLogValueEntryData> Entries;

	FString LastFocus;
	UUserWidget HasFocus;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
	}

	UFUNCTION(BlueprintPure)
	UWidget GetFirstEntry()
	{
		TArray<UUserWidget> DisplayedEntries = ListView.GetDisplayedEntryWidgets();
		if (DisplayedEntries.Num() != 0)
			return DisplayedEntries[0];
		return nullptr;
	}

	UFUNCTION(BlueprintPure)
	UWidget GetLastEntry()
	{
		TArray<UUserWidget> DisplayedEntries = ListView.GetDisplayedEntryWidgets();
		if (DisplayedEntries.Num() != 0)
			return DisplayedEntries.Last();
		return nullptr;
	}

	UFUNCTION(BlueprintPure)
	UWidget GetFocusEntry()
	{
		TArray<UUserWidget> DisplayedEntries = ListView.GetDisplayedEntryWidgets();
		for (int i = 0, Count = DisplayedEntries.Num(); i < Count; ++i)
		{
			auto EntryWidget = Cast<UTemporalLogValueEntryWidget>(DisplayedEntries[i]);
			if (EntryWidget.EntryData.FullPath == LastFocus)
				return EntryWidget;
		}
		if (DisplayedEntries.Num() != 0)
			return DisplayedEntries[0];
		return nullptr;
	}

	UFUNCTION()
	void UpdateFromReport(const FHazeTemporalLogReport& Report)
	{
		int ValueCount = Report.Values.Num();
		Entries.SetNum(ValueCount);
		EntryObjects.SetNum(ValueCount);

		TArray<FString> PrevHeadingPath;

		int EntryIndex = 0;
		for (int i = 0; i < ValueCount; ++i)
		{
			// Create a new entry object if needed
			if (Entries[EntryIndex] == nullptr)
			{
				Entries[EntryIndex] = UTemporalLogValueEntryData();
				EntryObjects[EntryIndex] = Entries[EntryIndex];
			}

			// Set the data
			auto Entry = Entries[EntryIndex];
			Entry.DisplayName = Report.Values[i].DisplayName;
			Entry.Value = Report.Values[i];
			Entry.FullPath = Report.Values[i].Path;
			Entry.bClickable = bClickable;
			Entry.bDirty = true;

			Entry.DisplayHeadings.Reset();
			Entry.HeadingLevel = Report.Values[i].SectionPath.Num();

			if (Report.Values[i].SectionPath != PrevHeadingPath)
			{
				Entry.DisplayHeadings = Report.Values[i].SectionPath;

				for (int n = 0; n < PrevHeadingPath.Num() && Entry.DisplayHeadings.Num() > 0; ++n)
				{
					if (PrevHeadingPath[n] == Entry.DisplayHeadings[0])
						Entry.DisplayHeadings.RemoveAt(0);
					else
						break;
				}

				PrevHeadingPath = Report.Values[i].SectionPath;
			}

			EntryIndex += 1;
		}

		ListView.SetListItems(EntryObjects);
		ListView.RequestRefresh();
	}

	FString GetTemporalValueDisplayName(FString ValueName)
	{
		int FoundIndex = -1;
		if (ValueName.FindChar('#', FoundIndex))
			return ValueName.Mid(FoundIndex+1).TrimStartAndEnd();
		else
			return ValueName;
	}

	void UpdateWatchStatus(TArray<FString> ActiveWatches)
	{
		for (auto EntryData : Entries)
			EntryData.bIsWatched = ActiveWatches.Contains(EntryData.FullPath);
	}
};

class UTemporalLogValueEntryData
{
	UPROPERTY()
	FHazeTemporalLogReportValue Value;
	UPROPERTY()
	FString DisplayName;
	UPROPERTY()
	TArray<FString> DisplayHeadings;
	UPROPERTY()
	int HeadingLevel = 0;
	UPROPERTY()
	FString FullPath;
	UPROPERTY()
	bool bClickable;
	UPROPERTY()
	bool bIsWatched;

	bool bDirty = false;
};

class UTemporalLogValueEntryWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UVerticalBox HeadingsBox;

	UPROPERTY(BindWidget)
	UButton BrowseButton;

	UPROPERTY()
	UTemporalLogValueEntryData EntryData;

	UPROPERTY()
	FString EntryName;

	UPROPERTY()
	FLinearColor NameColor;

	UPROPERTY()
	FString EntryValue;

	UPROPERTY()
	FLinearColor ValueColor;

	UPROPERTY()
	bool bFocused = false;

	TArray<UTextBlock> HeadingWidgets;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		BrowseButton.OnClicked.AddUFunction(this, n"OnBrowseClicked");
	}

	bool CanBrowseTo(UObject Object) const
	{
#if EDITOR
		if (Object == nullptr)
			return false;
		if (Object.IsA(AActor))
			return true;
		if (Object.IsA(UActorComponent))
			return true;
		if (Object.IsA(UHazeCapability))
			return true;
		if (Object.IsA(UClass))
			return true;
		if (Object.Outermost.GetPathName().StartsWith("/Game"))
			return true;
#endif
		return false;
	}

	UObject GetBrowseObject() const
	{
		UObject Object = nullptr;
		if (EntryData != nullptr && EntryData.Value.Type == ETemporalLogValueType::Object)
		{
			Object = FindObject(nullptr, EntryData.Value.DataValue);
			if (Object == nullptr)
				Object = FindObject(nullptr, Editor::RemovePIEPrefix(EntryData.Value.DataValue));
		}
		return Object;
	}

	UFUNCTION()
	private void OnBrowseClicked()
	{
#if EDITOR
		if (EntryData == nullptr)
			return;

		UObject Object = GetBrowseObject();
		if (Object == nullptr)
			return;

		if (Object.IsA(AActor))
		{
			auto Actor = Cast<AActor>(Object);
			Editor::SelectActor(Actor, true);
		}
		else if (Object.IsA(UActorComponent))
		{
			auto Comp = Cast<UActorComponent>(Object);
			Editor::SelectActor(Comp.Owner, true);
			Editor::SelectComponent(Comp);
		}
		else if (Object.IsA(UHazeCapability))
		{
			Editor::OpenEditorForClass(Object.Class);
		}
		else if (Object.IsA(UClass))
		{
			Editor::OpenEditorForClass(Cast<UClass>(Object));
		}
		else if (Object.Outermost.GetPathName().StartsWith("/Game"))
		{
			TArray<UObject> Assets;
			Assets.Add(Object);
			Editor::SyncContentBrowserToAssets(Assets);
		}
#endif
	}

	void UpdateDisplayNameForBrowseObject(UObject Object)
	{
		UHazeCapability Capability = Cast<UHazeCapability>(Object);
		if (Capability != nullptr)
		{
			EntryValue = Capability.Class.Name.ToString();
			EntryValue.RemoveFromEnd("_C");
			return;
		}

		UActorComponent Component = Cast<UActorComponent>(Object);
		if (Component != nullptr)
		{
			EntryValue = f"{Component.Name} ({Component.Owner.ActorNameOrLabel})";
			return;
		}

		AActor Actor = Cast<AActor>(Object);
		if (Actor != nullptr)
		{
			EntryValue = Actor.ActorNameOrLabel;
			return;
		}
	}

	UFUNCTION(BlueprintEvent)
	void Update() {}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (EntryData.bDirty)
		{
			SetEntryData(EntryData);
			EntryData.bDirty = false;
		}
	}

	UFUNCTION()
	void SetEntryData(UTemporalLogValueEntryData NewData)
	{
		EntryData = NewData;

		EntryName = EntryData.DisplayName;
		EntryValue = EntryData.Value.DisplayValue;

		NameColor = FLinearColor::White;
		ValueColor = FLinearColor::White;

		if (EntryData != nullptr && EntryData.Value.bChangedThisFrame)
			NameColor = FLinearColor(1.0, 0.4, 0.8);

		if (EntryData != nullptr && EntryData.Value.Color.A != 0)
			ValueColor = EntryData.Value.Color.ReinterpretAsLinear();
		else if (EntryValue == "true")
			ValueColor = FLinearColor::Green;
		else if (EntryValue == "false")
			ValueColor = FLinearColor::Red;
		else
			ValueColor = NameColor;

		// Update headings
		int HeadingsCount = EntryData.DisplayHeadings.Num();
		if (HeadingsCount != HeadingWidgets.Num())
		{
			for (int i = 0, Count = HeadingWidgets.Num(); i < Count; ++i)
				HeadingWidgets[i].RemoveFromParent();
			HeadingWidgets.Reset();

			for (int i = 0; i < HeadingsCount; ++i)
			{
				auto Widget = NewObject(this, UTextBlock);

				FSlateColor Color;
				Color.ColorUseRule = ESlateColorStylingMode::UseColor_Specified;
				Color.SpecifiedColor = FLinearColor(0.35, 0.35, 0.35, 1.0);
				Widget.ColorAndOpacity = Color;

				HeadingsBox.AddChild(Widget);
				HeadingWidgets.Add(Widget);
			}
		}

		for (int i = 0; i < HeadingsCount; ++i)
		{
			auto Widget = HeadingWidgets[i];
			Widget.Text = FText::FromString(EntryData.DisplayHeadings[i]);

			if(Widget.Text.IsEmpty())
				Widget.Visibility = ESlateVisibility::Collapsed;
			else
				Widget.Visibility = ESlateVisibility::HitTestInvisible;

			int HeadingLevel = (EntryData.HeadingLevel - HeadingsCount + i);

			auto Font = Widget.Font;
			Font.Size = Math::Max(14 - (2 * HeadingLevel), 11);
			Widget.Font = Font;

			auto HeadingSlot = Cast<UVerticalBoxSlot>(Widget.Slot);
			FMargin SlotPadding;
			SlotPadding.Left = 4.0 + 20.0*HeadingLevel;
			SlotPadding.Top = Math::Max(15.0 - (HeadingLevel * 10.0), 0.0);
			SlotPadding.Right = 2.0;
			SlotPadding.Bottom = 2.0;
			HeadingSlot.Padding = SlotPadding;
		}

		UObject Object = GetBrowseObject();
		if (Object != nullptr && CanBrowseTo(Object))
			BrowseButton.Visibility = ESlateVisibility::Visible;
		else
			BrowseButton.Visibility = ESlateVisibility::Collapsed;

		if (Object != nullptr)
			UpdateDisplayNameForBrowseObject(Object);
		Update();
	}

	UFUNCTION(BlueprintOverride)
	void OnAddedToFocusPath(FFocusEvent InFocusEvent)
	{
		bFocused = true;

		auto ValueList = Cast<UTemporalLogValueListWidget>(GetParentWidgetOfClass(UTemporalLogValueListWidget));
		if (ValueList != nullptr)
		{
			ValueList.LastFocus = EntryData.FullPath;
			ValueList.HasFocus = this;
			ValueList.ListView.SetSelectedItem(EntryData);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnRemovedFromFocusPath(FFocusEvent InFocusEvent)
	{
		bFocused = false;

		auto ValueList = Cast<UTemporalLogValueListWidget>(GetParentWidgetOfClass(UTemporalLogValueListWidget));
		if (ValueList != nullptr)
		{
			ValueList.LastFocus = EntryData.FullPath;
			if (ValueList.HasFocus == this)
				ValueList.HasFocus = nullptr;
		}
	}

	UFUNCTION(BlueprintPure)
	FLinearColor GetBackgroundColor() const
	{
		bool bHovered = IsHovered() && EntryData != nullptr && EntryData.bClickable;
		bool bWatched = EntryData != nullptr && EntryData.bIsWatched;

		if (bWatched)
		{
			return FLinearColor(0.0, 1.0, 0.5, bHovered ? 0.1 : 0.05);
		}
		else if (bHovered || bFocused)
		{
			return FLinearColor(1.0, 1.0, 1.0, 0.05);
		}
		else
		{
			return FLinearColor::Transparent;
		}
	}

	void OpenContextMenu()
	{
		FHazeContextMenu Menu;

		{
			FHazeContextOption Option;
			Option.Type = EHazeContextOptionType::Option;
			Option.Label = "Copy Value to Clipboard";
			Option.Icon = n"GenericCommands.Copy";
			Menu.AddOption(Option, FHazeContextDelegate(this, n"CopyToClipboard"));
		}

		UObject Object = GetBrowseObject();
		if (Object != nullptr && CanBrowseTo(Object))
		{
			FHazeContextOption Option;
			Option.Type = EHazeContextOptionType::Option;
			Option.Label = "Browse to Object";
			Option.Tooltip = "Browse to the logged object in the editor.";
			Option.Icon = n"Icons.BrowseContent";
			Menu.AddOption(Option, FHazeContextDelegate(this, n"OnBrowseTo"));
		}

		Menu.ShowContextMenu();
	}

	UFUNCTION()
	private void OnBrowseTo(FHazeContextOption Option)
	{
		OnBrowseClicked();
	}

	UFUNCTION()
	private void CopyToClipboard(FHazeContextOption Option)
	{
		Editor::CopyToClipBoard(EntryData.Value.DataValue);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.EffectingButton == EKeys::LeftMouseButton)
		{
			auto ValueList = Cast<UTemporalLogValueListWidget>(GetParentWidgetOfClass(UTemporalLogValueListWidget));
			if (ValueList != nullptr)
				ValueList.OnValueClicked.Broadcast(EntryData.FullPath);
			return FEventReply::Handled();
		}
		else if (MouseEvent.EffectingButton == EKeys::RightMouseButton)
		{
			OpenContextMenu();
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (bFocused)
		{
			if (InKeyEvent.Key == EKeys::Virtual_Accept
				|| InKeyEvent.Key == EKeys::SpaceBar
				|| InKeyEvent.Key == EKeys::Enter)
			{
				return FEventReply::Handled();
			}
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (bFocused)
		{
			if (InKeyEvent.Key == EKeys::Virtual_Accept
				|| InKeyEvent.Key == EKeys::SpaceBar
				|| InKeyEvent.Key == EKeys::Enter)
			{
				auto ValueList = Cast<UTemporalLogValueListWidget>(GetParentWidgetOfClass(UTemporalLogValueListWidget));
				if (ValueList != nullptr)
					ValueList.OnValueClicked.Broadcast(EntryData.FullPath);
				return FEventReply::Handled();
			}
		}

		return FEventReply::Unhandled();
	}
};
