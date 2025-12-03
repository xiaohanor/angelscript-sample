
event void FOnNavigateTemporalLog(FString NewPath);
event void FOnBookmarkTemporalLog(FString NewPath, bool bBookmark);

class UTemporalLogExplorerWidget : UHazeUserWidget
{
	UPROPERTY()
	UListView ListView;

	UPROPERTY(BindWidget)
	UHorizontalBox FilterBox;

	UPROPERTY(BindWidget)
	UComboBoxString FilterDropdown;

	UPROPERTY(BindWidget)
	UComboBoxString StatusDropdown;

	UPROPERTY()
	FOnNavigateTemporalLog OnNavigateTemporalLog;

	UPROPERTY()
	FOnBookmarkTemporalLog OnBookmarkTemporalLog;

	UPROPERTY(BindWidget)
	UEditableTextBox FilterTextBox;

	UPROPERTY(BindWidget)
	UButton ClearSearchButton;

	TArray<UObject> EntryObjects;
	TArray<UTemporalLogExplorerEntryData> Entries;
	FString LastFocus;

	TArray<FHazeTemporalLogReportNode> Bookmarks;
	TArray<FString> ShownFilters;
	TArray<FString> ShownStatuses;

	FString RememberedPath;
	UTemporalLogDevMenuConfig DevMenuConfig;

	bool bFiltersUpdated = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		FilterTextBox.OnTextChanged.AddUFunction(this, n"OnFilterTextChanged");
		ClearSearchButton.OnClicked.AddUFunction(this, n"OnClearSearch");
		FilterDropdown.OnSelectionChanged.AddUFunction(this, n"OnFilterChanged");
		StatusDropdown.OnSelectionChanged.AddUFunction(this, n"OnFilterChanged");
	}

	UFUNCTION()
	private void OnFilterChanged(FString SelectedItem, ESelectInfo SelectionType)
	{
		bFiltersUpdated = true;

		if (FilterDropdown.GetSelectedIndex() != 0)
		{
			FilterDropdown.WidgetStyle.ComboButtonStyle.ButtonStyle.Normal.TintColor = FLinearColor::MakeFromHex(0xff104040);
			FilterDropdown.WidgetStyle.ComboButtonStyle.ButtonStyle.Hovered.TintColor = FLinearColor::MakeFromHex(0xff104040);
		}
		else
		{
			FilterDropdown.WidgetStyle.ComboButtonStyle.ButtonStyle.Normal.TintColor = FLinearColor::MakeFromHex(0xff010101);
			FilterDropdown.WidgetStyle.ComboButtonStyle.ButtonStyle.Hovered.TintColor = FLinearColor::MakeFromHex(0xff010101);
		}

		if (StatusDropdown.GetSelectedIndex() != 0)
		{
			StatusDropdown.WidgetStyle.ComboButtonStyle.ButtonStyle.Normal.TintColor = FLinearColor::MakeFromHex(0xff104040);
			StatusDropdown.WidgetStyle.ComboButtonStyle.ButtonStyle.Hovered.TintColor = FLinearColor::MakeFromHex(0xff104040);
		}
		else
		{
			StatusDropdown.WidgetStyle.ComboButtonStyle.ButtonStyle.Normal.TintColor = FLinearColor::MakeFromHex(0xff010101);
			StatusDropdown.WidgetStyle.ComboButtonStyle.ButtonStyle.Hovered.TintColor = FLinearColor::MakeFromHex(0xff010101);
		}
	}

	UFUNCTION()
	private void OnClearSearch()
	{
		bFiltersUpdated = true;
		FilterTextBox.SetText(FText());
		FilterTextBox.SetForegroundColor(FLinearColor::MakeFromHex(0xff868686));
		ClearSearchButton.SetVisibility(ESlateVisibility::Collapsed);
	}

	UFUNCTION()
	private void OnFilterTextChanged(const FText&in Text)
	{
		bFiltersUpdated = true;

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
	}

	UFUNCTION(BlueprintPure)
	UWidget GetFocusEntry()
	{
		TArray<UUserWidget> DisplayedEntries = ListView.GetDisplayedEntryWidgets();
		for (int i = 0, Count = DisplayedEntries.Num(); i < Count; ++i)
		{
			auto EntryWidget = Cast<UTemporalLogExplorerEntry>(DisplayedEntries[i]);
			if (EntryWidget.EntryData.FullPath == LastFocus)
				return EntryWidget;
		}

		if (DisplayedEntries.Num() != 0)
			return DisplayedEntries[0];
		return nullptr;
	}

	bool HasSearchFilter() const
	{
		return !FilterTextBox.GetText().IsEmpty();
	}

	UFUNCTION()
	void UpdateFromReport(const FHazeTemporalLogReport& Report, const FString& SelectedPath)
	{
		TArray<FString> PossibleFilters;
		TArray<FString> PossibleStatuses;

		FString ActiveSearch = FilterTextBox.GetText().ToString();
		FString ActiveFilter;
		FString ActiveStatus;

		bool bRefreshFilters = false;
		if (RememberedPath != Report.ReportedPath)
		{
			if (DevMenuConfig != nullptr)
			{
				DevMenuConfig.RememberedFilters.Find(Report.ReportedPath, ActiveFilter);
				DevMenuConfig.RememberedStatuses.Find(Report.ReportedPath, ActiveStatus);

				ActiveSearch = "";
				DevMenuConfig.RememberedSearch.Find(Report.ReportedPath, ActiveSearch);
				FilterTextBox.SetText(FText::FromString(ActiveSearch));
				
				bRefreshFilters = true;
			}

			RememberedPath = Report.ReportedPath;
		}
		else
		{
			if (FilterDropdown.GetSelectedIndex() != 0)
			{
				ActiveFilter = FilterDropdown.GetSelectedOption();
				if (DevMenuConfig != nullptr)
					DevMenuConfig.RememberedFilters.Add(Report.ReportedPath, ActiveFilter);
			}
			else
			{
				if (DevMenuConfig != nullptr)
					DevMenuConfig.RememberedFilters.Remove(Report.ReportedPath);
			}

			if (StatusDropdown.GetSelectedIndex() != 0)
			{
				ActiveStatus = StatusDropdown.GetSelectedOption();
				if (DevMenuConfig != nullptr)
					DevMenuConfig.RememberedStatuses.Add(Report.ReportedPath, ActiveStatus);
			}
			else
			{
				if (DevMenuConfig != nullptr)
					DevMenuConfig.RememberedStatuses.Remove(Report.ReportedPath);
			}

			if (ActiveSearch.Len() != 0)
			{
				if (DevMenuConfig != nullptr)
					DevMenuConfig.RememberedSearch.Add(Report.ReportedPath, ActiveSearch);
			}
			else
			{
				if (DevMenuConfig != nullptr)
					DevMenuConfig.RememberedSearch.Remove(Report.ReportedPath);
			}
		}

		TArray<FString> StringFilters;
		ActiveSearch.ParseIntoArray(StringFilters, " ");

		if (bFiltersUpdated)
		{
			DevMenuConfig.Save();
			bFiltersUpdated = false;
		}

		Entries.Reserve(Report.ChildNodes.Num() + Bookmarks.Num() + 5);
		EntryObjects.Reserve(Report.ChildNodes.Num() + Bookmarks.Num() + 5);

		int Index = 0;

		// Add entries for bookmarks
		for (int i = 0, Count = Bookmarks.Num(); i < Count; ++i, ++Index)
		{
			if (!Entries.IsValidIndex(Index))
			{
				Entries.Add(UTemporalLogExplorerEntryData());
				EntryObjects.Add(Entries[Index]);
			}

			auto Entry = Entries[Index];
			Entry.ReportNode = Bookmarks[i];
			Entry.ReportStatusColor = Entry.ReportNode.StatusColor;
			Entry.DisplayName = "⭐ " + GetTemporalLogDisplayName(Bookmarks[i].DisplayName);
			Entry.FullPath = Bookmarks[i].Path;
			Entry.bSelected = false;
			Entry.bCanSelect = true;
			Entry.bDirty = true;
			Entry.bBookmarked = false;
			Entry.bIsBookmark = true;
			Entry.bIsSectionEnd = (i == Count-1);

			if (i == 0)
			{
				Entry.bIsHeadingStart = true;
				Entry.HeadingText = "Bookmarks";
			}
			else
			{
				Entry.bIsHeadingStart = false;
			}
		}

		// Show the entry for going up in the path tree
		if (Report.ReportedPath != "/")
		{
			if (!Entries.IsValidIndex(Index))
			{
				Entries.Add(UTemporalLogExplorerEntryData());
				EntryObjects.Add(Entries[Index]);
			}

			auto Entry = Entries[Index];
			Entry.DisplayName = "↑ ..";
			Entry.FullPath = GetTemporalLogParentPath(Report.ReportedPath);
			Entry.ReportNode = FHazeTemporalLogReportNode();
			Entry.bDirty = true;
			Entry.bSelected = false;
			Entry.bCanSelect = true;
			Entry.bBookmarked = false;
			Entry.bIsBookmark = false;
			Entry.bIsSectionEnd = false;
			Entry.bIsHeadingStart = false;
			Index += 1;
		}

		// Show the entry for selecting the values in the root
		if (Report.Values.Num() != 0)
		{
			if (!Entries.IsValidIndex(Index))
			{
				Entries.Add(UTemporalLogExplorerEntryData());
				EntryObjects.Add(Entries[Index]);
			}

			auto Entry = Entries[Index];
			Entry.DisplayName = Report.DisplayName;
			Entry.FullPath = Report.ReportedPath;
			Entry.ReportNode = FHazeTemporalLogReportNode();
			Entry.ReportStatusColor = Report.StatusColor;
			Entry.bDirty = true;
			Entry.bBookmarked = false;
			Entry.bIsBookmark = false;
			Entry.bIsSectionEnd = false;
			Entry.bIsHeadingStart = false;
			Entry.bSelected = (Entry.FullPath == SelectedPath);
			Entry.bCanSelect = true;
			Index += 1;
		}

		// Add entries for child nodes
		int FilteredEntries = 0;
		FString PrevHeading;
		for (int i = 0, Count = Report.ChildNodes.Num(); i < Count; ++i, ++Index)
		{
			bool bContainsFilter = false;
			for (const FString& Filter : Report.ChildNodes[i].MetaData.FilterKeywords)
			{
				PossibleFilters.AddUnique(Filter);
				if (Filter == ActiveFilter)
					bContainsFilter = true;
			}

			if (!Report.ChildNodes[i].Status.IsEmpty())
			{
				PossibleStatuses.AddUnique(Report.ChildNodes[i].Status);
			}

			if (!bContainsFilter && !ActiveFilter.IsEmpty())
			{
				// Skip entry if it doesn't match the active filter
				--Index;
				++FilteredEntries;
				continue;
			}
			
			if (!ActiveStatus.IsEmpty() && Report.ChildNodes[i].Status != ActiveStatus)
			{
				// Skip entry if it doesn't match the active status
				--Index;
				++FilteredEntries;
				continue;
			}

			if (StringFilters.Num() != 0)
			{
				bool bMatchesAllFilters = true;
				for (auto Filter : StringFilters)
				{
					if (!Report.ChildNodes[i].DisplayName.Contains(Filter))
					{
						bMatchesAllFilters = false;
						break;
					}
				}

				if (!bMatchesAllFilters)
				{
					--Index;
					++FilteredEntries;
					continue;
				}
			}

			if (!Entries.IsValidIndex(Index))
			{
				Entries.Add(UTemporalLogExplorerEntryData());
				EntryObjects.Add(Entries[Index]);
			}

			auto Entry = Entries[Index];
			Entry.ReportNode = Report.ChildNodes[i];
			Entry.ReportStatusColor = Entry.ReportNode.StatusColor;
			Entry.DisplayName = GetTemporalLogDisplayName(Entry.ReportNode.DisplayName);
			Entry.FullPath = Entry.ReportNode.Path;
			Entry.bSelected = (Entry.FullPath == SelectedPath);
			Entry.bCanSelect = true;
			Entry.bDirty = true;
			Entry.bBookmarked = false;
			Entry.bIsBookmark = false;
			Entry.bIsSectionEnd = false;
			Entry.bIsHeadingStart = false;

			if (Entry.ReportNode.MetaData.Heading != PrevHeading)
			{
				PrevHeading = Entry.ReportNode.MetaData.Heading;
				Entry.bIsHeadingStart = true;
				Entry.HeadingText = PrevHeading;
			}

			for (auto& Bookmark : Bookmarks)
			{
				if (Bookmark.Path == Entry.FullPath)
				{
					Entry.bBookmarked = true;
					break;
				}
			}
		}

		// Show the entry for how many entries were filtered
		if (FilteredEntries > 0)
		{
			if (!Entries.IsValidIndex(Index))
			{
				Entries.Add(UTemporalLogExplorerEntryData());
				EntryObjects.Add(Entries[Index]);
			}

			auto Entry = Entries[Index];
			Entry.DisplayName = f"{FilteredEntries} hidden by filters...";
			Entry.FullPath = "/";
			Entry.ReportNode = FHazeTemporalLogReportNode();
			Entry.ReportStatusColor = FLinearColor(0.33, 0.60, 0.77);
			Entry.bDirty = true;
			Entry.bBookmarked = false;
			Entry.bIsBookmark = false;
			Entry.bIsSectionEnd = false;
			Entry.bIsHeadingStart = false;
			Entry.bSelected = false;
			Entry.bCanSelect = false;
			Index += 1;
		}

		Entries.SetNum(Index);
		EntryObjects.SetNum(Index);

		ListView.SetListItems(EntryObjects);
		ListView.RequestRefresh();

		// Update the filter box
		if (ShownFilters != PossibleFilters || FilterDropdown.OptionCount == 0 || bRefreshFilters)
		{
			ShownFilters = PossibleFilters;

			if (ShownFilters.Num() == 0)
				FilterDropdown.Visibility = ESlateVisibility::Collapsed;
			else
				FilterDropdown.Visibility = ESlateVisibility::Visible;

			FilterDropdown.ClearOptions();
			FilterDropdown.AddOption("All");
			for (const FString& Filter : ShownFilters)
				FilterDropdown.AddOption(Filter);

			int ShownIndex = ShownFilters.FindIndex(ActiveFilter);
			if (ShownIndex != -1)
			{
				if (FilterDropdown.SelectedIndex != (1 + ShownIndex))
					FilterDropdown.SetSelectedIndex(1 + ShownIndex);
			}
			else if (FilterDropdown.SelectedIndex != 0)
			{
				FilterDropdown.SetSelectedIndex(0);
			}
		}

		if (ShownStatuses != PossibleStatuses || StatusDropdown.OptionCount == 0 || bRefreshFilters)
		{
			ShownStatuses = PossibleStatuses;

			if (ShownStatuses.Num() == 0)
				StatusDropdown.Visibility = ESlateVisibility::Collapsed;
			else
				StatusDropdown.Visibility = ESlateVisibility::Visible;

			StatusDropdown.ClearOptions();
			StatusDropdown.AddOption("Any");
			for (const FString& Status : ShownStatuses)
				StatusDropdown.AddOption(Status);

			int ShownIndex = ShownStatuses.FindIndex(ActiveStatus);
			if (ShownIndex != -1)
			{
				if (StatusDropdown.SelectedIndex != (1 + ShownIndex))
					StatusDropdown.SetSelectedIndex(1 + ShownIndex);
			}
			else if (!ActiveStatus.IsEmpty())
			{
				StatusDropdown.AddOption(ActiveStatus);
				StatusDropdown.SetSelectedIndex(StatusDropdown.OptionCount - 1);
			}
			else
			{
				StatusDropdown.SetSelectedIndex(0);
			}
		}
	}
};

class UTemporalLogExplorerEntryData
{
	UPROPERTY()
	FString DisplayName;
	UPROPERTY()
	FString FullPath;
	UPROPERTY()
	FHazeTemporalLogReportNode ReportNode;
	UPROPERTY()
	FLinearColor ReportStatusColor = FLinearColor::White;
	UPROPERTY()
	bool bSelected = false;
	UPROPERTY()
	bool bBookmarked = false;
	UPROPERTY()
	bool bIsBookmark = false;
	UPROPERTY()
	bool bIsSectionEnd = false;
	UPROPERTY()
	FString HeadingText;
	UPROPERTY()
	bool bIsHeadingStart = false;
	UPROPERTY()
	bool bCanSelect = false;

	bool bDirty = false;
};

class UTemporalLogExplorerEntry : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UHazeTextWidget HeadingText;

	UPROPERTY(BindWidget)
	UTextBlock NameText;

	UPROPERTY(BindWidget)
	UBorder BackgroundBorder;

	UPROPERTY()
	UTemporalLogExplorerEntryData EntryData;

	UPROPERTY()
	bool bHovered = false;

	UPROPERTY()
	bool bFocused = false;

	UFUNCTION()
	void SetEntryData(UTemporalLogExplorerEntryData NewData)
	{
		EntryData = NewData;
		UpdateLayout();
		Update();
	}

	void UpdateLayout()
	{
		auto BorderSlot = Cast<UVerticalBoxSlot>(BackgroundBorder.Slot);

		FMargin Margin;
		if (!EntryData.bCanSelect)
			Margin.Top += 5.0;
		if (EntryData.bIsSectionEnd)
			Margin.Bottom += 20.0;

		BorderSlot.SetPadding(Margin);

		if (EntryData.bIsBookmark)
			SetToolTipText(FText::FromString(EntryData.FullPath));
		else
			SetToolTip(nullptr);

		FSlateFontInfo Font = NameText.GetFont();
		if (EntryData.bCanSelect)
			Font.TypefaceFontName = n"Bold";
		else
			Font.TypefaceFontName = n"Italic";
		NameText.SetFont(Font);

		if (EntryData.bIsHeadingStart)
		{
			HeadingText.Visibility = ESlateVisibility::HitTestInvisible;
			HeadingText.Text = FText::FromString(EntryData.HeadingText);
			HeadingText.Update();
		}
		else
		{
			HeadingText.Visibility = ESlateVisibility::Collapsed;
		}
	}

	UFUNCTION(BlueprintEvent)
	void Update() {}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (EntryData.bDirty)
		{
			UpdateLayout();
			Update();
			EntryData.bDirty = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnAddedToFocusPath(FFocusEvent InFocusEvent)
	{
		bFocused = true;

		auto Explorer = Cast<UTemporalLogExplorerWidget>(GetParentWidgetOfClass(UTemporalLogExplorerWidget));
		if (Explorer != nullptr)
		{
			Explorer.LastFocus = EntryData.FullPath;
			Explorer.ListView.SetSelectedItem(EntryData);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnRemovedFromFocusPath(FFocusEvent InFocusEvent)
	{
		bFocused = false;
	}

	UFUNCTION(BlueprintPure)
	FLinearColor GetBackgroundColor() const
	{
		if (EntryData != nullptr && !EntryData.bCanSelect)
			return FLinearColor::Transparent;
		else if (IsHovered() || (bFocused && Widget::ShouldShowUserFocus(this)))
			return FLinearColor(0.0, 0.2, 0.5, 0.5);
		else if (EntryData != nullptr && EntryData.bSelected)
			return FLinearColor(0.05, 0.1, 0.15, 0.5);
		else
			return FLinearColor::Transparent;
	}

	UFUNCTION(BlueprintPure)
	FLinearColor GetTextColor() const
	{
		if (EntryData.ReportStatusColor.A < 0.25)
		{
			if (EntryData.bIsBookmark)
				return FLinearColor(1.0, 1.0, 0.0, 1.0);
			else
				return FLinearColor::White;
		}
		else
		{
			return EntryData.ReportStatusColor;
		}
	}

	void NavigateToEntry()
	{
		auto Explorer = Cast<UTemporalLogExplorerWidget>(GetParentWidgetOfClass(UTemporalLogExplorerWidget));
		if (Explorer != nullptr)
			Explorer.OnNavigateTemporalLog.Broadcast(EntryData.FullPath);
	}

	void BookmarkEntry()
	{
		if (EntryData.FullPath == "/")
			return;
		auto Explorer = Cast<UTemporalLogExplorerWidget>(GetParentWidgetOfClass(UTemporalLogExplorerWidget));
		if (Explorer != nullptr)
			Explorer.OnBookmarkTemporalLog.Broadcast(EntryData.FullPath, !EntryData.bIsBookmark);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (EntryData.bCanSelect)
		{
			if (MouseEvent.EffectingButton == EKeys::LeftMouseButton)
			{
				NavigateToEntry();
				return FEventReply::Handled();
			}
			else if (MouseEvent.EffectingButton == EKeys::RightMouseButton)
			{
				BookmarkEntry();
				return FEventReply::Handled();
			}
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (bFocused && EntryData.bCanSelect)
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
		if (bFocused && EntryData.bCanSelect)
		{
			if (InKeyEvent.Key == EKeys::Virtual_Accept
				|| InKeyEvent.Key == EKeys::SpaceBar
				|| InKeyEvent.Key == EKeys::Enter)
			{
				NavigateToEntry();
				return FEventReply::Handled();
			}
		}

		return FEventReply::Unhandled();
	}
};