
event void FOnCapabilitySelected(FHazeCapabilityDebugHandle Capability);

UCLASS(Config = EditorPerProjectUserSettings)
class UCapabilityDevMenuConfig
{
	UPROPERTY(Config)
	float MainSplitLeft = 0.5;
	UPROPERTY(Config)
	float MainSplitRight = 1.0;

	FString FilterText;
	bool bFilterHasCategory = false;
	FName FilterCategory;
	bool bFilterShowDeactive = true;
	bool bFilterShowNotStarted = false;
	FHazeCapabilityDebugHandle LastSelectedCapability;

	bool bConfigDirty = false;
	float LastConfigSave = -1.0;

	void UpdateConfig()
	{
#if EDITOR
		if (!bConfigDirty)
			return;

		if (LastConfigSave < 0.0 || LastConfigSave < Time::PlatformTimeSeconds - 1.0)
		{
			SaveConfig();
			LastConfigSave = Time::PlatformTimeSeconds;
			bConfigDirty = false;
		}
#endif
	}
};

UCLASS()
class UCapabilityDevMenuWidget : UHazeDevMenuEntryWidget
{
	UPROPERTY(Meta = (BindWidget))
	UDevCapabilityListWidget CapabilityList;

	UPROPERTY(Meta = (BindWidget))
	UDevCapabilityInfoWidget CapabilityInfo;

	UPROPERTY(Meta = (BindWidget))
	UComboBoxString CategoryFilter;

	UPROPERTY(Meta = (BindWidget))
	UCheckBox ShowDeactiveCheckbox;

	UPROPERTY(Meta = (BindWidget))
	UCheckBox ShowNotStartedCheckbox;

	UPROPERTY(Meta = (BindWidget))
	UEditableTextBox FilterTextBox;

	UPROPERTY()
	FHazeCapabilityDebugHandle SelectedCapability;

	UPROPERTY(BlueprintReadOnly)
	FString CurrentActorName = "";

	UPROPERTY(Meta = (BindWidget))
	USplitter MainSplitter;

	UCapabilityDevMenuConfig DevMenuConfig;
	TArray<float> SplitterSize;

	bool bWaitingForFocus = false;
	EFocusCause WaitingFocusCause;

	UHazeCapabilityComponent PrevComponent;
	AActor PrevActor;

	TArray<FString> CategoryDisplayStrings;
	TArray<FName> CategoryNames;


	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		DevMenuConfig = Cast<UCapabilityDevMenuConfig>(UCapabilityDevMenuConfig.DefaultObject);

		CapabilityList.OnCapabilitySelected.AddUFunction(this, n"OnCapabilitySelected");

		CategoryDisplayStrings.Add("All Capabilities");
		CategoryNames.Add(NAME_None);
		CategoryDisplayStrings.Add("Uncategorized");
		CategoryNames.Add(NAME_None);

		CategoryFilter.SetSelectedIndex(0);
		UpdateCategoryList(nullptr, bInitial = true);

		if (DevMenuConfig.bFilterShowDeactive) 
			ShowDeactiveCheckbox.SetCheckedState(ECheckBoxState::Checked);
		else
			ShowDeactiveCheckbox.SetCheckedState(ECheckBoxState::Unchecked);

		if (DevMenuConfig.bFilterShowNotStarted) 
			ShowNotStartedCheckbox.SetCheckedState(ECheckBoxState::Checked);
		else
			ShowNotStartedCheckbox.SetCheckedState(ECheckBoxState::Unchecked);

		FilterTextBox.SetText(FText::FromString(DevMenuConfig.FilterText));
		SelectedCapability = DevMenuConfig.LastSelectedCapability;

		// Restore split size from config
		for (int i = 0, Count = MainSplitter.GetChildrenCount(); i < Count; ++i)
		{
			float& SplitSize = (i == 0) ? DevMenuConfig.MainSplitLeft : DevMenuConfig.MainSplitRight;
			auto SplitSlot = Cast<USplitterSlot>(MainSplitter.GetChildAt(i).Slot);
			SplitSlot.SetSize(SplitSize);
			SplitterSize.Add(SplitSize);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Destruct()
	{
		SelectedCapability.SetIsDebugging(false);
	}

	UFUNCTION()
	private void OnCapabilitySelected(FHazeCapabilityDebugHandle Capability)
	{
		if (Capability == SelectedCapability)
			return;

		SelectedCapability.SetIsDebugging(false);
		SelectedCapability = Capability;

		CapabilityList.SelectedCapability = Capability;
		SelectedCapability.SetIsDebugging(true);

		DevMenuConfig.LastSelectedCapability = Capability;
	}

	void SelectCapability(FHazeCapabilityDebugHandle Handle)
	{
		if (Handle == SelectedCapability)
			return;

		OnCapabilitySelected(Handle);
		CapabilityList.SelectItemForCapability(Handle);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (InKeyEvent.Key == EKeys::Gamepad_FaceButton_Top || InKeyEvent.Key == EKeys::F)
		{
			// Cycle category filter
			CycleCategoryFilter();
			return FEventReply::Handled();
		}
		else if (InKeyEvent.Key == EKeys::Gamepad_FaceButton_Left || InKeyEvent.Key == EKeys::G)
		{
			// Cycle status filter
			CycleStatusFilter();
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (InKeyEvent.Key == EKeys::Gamepad_FaceButton_Top || InKeyEvent.Key == EKeys::F)
		{
			return FEventReply::Handled();
		}
		else if (InKeyEvent.Key == EKeys::Gamepad_FaceButton_Left || InKeyEvent.Key == EKeys::G)
		{
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintEvent)
	void UpdateActor() {}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		UHazeCapabilityComponent CapabilityComponent;
		auto Actor = GetDebugActor();
		if (Actor != nullptr)
			CapabilityComponent = UHazeCapabilityComponent::Get(Actor);

		// If we are looking at a different component, update selected capability
		if (PrevComponent != CapabilityComponent)
		{
			if (CapabilityComponent != nullptr)
				OnCapabilitySelected(SelectedCapability.GetCapabilityInOtherComponent(CapabilityComponent));
			else
				OnCapabilitySelected(FHazeCapabilityDebugHandle());

			CapabilityList.SelectItemForCapability(SelectedCapability);
			UpdateCategoryList(CapabilityComponent);
			PrevComponent = CapabilityComponent;
		}

		if (Actor != PrevActor)
		{
			if(Actor != nullptr)
			{
				CurrentActorName = Actor.GetName().ToString();
				if(Network::IsGameNetworked())
				{
					if(Actor.HasControl())
						CurrentActorName += " (Control)";
					else
						CurrentActorName += " (Remote)";
				}
			}

			UpdateActor();
			PrevActor = Actor;

		}

		// Update list of capabilities on the left
		UpdateFilter();
		CapabilityList.Update(CapabilityComponent);

		// Update capability info on the right
		if (SelectedCapability.IsValid())
		{
			CapabilityInfo.SetVisibility(ESlateVisibility::Visible);
			CapabilityInfo.UpdateFromHandle(SelectedCapability);
		}
		else
		{
			CapabilityInfo.SetVisibility(ESlateVisibility::Hidden);
		}

		// If we've resized the split, save that in config
		for (int i = 0, Count = MainSplitter.GetChildrenCount(); i < Count; ++i)
		{
			auto SplitSlot = Cast<USplitterSlot>(MainSplitter.GetChildAt(i).Slot);
			if (SplitterSize[i] != SplitSlot.Size)
			{
				float& SplitSize = (i == 0) ? DevMenuConfig.MainSplitLeft : DevMenuConfig.MainSplitRight;
				SplitSize = SplitSlot.Size;
				DevMenuConfig.bConfigDirty = true;
			}
		}

		// See if we should save the config
		DevMenuConfig.UpdateConfig();

		// Focus the right UI element if we want to
		if (bWaitingForFocus)
		{
			auto NewWidget = CapabilityList.GetFocusEntry();
			if (NewWidget != nullptr)
			{
				Widget::SetAllPlayerUIFocus(NewWidget, WaitingFocusCause);
				bWaitingForFocus = false;
			}
		}
	}

	void UpdateFilter()
	{
		CapabilityList.Filters.FilterString = FilterTextBox.GetText().ToString();

		int SelectedIndex = CategoryFilter.GetSelectedIndex();
		if (SelectedIndex <= 0)
		{
			CapabilityList.Filters.bFilterCategory = false;

			DevMenuConfig.FilterCategory = NAME_None;
			DevMenuConfig.bFilterHasCategory = false;
		}
		else
		{
			CapabilityList.Filters.bFilterCategory = true;
			CapabilityList.Filters.Category = CategoryNames[SelectedIndex];

			DevMenuConfig.FilterCategory = CategoryNames[SelectedIndex];
			DevMenuConfig.bFilterHasCategory = true;
		}

		CapabilityList.Filters.bDeactiveCapabilities = ShowDeactiveCheckbox.IsChecked();
		CapabilityList.Filters.bNotStartedCapabilities = ShowNotStartedCheckbox.IsChecked();

		DevMenuConfig.bFilterShowDeactive = ShowDeactiveCheckbox.IsChecked();
		DevMenuConfig.bFilterShowNotStarted = ShowNotStartedCheckbox.IsChecked();
		DevMenuConfig.FilterText = CapabilityList.Filters.FilterString;
	}

	void CycleCategoryFilter()
	{
		int Selected = Math::Max(CategoryFilter.GetSelectedIndex(), 0);
		Selected = (Selected + 1) % CategoryFilter.GetOptionCount();
		CategoryFilter.SetSelectedIndex(Selected);
	}

	void CycleStatusFilter()
	{
		if (ShowDeactiveCheckbox.IsChecked() && !ShowNotStartedCheckbox.IsChecked())
		{
			ShowDeactiveCheckbox.SetCheckedState(ECheckBoxState::Unchecked);
			ShowNotStartedCheckbox.SetCheckedState(ECheckBoxState::Unchecked);
		}
		else if (ShowDeactiveCheckbox.IsChecked() && ShowNotStartedCheckbox.IsChecked())
		{
			ShowDeactiveCheckbox.SetCheckedState(ECheckBoxState::Checked);
			ShowNotStartedCheckbox.SetCheckedState(ECheckBoxState::Unchecked);
		}
		else if (!ShowDeactiveCheckbox.IsChecked() && !ShowNotStartedCheckbox.IsChecked())
		{
			ShowDeactiveCheckbox.SetCheckedState(ECheckBoxState::Checked);
			ShowNotStartedCheckbox.SetCheckedState(ECheckBoxState::Checked);
		}
	}

	void UpdateCategoryList(UHazeCapabilityComponent CapabilityComponent, bool bInitial = false)
	{
		int SelectedIndex = CategoryFilter.GetSelectedIndex();
		FName SelectedCategory = CategoryNames[Math::Max(SelectedIndex, 0)];

		if (bInitial && DevMenuConfig.bFilterHasCategory)
		{
			if (DevMenuConfig.FilterCategory.IsNone())
			{
				SelectedCategory = NAME_None;
				SelectedIndex = 1;
			}
			else
			{
				SelectedCategory = DevMenuConfig.FilterCategory;
				SelectedIndex = -1;
			}
		}

		if (SelectedIndex >= 2)
			SelectedIndex = -1;

		CategoryDisplayStrings.SetNum(2);
		CategoryNames.SetNum(2);

		// Gather all categories
		if (CapabilityComponent != nullptr)
		{
			TArray<FHazeCapabilityDebugHandle> CapabilityHandles;
			FHazeCapabilityDebugFilter NoFilter;
			CapabilityDebug::GetFilteredCapabilityDebug(CapabilityComponent, NoFilter, CapabilityHandles);

			for (auto CapabilityHandle : CapabilityHandles)
			{
				FName Category = CapabilityHandle.GetCapabilityDebugCategory();
				if (Category == NAME_None)
					continue;
				if (CategoryNames.Contains(Category))
					continue;

				if (SelectedIndex == -1 && Category == SelectedCategory)
					SelectedIndex = CategoryNames.Num();
				CategoryNames.Add(Category);
				CategoryDisplayStrings.Add(Category.ToString());
			}
		}

		if (SelectedIndex == -1 && !SelectedCategory.IsNone())
		{
			SelectedIndex = CategoryNames.Num();
			CategoryNames.Add(SelectedCategory);
			CategoryDisplayStrings.Add(SelectedCategory.ToString());
		}

		// Update the combobox
		CategoryFilter.ClearOptions();
		for (auto DisplayCategory : CategoryDisplayStrings)
			CategoryFilter.AddOption(DisplayCategory);
		if (SelectedIndex != -1)
			CategoryFilter.SetSelectedIndex(SelectedIndex);
		else
			CategoryFilter.SetSelectedIndex(0);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		auto NewWidget = CapabilityList.GetFocusEntry();
		if (NewWidget != nullptr)
			return FEventReply::Handled().SetUserFocus(NewWidget, InFocusEvent.Cause);
		
		bWaitingForFocus = true;
		WaitingFocusCause = InFocusEvent.Cause;
		return FEventReply::Unhandled();
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
};

UCLASS()
class UDevCapabilityInfoWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UTemporalLogValueListWidget TemporalValues;
	UPROPERTY(BindWidget)
	UTemporalLogEventListWidget TemporalEvents;

	UPROPERTY(BindWidget)
	UBorder CompoundBorder;
	UPROPERTY(BindWidget)
	UHazeImmediateWidget CompoundDrawer;

	UPROPERTY()
	FHazeCapabilityDebugInfo DebugInfo;
	FHazeCapabilityDebugHandle DebugHandle;

	FHazeTemporalLogReport TemporalReport;

	UPROPERTY(BindWidget)
	USplitter MainSplitter;

	UPROPERTY(BindWidget)
	UButton BlockButton;
	UPROPERTY(BindWidget)
	UTextBlock BlockButtonText;

	UPROPERTY()
	TArray<float> SplitterSize;

	UCapabilityDevMenuConfig DevMenuConfig;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		DevMenuConfig = Cast<UCapabilityDevMenuConfig>(UCapabilityDevMenuConfig.DefaultObject);
		BlockButton.OnClicked.AddUFunction(this, n"OnBlockClicked");

		TemporalEvents.bClickable = false;
	}

	UFUNCTION(BlueprintPure)
	bool IsUnusedTickGroup() const
	{
		if (DebugInfo.bCapabilityHasInactiveTick)
		{
			if (DebugInfo.bIsActive && DebugInfo.bHandleIsInactiveTick)
				return true;
			if (!DebugInfo.bIsActive && !DebugInfo.bHandleIsInactiveTick)
				return true;
		}
		return false;
	}

	UFUNCTION(BlueprintPure)
	FString GetInfoString()
	{
		FString Info;

		// Show the list of current blockers
		TArray<FName> BlockedTags;
		FString Blockers;

		// Show each tag with an indicator if is blocked
		Info += "Tags:  ";
		for (int i = 0, Count = DebugInfo.Tags.Num(); i < Count; ++i)
		{
			if (i != 0)
				Info += ", ";

			FName Tag = DebugInfo.Tags[i];
			if (BlockedTags.Contains(Tag))
				Info += "<red>"+Tag.ToString()+"</>";
			else
				Info += Tag.ToString();
		}

		// Show current duration of status
		if (DebugInfo.bIsActive)
			Info += f"\nActive Duration:  <green>{DebugInfo.ActiveDuration :.1}s</>";
		else
			Info += f"\nDeactive Duration:  <red>{DebugInfo.DeactiveDuration :.1}s</>";

		// Show the correct tick group
		if (IsUnusedTickGroup())
			Info += "\n<yellow>Not used in this tick group due to separated active/inactive ticks.</>";

		// Add the actual text for blockers
		Info += Blockers;

		return Info;
	}

	void UpdateFromHandle(FHazeCapabilityDebugHandle Handle)
	{
		DebugHandle = Handle;
		Handle.GetCapabilityDebugInfo(DebugInfo);
		Handle.HandleDebugVisible();

		auto TemporalLog = UHazeTemporalLog::Get();

		TemporalReport = FHazeTemporalLogReport();
		if (TemporalLog != nullptr)
		{
			FHazeTemporalLogReportParams ReportParams;
			ReportParams.ReportFrame = TemporalLog.LastLoggedFrame;
			ReportParams.ReportPath = Handle.GetTemporalLogPath();
			ReportParams.EventHistoryCount = 100;
			TemporalLog.ReportOnFrame(ReportParams, TemporalReport);

			// Draw all shapes in the temporal log
			TemporalLog.DrawAllDebugShapes(ReportParams.ReportPath, ReportParams.ReportFrame);
		}

		TemporalValues.UpdateFromReport(TemporalReport);
		TemporalEvents.UpdateFromReport(TemporalReport, bForceBottom = false);

		if (Handle.IsCompoundCapability() || Handle.IsChildCapability())
			CompoundBorder.Visibility = ESlateVisibility::Visible;
		else
			CompoundBorder.Visibility = ESlateVisibility::Collapsed;

		Update();
		UpdateBlockButton();
	}

	UFUNCTION(BlueprintEvent)
	void Update() {}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (DebugHandle.IsValid()
			&& (DebugHandle.IsCompoundCapability() || DebugHandle.IsChildCapability())
			&& CompoundDrawer.Drawer.IsVisible())
		{
			auto CompoundHandle = DebugHandle;
			if (DebugHandle.IsChildCapability())
				CompoundHandle = DebugHandle.GetCompoundParent();

			// Draw the compound capability tree
			TArray<FHazeCapabilityCompoundDebug> CompoundTree;
			CompoundHandle.GetCompoundTree(CompoundTree);

			FCompoundCapabilityDebug CompoundHelper;

			// Find selected capability index
			for (int i = 0, Count = CompoundTree.Num(); i < Count; ++i)
			{
				if (CompoundTree[i].OptionalDebugCapability == DebugHandle)
				{
					CompoundHelper.SelectedIndex = i;
					break;
				}
			}

			auto Panel = CompoundDrawer.Drawer.BeginCanvasPanel();
			CompoundHelper.Draw(Panel, CompoundTree);

			if (CompoundHelper.ClickedIndex != -1)
				SelectCapability(CompoundTree[CompoundHelper.ClickedIndex].OptionalDebugCapability);
		}

	}

	void SelectCapability(FHazeCapabilityDebugHandle Handle)
	{
		auto DevMenu = Cast<UCapabilityDevMenuWidget>(GetParentWidgetOfClass(UCapabilityDevMenuWidget));
		if (DevMenu != nullptr)
			DevMenu.SelectCapability(Handle);
	}

	void UpdateBlockButton()
	{
		if (DebugHandle.IsBlockedByDevMenu())
			BlockButtonText.SetText(FText::FromString("Unblock"));
		else
			BlockButtonText.SetText(FText::FromString("Block"));
	}

	UFUNCTION()
	private void OnBlockClicked()
	{
		if (DebugHandle.IsBlockedByDevMenu())
			DebugHandle.SetBlockedByDevMenu(false);
		else
			DebugHandle.SetBlockedByDevMenu(true);
	}
};

enum EDebugCompoundType
{
	Unknown,
	RunAll,
	Sequence,
	Selector,
	StatePicker,
}


class UDevCapabilityListWidget : UHazeUserWidget
{
	UPROPERTY()
	UListView ListView;

	UPROPERTY()
	FOnCapabilitySelected OnCapabilitySelected;

	TArray<UObject> EntryObjects;
	TArray<UDevCapabilityEntryData> Entries;

	TArray<FHazeCapabilityDebugHandle> CapabilityHandles;

	FHazeCapabilityDebugFilter Filters;

	FHazeCapabilityDebugHandle SelectedCapability;
	FHazeCapabilityDebugHandle LastFocus;
	UUserWidget HasFocus;

	UHazeCapabilityComponent PrevComponent;

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
		UDevCapabilityEntryWidget LastFocusWidget;
		for (int i = 0, Count = DisplayedEntries.Num(); i < Count; ++i)
		{
			auto EntryWidget = Cast<UDevCapabilityEntryWidget>(DisplayedEntries[i]);
			if (EntryWidget.EntryData == ListView.GetSelectedItem())
			{
				return EntryWidget;
			}
			else if (EntryWidget.EntryData.Handle == LastFocus)
			{
				LastFocusWidget = EntryWidget;
			}
		}
		if (LastFocusWidget != nullptr)
			return LastFocusWidget;
		if (DisplayedEntries.Num() != 0)
			return DisplayedEntries[0];
		return nullptr;
	}

	void SelectItemForCapability(FHazeCapabilityDebugHandle Handle)
	{
		for (int i = 0, Count = Entries.Num(); i < Count; ++i)
		{
			if (Entries[i].Handle == Handle)
			{
				LastFocus = Handle;
				ListView.SetSelectedItem(Entries[i]);
				break;
			}
		}
	}

	UFUNCTION()
	void Update(UHazeCapabilityComponent CapabilityComponent)
	{
		if (PrevComponent != CapabilityComponent)
		{
			if (CapabilityComponent != nullptr)
				SelectedCapability = SelectedCapability.GetCapabilityInOtherComponent(CapabilityComponent);
			else
				SelectedCapability = FHazeCapabilityDebugHandle();
			PrevComponent = CapabilityComponent;
		}

		CapabilityHandles.Reset();
		CapabilityDebug::GetFilteredCapabilityDebug(CapabilityComponent, Filters, CapabilityHandles);

		int ValueCount = CapabilityHandles.Num();

		bool bNeedRefresh = false;
		if (Entries.Num() != ValueCount)
			bNeedRefresh = true;

		Entries.SetNum(ValueCount);
		EntryObjects.SetNum(ValueCount);

		EHazeTickGroup CurrentTickGroup = EHazeTickGroup::MAX;
		int SelectedIndex = -1;

		for (int i = 0; i < ValueCount; ++i)
		{
			// Create a new entry object if needed
			if (Entries[i] == nullptr)
			{
				Entries[i] = UDevCapabilityEntryData();
				EntryObjects[i] = Entries[i];
				bNeedRefresh = true;
			}

			// Set the data
			auto Handle = CapabilityHandles[i];
			auto Entry = Entries[i];

			if (Entry.Handle != Handle)
			{
				Entry.Handle = Handle;
				Entry.bDirty = true;
			}

			// Check whether this is selected
			Entry.bSelected = (Handle == SelectedCapability);
			if (Entry.bSelected)
				SelectedIndex = i;

			// If this indicates a new tick group we should tell the entry widget about that
			Entry.bFirstInTickGroup = false;
			if (!Handle.IsChildCapability())
			{
				auto TickGroup = Handle.CapabilityTickGroup;
				if (CurrentTickGroup != TickGroup)
				{
					Entry.bFirstInTickGroup = true;
					CurrentTickGroup = TickGroup;
				}
			}
		}

		if (bNeedRefresh)
		{
			ListView.SetListItems(EntryObjects);
			ListView.RequestRefresh();

			if (SelectedIndex != -1 && ListView.GetSelectedItem() != Entries[SelectedIndex])
				ListView.SetSelectedItem(Entries[SelectedIndex]);
		}
	}
};

class UDevCapabilityEntryData
{
	UPROPERTY()
	FHazeCapabilityDebugHandle Handle;

	UPROPERTY()
	bool bSelected = false;

	UPROPERTY()
	bool bFirstInTickGroup = false;

	bool bDirty = false;
};

class UDevCapabilityEntryWidget : UHazeUserWidget
{
	UPROPERTY()
	UDevCapabilityEntryData EntryData;
	UPROPERTY()
	FHazeCapabilityDebugInfo DebugInfo;

	bool bFocused = false;

	UFUNCTION(BlueprintEvent)
	void UpdateCapability() {}

	UFUNCTION(BlueprintEvent)
	void UpdateInfo() {}

	UFUNCTION(BlueprintPure)
	bool IsUnusedTickGroup() const
	{
		if (DebugInfo.bCapabilityHasInactiveTick)
		{
			if (DebugInfo.bIsActive && DebugInfo.bHandleIsInactiveTick)
				return true;
			if (!DebugInfo.bIsActive && !DebugInfo.bHandleIsInactiveTick)
				return true;
		}
		return false;
	}

	UFUNCTION(BlueprintPure)
	FString GetCapabilityName()
	{
		if (DebugInfo.bIsChild)
			return "👶 " + DebugInfo.DisplayName;
		return DebugInfo.DisplayName;
	}

	UFUNCTION(BlueprintPure)
	FString GetCapabilityTickOrder()
	{
		if (DebugInfo.TickSubPlacement == 0)
			return f"{DebugInfo.TickOrder}";
		else
			return f"{DebugInfo.TickSubPlacement}◃ {DebugInfo.TickOrder}";
	}

	UFUNCTION(BlueprintPure)
	bool ShouldShowTickOrder()
	{
		return !DebugInfo.bIsChild;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		// See if we need to update to a new entry
		if (EntryData.bDirty)
		{
			SetEntryData(EntryData);
			EntryData.bDirty = false;
		}

		// Update the display data for this capability
		EntryData.Handle.GetCapabilityDebugInfo(DebugInfo);
		UpdateInfo();
	}

	UFUNCTION()
	void SetEntryData(UDevCapabilityEntryData NewData)
	{
		EntryData = NewData;
		EntryData.Handle.GetCapabilityDebugInfo(DebugInfo);

		UpdateCapability();
		UpdateInfo();
	}

	UFUNCTION(BlueprintOverride)
	void OnAddedToFocusPath(FFocusEvent InFocusEvent)
	{
		bFocused = true;

		auto ValueList = Cast<UDevCapabilityListWidget>(GetParentWidgetOfClass(UDevCapabilityListWidget));
		if (ValueList != nullptr)
		{
			ValueList.LastFocus = EntryData.Handle;
			ValueList.HasFocus = this;
			ValueList.ListView.SetSelectedItem(EntryData);
			ValueList.OnCapabilitySelected.Broadcast(EntryData.Handle);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnRemovedFromFocusPath(FFocusEvent InFocusEvent)
	{
		bFocused = false;

		auto ValueList = Cast<UDevCapabilityListWidget>(GetParentWidgetOfClass(UDevCapabilityListWidget));
		if (ValueList != nullptr)
		{
			ValueList.LastFocus = EntryData.Handle;
			if (ValueList.HasFocus == this)
				ValueList.HasFocus = nullptr;
		}
	}

	UFUNCTION(BlueprintPure)
	FLinearColor GetBackgroundColor() const
	{
		bool bHovered = IsHovered() && EntryData != nullptr;
		if (EntryData != nullptr && EntryData.bSelected)
		{
			if (bHovered)
				return FLinearColor(0.05, 0.1, 0.15, 0.85);
			else
				return FLinearColor(0.05, 0.1, 0.15, 0.65);
		}
		else if (bHovered || bFocused)
			return FLinearColor(1.0, 1.0, 1.0, 0.05);
		else
			return FLinearColor::Transparent;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.EffectingButton == EKeys::LeftMouseButton)
		{
			auto ValueList = Cast<UDevCapabilityListWidget>(GetParentWidgetOfClass(UDevCapabilityListWidget));
			if (ValueList != nullptr)
				ValueList.OnCapabilitySelected.Broadcast(EntryData.Handle);
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
				auto ValueList = Cast<UDevCapabilityListWidget>(GetParentWidgetOfClass(UDevCapabilityListWidget));
				if (ValueList != nullptr)
					ValueList.OnCapabilitySelected.Broadcast(EntryData.Handle);
				return FEventReply::Handled();
			}
		}

		return FEventReply::Unhandled();
	}
};