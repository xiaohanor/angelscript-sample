
UCLASS(Abstract)
class ULevelsDevMenuWidget : UHazeDevMenuEntryWidget
{
	UPROPERTY(BindWidget)
	UListView LevelList;

	UPROPERTY(BindWidget)
	UListView ProgressPointList;

	UPROPERTY(BindWidget)
	UCheckBox TestMapCheckbox;

	UPROPERTY(BindWidget)
	URichTextBlock DetailsText;

	UPROPERTY(BindWidget)
	UButton ExpandDetailsButton;

	UPROPERTY(BindWidget)
	UTextBlock ExpandDetailsText;

	UPROPERTY(BindWidget)
	UHorizontalBox ExpandedDetailsBox;

	UPROPERTY(BindWidget)
	URichTextBlock PrimaryDetailsText;

	UPROPERTY(BindWidget)
	UWidget SecondaryDetailsBox;

	UPROPERTY(BindWidget)
	URichTextBlock SecondaryDetailsText;

	UPROPERTY(BindWidget)
	UBorder ExpandedBorder;

	UPROPERTY(Meta = (BindWidget))
	UComboBoxString ModeCombo;

	TArray<UDevMenuLevelEntryData> LevelEntries;
	TArray<UObject> LevelData;
	TArray<UObject> ProgressPointData;
	UObject LastFocusedProgressPoint;
	int DatabaseModificationCounter = 0;

	FString VisibleLevelGroup;
	FString CurrentEditorLevelGroup;
	bool bShowingTestMaps = false;

	bool bWaitingForFocus = false;
	EFocusCause WaitingFocusCause;

	FHazeProgressPointRef PreparedHostRef;
	FHazeProgressPointRef PreparedGuestRef;

	FHazeProgressPointRef ActiveHostRef;
	FHazeProgressPointRef ActiveGuestRef;

	bool bHasInitialSelection = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		// Set an invalid ref so we update the details text the first time
		PreparedHostRef.Name = "INVALID";

		RefreshLevels();

		VisibleLevelGroup = GetSelectedLevelGroup();
		RefreshProgressPoints();

		ExpandedDetailsBox.Visibility = ESlateVisibility::Collapsed;
		ExpandDetailsButton.OnClicked.AddUFunction(this, n"OnExpandDetailsClicked");

		if (bIsPopupMenu)
			ExpandedBorder.SetVisibility(ESlateVisibility::Collapsed);
	}

	UFUNCTION()
	private void OnExpandDetailsClicked()
	{
		if (ExpandedDetailsBox.Visibility == ESlateVisibility::Collapsed)
		{
			ExpandedDetailsBox.Visibility = ESlateVisibility::SelfHitTestInvisible;
			ExpandDetailsText.Text = FText::FromString("-");
		}
		else
		{
			ExpandedDetailsBox.Visibility = ESlateVisibility::Collapsed;
			ExpandDetailsText.Text = FText::FromString("+");
		}
	}

	UFUNCTION(BlueprintPure)
	UWidget GetLevelToFocus()
	{
		auto Selected = LevelList.GetSelectedEntryWidget();
		if (Selected != nullptr)
			return Selected;

		for (auto Widget : LevelList.DisplayedEntryWidgets)
			return Widget;

		return nullptr;
	}

	UFUNCTION(BlueprintPure)
	UWidget GetProgressPointToFocus()
	{
		if (LastFocusedProgressPoint != nullptr)
		{
			auto Widget = ProgressPointList.GetEntryWidgetForItem(LastFocusedProgressPoint);
			if (Widget != nullptr)
				return Widget;
		}

		auto Selected = ProgressPointList.GetSelectedEntryWidget();
		if (Selected != nullptr)
			return Selected;

		for (auto Widget : ProgressPointList.DisplayedEntryWidgets)
			return Widget;

		return nullptr;
	}

	bool IsDetailsExpanded()
	{
		return ExpandedDetailsBox.Visibility != ESlateVisibility::Collapsed;
	}

	FString GetSelectedLevelGroup()
	{
		auto Item = LevelList.GetSelectedItem();
		if (Item == nullptr)
			return "";
		return Cast<UDevMenuLevelEntryData>(Item).LevelGroup;
	}

	void RefreshLevels()
	{
		FString SelectedGroup = GetSelectedLevelGroup();
		bShowingTestMaps = TestMapCheckbox.IsChecked();

		// Figure out the sorting order based on the level flow
		TMap<FString, int> LevelGroupSortOrder;

		ULevelFlowSettings LevelFlow = Cast<ULevelFlowSettings>(ULevelFlowSettings.DefaultObject);
		for (auto Section : LevelFlow.Sections)
		{
			for (auto Level : Section.Levels)
			{
				FString Group = Progress::GetLevelGroup(Progress::GetShortLevelName(Level.PersistentPath));
				if (LevelGroupSortOrder.Contains(Group))
					continue;

				int Sort = LevelGroupSortOrder.Num();
				LevelGroupSortOrder.Add(Group, Sort);
			}
		}

		// Add an entry for each level group
		int SelectedIndex = -1;
		LevelEntries.Reset();
		for (FString LevelGroup : Progress::GetLevelGroupsWithProgressPoints())
		{
			if (Progress::IsLevelTestMap(LevelGroup) && !bShowingTestMaps)
				continue;

			auto Entry = UDevMenuLevelEntryData();
			Entry.LevelGroup = LevelGroup;

			if (LevelGroupSortOrder.Find(LevelGroup, Entry.SortOrder))
			{
				Entry.bInLevelFlow = true;
			}
			else
			{
				Entry.SortOrder = 1000;
				Entry.bInLevelFlow = false;
			}

			LevelEntries.Add(Entry);
		}
		LevelEntries.Sort();

		LevelData.Reset();
		for (int i = 0, Count = LevelEntries.Num(); i < Count; ++i)
		{
			if (LevelEntries[i].LevelGroup == SelectedGroup)
				SelectedIndex = i;
			LevelData.Add(LevelEntries[i]);
		}

		LevelList.SetListItems(LevelData);

		if (SelectedIndex != -1)
			LevelList.SetSelectedIndex(SelectedIndex);

		LevelList.RequestRefresh();
	}

	void RefreshProgressPoints()
	{
		ProgressPointData.Reset();

		// Add an entry for each progress point in the group
		if (VisibleLevelGroup.Len() != 0)
		{
			FString PrevLevelBP;

			int PointIndex = 1;
			for (FHazeProgressPoint ProgressPoint : Progress::GetProgressPointsInLevelGroup(VisibleLevelGroup))
			{
				if (ProgressPoint.bHidden)
					continue;

				auto Entry = UDevMenuProgressPointEntryData();
				Entry.Index = PointIndex;
				Entry.ProgressPoint = ProgressPoint;
				Entry.LevelBP = FPaths::GetBaseFilename(ProgressPoint.InLevel);
				Entry.bFirstInLevelBP = false;

				if (PrevLevelBP != Entry.LevelBP)
				{
					Entry.bFirstInLevelBP = true;
					PrevLevelBP = Entry.LevelBP;
				}

				if (!ProgressPoint.bDevOnly)
					PointIndex += 1;

				ProgressPointData.Add(Entry);
			}
		}

		ProgressPointList.SetListItems(ProgressPointData);
		ProgressPointList.RequestRefresh();
		LastFocusedProgressPoint = nullptr;
	}

	void SelectLevelGroup(FString LevelGroup)
	{
		for (int i = 0, Count = LevelData.Num(); i < Count; ++i)
		{
			auto Entry = Cast<UDevMenuLevelEntryData>(LevelData[i]);
			if (Entry.LevelGroup == LevelGroup)
			{
				LevelList.SetSelectedIndex(i);
				bHasInitialSelection = true;
				return;
			}
		}
	}

	void OnProgressPointClicked(UDevMenuProgressPointEntryData Entry)
	{
		bool bPrepareOnly = false;
		bool bReloadCleanMaps = true;
		bool bClearSaveData = true;

		switch (ModeCombo.GetSelectedIndex())
		{
			case 1:
				// Activate but not restart
				bReloadCleanMaps = false;
				bClearSaveData = false;
			break;
			case 2:
				// Prepare only
				bReloadCleanMaps = false;
				bPrepareOnly = true;
				bClearSaveData = false;
			break;
		}

		if (bIsPopupMenu)
			DevMenu::ClosePopupDevMenu(this);
		else if (bIsOverlayMenu)
			DevMenu::CloseDevMenuOverlay();

		Progress::DebugSwitchToProgressPoint(
			Progress::GetProgressPointID(Entry.ProgressPoint),
			bPrepareOnly,
			bReloadCleanMaps,
			bClearSaveData,
		);

#if EDITOR
		if (Editor::IsPlaying())
#endif
		{
			FScopeDebugPrimaryWorld ScopeWorld;
			Game::GetSingleton(UGlobalMenuSingleton).NetResetTimers();
		}
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (InKeyEvent.Key == EKeys::Gamepad_FaceButton_Left)
		{
			TestMapCheckbox.SetCheckedState(TestMapCheckbox.IsChecked() ? ECheckBoxState::Unchecked : ECheckBoxState::Checked);
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}


	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		// If we've switched which level we have open in the editor, select it
		FString EditorGroup = Progress::GetLevelGroup(Progress::GetEditorLevelName());
		if (EditorGroup != CurrentEditorLevelGroup)
		{
			bool bEditorTestMap = Progress::IsLevelTestMap(Progress::GetEditorLevelName());
			if (bEditorTestMap != bShowingTestMaps)
			{
				TestMapCheckbox.SetCheckedState(bEditorTestMap ? ECheckBoxState::Checked : ECheckBoxState::Unchecked);
				RefreshLevels();
			}

			SelectLevelGroup(EditorGroup);
			LevelList.ScrollItemIntoView(LevelList.GetSelectedItem());
			CurrentEditorLevelGroup = EditorGroup;
		}

		// If we don't have an initial level selection, select it now
		if (!bHasInitialSelection)
		{
			if (LevelList.SelectedItem != nullptr)
			{
				bHasInitialSelection = true;
			}
			else
			{
				FHazeProgressPointRef HostRef, GuestRef;
				Progress::DebugGetActiveProgressPoints(HostRef, GuestRef);

				if (HostRef.Name.Len() != 0)
				{
					SelectLevelGroup(Progress::GetLevelGroup(Progress::GetShortLevelName(HostRef.InLevel)));
					LevelList.ScrollItemIntoView(LevelList.GetSelectedItem());
				}

				if (LevelList.SelectedItem == nullptr)
				{
					// In cooked builds, make sure _something_ is always selected or it can get confusing to control
					if (!Game::IsEditorBuild() && LevelData.Num() != 0)
					{
						LevelList.SetSelectedIndex(0);
						bHasInitialSelection = true;
					}
				}
			}
		}

		// Refresh everything if we've made modifications to the progress point database
		bool bForceRefresh = false;
		if (Progress::ProgressPointDatabaseModificationCounter != DatabaseModificationCounter)
		{
			DatabaseModificationCounter = Progress::ProgressPointDatabaseModificationCounter;
			bForceRefresh = true;
		}

		// Update progress points if selected group has changed
		FString CurGroup = GetSelectedLevelGroup();
		if (VisibleLevelGroup != CurGroup || bForceRefresh)
		{
			VisibleLevelGroup = CurGroup;
			RefreshProgressPoints();
		}

		// Update whether testmaps should be displayed
		if (bShowingTestMaps != TestMapCheckbox.IsChecked() || bForceRefresh)
			RefreshLevels();

		// Update prepared and active progress points
		UpdateDetailsLine();

		if (IsDetailsExpanded())
			UpdateExpandedDetails();

		// Focus the right UI element if we want to
		if (bWaitingForFocus)
		{
			auto NewWidget = GetProgressPointToFocus();
			if (NewWidget == nullptr)
				NewWidget = GetLevelToFocus();

			if (NewWidget != nullptr)
			{
				Widget::SetAllPlayerUIFocus(NewWidget, WaitingFocusCause);
				bWaitingForFocus = false;
			}
		}
	}

	void UpdateDetailsLine(bool bForceUpdate = false)
	{
		bool bNeedUpdate = false;

		// Update prepared refs
		{
			FHazeProgressPointRef HostRef, GuestRef;
			Progress::DebugGetPreparedProgressPoints(HostRef, GuestRef);

			if (HostRef.InLevel != PreparedHostRef.InLevel || HostRef.Name != PreparedHostRef.Name)
			{
				PreparedHostRef = HostRef;
				bNeedUpdate = true;
			}

			if (GuestRef.InLevel != PreparedGuestRef.InLevel || GuestRef.Name != PreparedGuestRef.Name)
			{
				PreparedGuestRef = GuestRef;
				bNeedUpdate = true;
			}
		}

		// Update active refs
		{
			FHazeProgressPointRef HostRef, GuestRef;
			Progress::DebugGetActiveProgressPoints(HostRef, GuestRef);

			if (HostRef.InLevel != ActiveHostRef.InLevel || HostRef.Name != ActiveHostRef.Name)
			{
				ActiveHostRef = HostRef;
				bNeedUpdate = true;
			}

			if (GuestRef.InLevel != ActiveGuestRef.InLevel || GuestRef.Name != ActiveGuestRef.Name)
			{
				ActiveGuestRef = GuestRef;
				bNeedUpdate = true;
			}
		}

		if (!bNeedUpdate || bForceUpdate)
			return;

		FString Details;

		// Show prepared progress point
		if (ActiveHostRef.Name.Len() == 0)
			Details += "No progress point started...";
		else if (PreparedHostRef.Name.Len() != 0 && (PreparedHostRef.Name != ActiveHostRef.Name || PreparedHostRef.InLevel != ActiveHostRef.InLevel))
			Details += f"Prepared: {ProgressPointRefString(PreparedHostRef)}";
		else
			Details += f"Nothing prepared...";

		DetailsText.SetText(FText::FromString(Details));
	}

	void UpdateExpandedDetails()
	{
		FString PrimaryDetails;
		FString SecondaryDetails;

		if (Editor::HasPrimaryGameWorld())
		{
			FScopeDebugPrimaryWorld ScopeWorld;

			PrimaryDetails = MakeDetailsText();
		}

		if (Editor::HasSecondaryGameWorld())
		{
			FScopeDebugSecondaryWorld ScopeWorld;

			PrimaryDetails = "Host:\n\n"+PrimaryDetails;
			SecondaryDetails = "Guest:\n\n";
			SecondaryDetails += MakeDetailsText();
		}

		PrimaryDetailsText.SetText(FText::FromString(PrimaryDetails));

		if (SecondaryDetails.IsEmpty())
		{
			SecondaryDetailsBox.Visibility = ESlateVisibility::Collapsed;
		}
		else
		{
			SecondaryDetailsBox.Visibility = ESlateVisibility::HitTestInvisible;
			SecondaryDetailsText.SetText(FText::FromString(SecondaryDetails));
		}
	}

	FString MakeDetailsText()
	{
		FString Details;

		Details += "<green>Active Levels:</>\n";

		TArray<FString> ActiveLevels = Progress::GetActiveLevels();
		for (FString Level : ActiveLevels)
		{
			FString BaseName = FPaths::GetBaseFilename(Level);
			Details += f"{BaseName}\n";
		}

		Details += "\n<yellow>Prepared Levels:</>\n";

		TArray<FString> PreparedLevels = Progress::GetPreparedLevels();
		for (FString Level : PreparedLevels)
		{
			FString BaseName = FPaths::GetBaseFilename(Level);
			float Progress = Progress::GetLevelLoadProgress(Level);
			Details += f"{BaseName} ({Progress :%})\n";
		}

		return Details;
	}

	FString ProgressPointRefString(FHazeProgressPointRef Ref)
	{
		FString LevelGroup = Progress::GetLevelGroup(Progress::GetShortLevelName(PreparedHostRef.InLevel)); 
		if (LevelGroup == VisibleLevelGroup)
			return Ref.Name;
		else
			return f"{Ref.Name} ({LevelGroup})";
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		auto NewWidget = GetProgressPointToFocus();
		if (NewWidget != nullptr)
			return FEventReply::Handled().SetUserFocus(NewWidget, InFocusEvent.Cause);

		bWaitingForFocus = true;
		WaitingFocusCause = InFocusEvent.Cause;
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	void OnRemovedFromFocusPath(FFocusEvent InFocusEvent)
	{
		bWaitingForFocus = false;
	}
};

class UDevMenuLevelEntryData
{
	UPROPERTY(BlueprintReadOnly)
	FString LevelGroup;
	
	bool bInLevelFlow = false;
	int SortOrder = 0;

	int opCmp(UDevMenuLevelEntryData Other) const
	{
		if (SortOrder < Other.SortOrder)
			return -1;
		else if (SortOrder > Other.SortOrder)
			return 1;

		return LevelGroup.Compare(Other.LevelGroup);
	}
};

class UDevMenuLevelEntryWidget : UHazeUserWidget
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	UDevMenuLevelEntryData EntryData;

	UPROPERTY(Meta = (BindWidget))
	UTextBlock GroupName;

	UFUNCTION()
	void SetEntryData(UDevMenuLevelEntryData Data)
	{
		EntryData = Data;

		GroupName.SetText(FText::FromString(Data.LevelGroup));
		if (Data.bInLevelFlow)
			GroupName.SetColorAndOpacity(FLinearColor::White);
		else
			GroupName.SetColorAndOpacity(FLinearColor(0.5, 0.5, 0.5));
	}

	bool bFocused = false;
	UFUNCTION(BlueprintOverride)
	void OnAddedToFocusPath(FFocusEvent InFocusEvent)
	{
		bFocused = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemovedFromFocusPath(FFocusEvent InFocusEvent)
	{
		bFocused = false;
	}

	UFUNCTION(BlueprintPure)
	bool IsFocused() const
	{
		return bFocused;
	}
};

class UDevMenuProgressPointEntryData
{
	UPROPERTY(BlueprintReadOnly)
	FHazeProgressPoint ProgressPoint;
	UPROPERTY(BlueprintReadOnly)
	int Index = 0;
	UPROPERTY(BlueprintReadOnly)
	FString LevelBP;
	UPROPERTY(BlueprintReadOnly)
	bool bFirstInLevelBP;
};

class UDevMenuProgressPointEntryWidget : UHazeUserWidget
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	UDevMenuProgressPointEntryData EntryData;

	UPROPERTY(BindWidget)
	UTextBlock PointName;
	UPROPERTY(BindWidget)
	UTextBlock BPHeader;

	bool bPressed = false;
	bool bFocused = false;
	bool bFocusedByMouse = false;

	UFUNCTION(BlueprintPure)
	FLinearColor GetBackgroundColor()
	{
		FLinearColor Color = FLinearColor::White;
		Color.A = 0.0;

		auto DevMenu = Cast<ULevelsDevMenuWidget>(GetParentWidgetOfClass(ULevelsDevMenuWidget));
		if (DevMenu != nullptr)
		{
			if (DevMenu.ActiveHostRef.InLevel == EntryData.ProgressPoint.InLevel
				&& DevMenu.ActiveHostRef.Name == EntryData.ProgressPoint.Name)
			{
				Color = FLinearColor(0.0, 0.0, 0.4, 0.1);
			}
			else if (DevMenu.PreparedHostRef.InLevel == EntryData.ProgressPoint.InLevel
				&& DevMenu.PreparedHostRef.Name == EntryData.ProgressPoint.Name)
			{
				Color = FLinearColor(1.0, 0.3, 0.8, 0.1);
			}
		}

		if (bPressed)
			Color.A += 0.2;
		else if (IsHovered())
			Color.A += 0.03;

		FLinearColor Background = FLinearColor(0.0105, 0.0105, 0.0105);
		Color = Math::Lerp(Background, Color, Color.A);
		Color.A = 1.0;
		return Color;
	}

	UFUNCTION()
	void SetEntryData(UDevMenuProgressPointEntryData Data)
	{
		EntryData = Data;

		FString EntryName = Data.ProgressPoint.Name;

		FSlateColor Color;
		Color.ColorUseRule = ESlateColorStylingMode::UseColor_Specified;
		Color.SpecifiedColor = FLinearColor::White;

		if (Data.ProgressPoint.bDevOnly)
		{
			EntryName = f"(DEV) {EntryName}";
			Color.SpecifiedColor = FLinearColor::DPink;
		}
		else
		{
			EntryName = f"{Data.Index}. {EntryName}";
		}

		PointName.SetText(FText::FromString(EntryName));
		PointName.SetColorAndOpacity(Color);

		if (EntryData.bFirstInLevelBP)
		{
			BPHeader.SetText(FText::FromString(EntryData.LevelBP));
			BPHeader.Visibility = ESlateVisibility::HitTestInvisible;

			UVerticalBoxSlot HeaderSlot = Cast<UVerticalBoxSlot>(BPHeader.Slot);
			if (EntryData.Index != 1 && EntryData.bFirstInLevelBP)
				HeaderSlot.SetPadding(FMargin(3, 15, 3, 3));
			else
				HeaderSlot.SetPadding(FMargin(3));
		}
		else
		{
			BPHeader.Visibility = ESlateVisibility::Collapsed;
		}
	}

	UFUNCTION(BlueprintPure)
	bool IsPressed()
	{
		return bPressed;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		auto DevMenu = Cast<ULevelsDevMenuWidget>(GetParentWidgetOfClass(ULevelsDevMenuWidget));
		if (DevMenu != nullptr)
		{
			DevMenu.LastFocusedProgressPoint = EntryData;
			DevMenu.ProgressPointList.SetSelectedItem(EntryData);
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	void OnAddedToFocusPath(FFocusEvent InFocusEvent)
	{
		bFocused = true;
		bFocusedByMouse = (InFocusEvent.Cause == EFocusCause::Mouse);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemovedFromFocusPath(FFocusEvent InFocusEvent)
	{
		bFocused = false;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.EffectingButton == EKeys::LeftMouseButton)
		{
			bPressed = true;
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseLeave(FPointerEvent MouseEvent)
	{
		bPressed = false;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonUp(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.EffectingButton == EKeys::LeftMouseButton)
		{
			if (bPressed)
			{
				auto DevMenu = Cast<ULevelsDevMenuWidget>(GetParentWidgetOfClass(ULevelsDevMenuWidget));
				if (DevMenu != nullptr)
					DevMenu.OnProgressPointClicked(EntryData);
				bPressed = false;
			}
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
				bPressed = true;
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
				if (bPressed)
				{
					auto DevMenu = Cast<ULevelsDevMenuWidget>(GetParentWidgetOfClass(ULevelsDevMenuWidget));
					if (DevMenu != nullptr)
						DevMenu.OnProgressPointClicked(EntryData);
				}
				bPressed = false;
				return FEventReply::Handled();
			}
		}

		return FEventReply::Unhandled();
	}
};