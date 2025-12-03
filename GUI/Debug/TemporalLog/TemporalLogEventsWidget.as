
event void FOnBrowseToEvent(int EventFrame);

class UTemporalLogEventListWidget : UHazeUserWidget
{
	UPROPERTY()
	UListView ListView;
	UPROPERTY()
	FOnBrowseToEvent OnBrowseToEvent;

	UPROPERTY()
	bool bClickable = true;

	UPROPERTY()
	bool bShowFrameNumbers = false;

	TArray<UObject> EntryObjects;
	TArray<UTemporalLogEventEntryData> Entries;

	UUserWidget HasFocus;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
	}

	UFUNCTION(BlueprintPure)
	UWidget GetFocusEntry()
	{
		TArray<UUserWidget> DisplayedEntries = ListView.GetDisplayedEntryWidgets();

		UTemporalLogEventEntryWidget BestWidget;
		int BestFrame = -1;
		for (int i = 0, Count = DisplayedEntries.Num(); i < Count; ++i)
		{
			auto EntryWidget = Cast<UTemporalLogEventEntryWidget>(DisplayedEntries[i]);
			if (!Entries.Contains(EntryWidget.EntryData))
				continue;
			if (EntryWidget.EntryData.Value.Frame > BestFrame)
			{
				BestFrame = EntryWidget.EntryData.Value.Frame;
				BestWidget = EntryWidget;
			}
		}
		if (BestWidget != nullptr)
			return BestWidget;

		return nullptr;
	}

	UFUNCTION()
	void ToggleFrameNumbers()
	{
		bShowFrameNumbers = !bShowFrameNumbers;
		for (auto Entry : Entries)
		{
			Entry.bShowFrameNumbers = bShowFrameNumbers;
			Entry.bDirty = true;
		}
		ListView.RequestRefresh();
	}

	UFUNCTION()
	void UpdateFromReport(const FHazeTemporalLogReport& Report, bool bForceBottom = true)
	{
		int EventCount = Report.Events.Num();
		int EntryCount = EventCount;

		if (Report.EventsPrecedingReport != 0)
			EntryCount += 1;

		bool bRefresh = false;
		if (EntryCount != Entries.Num())
			bRefresh = true;
		bool bAtBottom = ListView.DistanceFromBottom < 0.001;

		Entries.SetNum(EntryCount);
		EntryObjects.SetNum(EntryCount);

		// Add the 'more entries' entry
		int EntryIndex = 0;
		if (Report.EventsPrecedingReport != 0)
		{
			if (Entries[0] == nullptr)
			{
				Entries[0] = UTemporalLogEventEntryData();
				EntryObjects[0] = Entries[0];
				bRefresh = true;
			}

			auto Entry = Entries[0];
			Entry.Value = FHazeTemporalLogReportEvent();
			Entry.bIsMoreEntry = true;
			Entry.MoreCount = Report.EventsPrecedingReport;
			Entry.ReportedFrame = Report.ReportedFrame;
			Entry.bDirty = true;
			Entry.bClickable = bClickable;
			Entry.bShowFrameNumbers = bShowFrameNumbers;
			EntryIndex += 1;
		}

		for (int i = 0; i < EventCount; ++i, ++EntryIndex)
		{
			// Create a new entry object if needed
			if (Entries[EntryIndex] == nullptr)
			{
				Entries[EntryIndex] = UTemporalLogEventEntryData();
				EntryObjects[EntryIndex] = Entries[EntryIndex];
				bRefresh = true;
			}

			// Set the data
			auto Entry = Entries[EntryIndex];
			Entry.ReportedFrame = Report.ReportedFrame;
			Entry.Value = Report.Events[i];
			Entry.bIsMoreEntry = false;
			Entry.bDirty = true;
			Entry.bClickable = bClickable;
			Entry.bShowFrameNumbers = bShowFrameNumbers;
		}

		if (bRefresh)
		{
			ListView.SetListItems(EntryObjects);
			ListView.RequestRefresh();

			if (bForceBottom || bAtBottom)
				ListView.ScrollToBottom();
		}

		if (HasFocus != nullptr)
		{
			auto NewEntry = GetFocusEntry();
			if (NewEntry != nullptr)
				Widget::SetAllPlayerUIFocus(NewEntry);
		}
	}
};

class UTemporalLogEventEntryData
{
	UPROPERTY()
	FHazeTemporalLogReportEvent Value;

	UPROPERTY()
	int ReportedFrame = -1;

	UPROPERTY()
	bool bIsMoreEntry = false;

	UPROPERTY()
	int MoreCount = 0;

	UPROPERTY()
	bool bShowFrameNumbers = false;

	bool bClickable = false;
	bool bDirty = false;
};

class UTemporalLogEventEntryWidget : UHazeUserWidget
{
	UPROPERTY()
	UTemporalLogEventEntryData EntryData;

	UPROPERTY()
	bool bIsCurrentFrame = false;

	UPROPERTY()
	bool bFocused = false;

	UFUNCTION(BlueprintPure)
	bool IsClickable()
	{
		return EntryData != nullptr && EntryData.bClickable;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (EntryData.bDirty)
		{
			SetEntryData(EntryData);
			EntryData.bDirty = false;
		}
	}

	UFUNCTION(BlueprintEvent)
	void Update() {}

	UFUNCTION()
	void SetEntryData(UTemporalLogEventEntryData NewData)
	{
		EntryData = NewData;
		bIsCurrentFrame = (EntryData.ReportedFrame == EntryData.Value.Frame);
		Update();
	}

	UFUNCTION()
	void BrowseToEvent()
	{
		auto EventList = Cast<UTemporalLogEventListWidget>(GetParentWidgetOfClass(UTemporalLogEventListWidget));
		if (EventList != nullptr)
		{
			EventList.OnBrowseToEvent.Broadcast(EntryData.Value.Frame);
			EventList.HasFocus = this;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnAddedToFocusPath(FFocusEvent InFocusEvent)
	{
		bFocused = true;

		auto EventList = Cast<UTemporalLogEventListWidget>(GetParentWidgetOfClass(UTemporalLogEventListWidget));
		if (EventList != nullptr)
		{
			EventList.ListView.SetSelectedItem(EntryData);
			if (EventList.HasFocus == this)
				EventList.HasFocus = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnRemovedFromFocusPath(FFocusEvent InFocusEvent)
	{
		bFocused = false;
	}

	UFUNCTION(BlueprintPure)
	FString GetTimestamp()
	{
		if (EntryData == nullptr)
			return "";

		if (EntryData.bShowFrameNumbers)
		{
			return f"[Frame {EntryData.Value.Frame : >4}]";
		}
		else if (EntryData.Value.GameTime >= 0.0)
		{
			return f"[{EntryData.Value.GameTime : 4.2} s]";
		}
		else
		{
			return "[  End  ]";
		}
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
				BrowseToEvent();
				return FEventReply::Handled();
			}
		}

		return FEventReply::Unhandled();
	}
};