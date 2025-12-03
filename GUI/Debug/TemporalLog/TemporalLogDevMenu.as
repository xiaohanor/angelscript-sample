
event void FOnWatchRemove(FString ValuePath);

UCLASS(Config = EditorPerProjectUserSettings)
class UTemporalLogDevMenuConfig
{
	UPROPERTY(Config)
	TArray<FString> Bookmarks;

	UPROPERTY(Config)
	bool bScrubAnimation = false;

	UPROPERTY(Config)
	bool bScrubCamera = false;

	UPROPERTY(Config)
	bool bActorIsVisible = true;

	UPROPERTY(Config)
	bool bPauseOnScrub = true;
	
	UPROPERTY(Config)
	bool bHighlightWatchedActors = true;

	UPROPERTY(Config)
	bool bEnableControllerShortcuts = true;

	// Not stored in config, but we do want to preserve across PIE runs
	FString StartingPath = "/";
	TArray<FString> ActiveWatches;
	bool bShowNodesWithNoData = false;

	UPROPERTY(Config)
	TMap<FString, FString> RememberedSearch;

	UPROPERTY(Config)
	TMap<FString, FString> RememberedFilters;

	UPROPERTY(Config)
	TMap<FString, FString> RememberedStatuses;

	void Save()
	{
#if EDITOR
		SaveConfig();
#endif
	}
};

class UTemporalLogDevMenu : UHazeDevMenuEntryWidget
{
	UPROPERTY(BindWidget)
	UButton NetworkSideButton;

	UPROPERTY(BindWidget)
	UButton PrevFrameButton;
	
	UPROPERTY(BindWidget)
	UButton NextFrameButton;

	UPROPERTY(BindWidget)
	UTextBlock NetworkSideText;

	UPROPERTY(BindWidget)
	UTextBlock AnimationScrubCrossMark;

	UPROPERTY(BindWidget)
	UButton AnimationScrubButton;
	
	UPROPERTY(BindWidget)
	UButton CameraScrubButton;

	UPROPERTY(BindWidget)
	UTextBlock CameraScrubCrossMark;

	UPROPERTY(BindWidget)
	UButton ActorVisibilityButton;

	UPROPERTY(BindWidget)
	UButton MenuOptionsButton;

	UPROPERTY(BindWidget)
	UTextBlock ActorVisibilityCrossMark;

	UPROPERTY(BindWidget)
	USpinBox PlayRate;

	UPROPERTY(BindWidget)
	UTextBlock FrameNumberText;

	UPROPERTY(NotEditable)
	UTemporalLogValueListWidget ValueList;

	UPROPERTY(NotEditable)
	UTemporalLogEventListWidget EventList;

	UPROPERTY(NotEditable)
	UTemporalLogExplorerWidget Explorer;

	UPROPERTY(NotEditable)
	UTemporalLogTimelineWidget Timeline;

	UPROPERTY(NotEditable)
	UComboBoxString SelectableLogs;

	UPROPERTY(NotEditable)
	UHorizontalBox CrumbBox;

	UPROPERTY(NotEditable)
	UVerticalBox WatchBox;

	UPROPERTY(NotEditable)
	FHazeTemporalLogReport ValueReport;

	UPROPERTY(NotEditable)
	FHazeTemporalLogReport ExploreReport;

	UPROPERTY()
	TSubclassOf<UTemporalLogPathCrumb> CrumbWidgetClass;

	UPROPERTY()
	TSubclassOf<UTemporalLogWatchWidget> WatchEntryWidgetClass;

	UPROPERTY()
	UHazeTemporalLog TemporalLog;

	UPROPERTY(NotEditable, Meta = (BindWidget))
	USplitter ValueSplitter;

	UPROPERTY(NotEditable)
	FString CurrentPath;

	UPROPERTY(NotEditable)
	int CurrentFrame = -1;

	UPROPERTY(NotEditable)
	int CurrentEventHistory = 50;

	UPROPERTY(NotEditable)
	bool bLockedToLatestFrame = true;

	TArray<FString> ActiveWatches;
	TArray<UTemporalLogWatchWidget> WatchWidgets;

	TArray<UWidget> PathCrumbs;
	TArray<UHazeTemporalLog> AvailableLogs;

	TArray<UTemporalLogUIPanel> UIExtensions;

	UPROPERTY()
	TSubclassOf<UTemporalLogUIPanel> UIPanelClass;

	bool bRequiresUpdate = false;
	int ReportedFrame = -1;
	FString ReportedPath;
	FString ReportedStatusPath;

	TArray<FString> PathHistory;
	TArray<FString> PathFuture;

	bool bFocused = false;
	bool bWaitingForFocus = false;
	bool bHasBrowsedToPath = false;
	EFocusCause WaitingFocusCause;

	bool bIsControllingEditorCamera = false;
    TPerPlayer<bool> IsControllingPlayerCamera;

	bool bShowingLatestLog = true;
	bool bIsPlaying = false;
	bool bIsScrubbing = false;
	int ScrubbedFrame = -1;
	float StoredPlayDelta = 0.0;
	int JumpBackFrame = -1;
	bool bPausedFromScrubbing = false;

	TArray<UClass> IgnoreScrubbables;
	TArray<TSoftObjectPtr<UHazeTemporalLogScrubbableComponent>> ActiveScrubbables;

	UTemporalLogDevMenuConfig DevMenuConfig;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		DevMenuConfig = Cast<UTemporalLogDevMenuConfig>(FindObject(GetTransientPackage(), "DevMenuConfigStorage"));
		if (DevMenuConfig == nullptr)
			DevMenuConfig = NewObject(GetTransientPackage(), UTemporalLogDevMenuConfig, n"DevMenuConfigStorage", true);

		ValueList.bClickable = true;
		EventList.bShowFrameNumbers = true;
		Explorer.DevMenuConfig = DevMenuConfig;

		SetPath(DevMenuConfig.StartingPath, bAddToHistory = false);

		Explorer.OnNavigateTemporalLog.AddUFunction(this, n"OnExplorerNavigate");
		Explorer.OnBookmarkTemporalLog.AddUFunction(this, n"OnExplorerBookmark");
		Explorer.FilterDropdown.OnSelectionChanged.AddUFunction(this, n"OnExplorerFilterChanged");
		Explorer.StatusDropdown.OnSelectionChanged.AddUFunction(this, n"OnExplorerFilterChanged");

		Timeline.OnFrameSelected.AddUFunction(this, n"OnFrameSelected");
		Timeline.OnTimelineShifted.AddUFunction(this, n"OnTimelineShifted");
		ValueList.OnValueClicked.AddUFunction(this, n"OnValueClicked");
		EventList.OnBrowseToEvent.AddUFunction(this, n"OnEventClicked");

		NetworkSideButton.OnClicked.AddUFunction(this, n"OnToggleNetworkSide");
		AnimationScrubButton.OnClicked.AddUFunction(this, n"OnAnimationScrubToggle");
		CameraScrubButton.OnClicked.AddUFunction(this, n"OnCameraScrubToggle");
		ActorVisibilityButton.OnClicked.AddUFunction(this, n"OnVisibleToggle");
		MenuOptionsButton.OnClicked.AddUFunction(this, n"OnMenuOptions");

		SelectableLogs.OnSelectionChanged.AddUFunction(this, n"OnLogSelected");
		UpdateLogSelection();
		SetScrubAnimation(DevMenuConfig.bScrubAnimation);
		SetScrubCamera(DevMenuConfig.bScrubCamera);
		SetVisible(DevMenuConfig.bActorIsVisible);
		SetPauseOnScrub(DevMenuConfig.bPauseOnScrub);

		NextFrameButton.OnClicked.AddUFunction(this, n"OnClickNextFrame");
		PrevFrameButton.OnClicked.AddUFunction(this, n"OnClickPrevFrame");

		TArray<FString> RestoreWatches = DevMenuConfig.ActiveWatches;
		for (FString PrevWatch : RestoreWatches)
			AddWatch(PrevWatch);				
	}

	UFUNCTION()
	private void OnMenuOptions()
	{
		FHazeContextMenu Menu;

		{
			FHazeContextOption Option;
			Option.Type = EHazeContextOptionType::Checkbox;
			Option.Label = "Show Event Frame Numbers";
			Option.Tooltip = "Whether to show frame numbers instead of game time for logged events.";
			Option.bChecked = EventList.bShowFrameNumbers;
			Menu.AddOption(Option, FHazeContextDelegate(this, n"OnToggleEventFrameNumbers"));
		}

		{
			FHazeContextOption Option;
			Option.Type = EHazeContextOptionType::Checkbox;
			Option.Label = "Auto-Pause when Scrubbing";
			Option.Tooltip = "Whether to automatically pause and unpause a running PIE session when scrubbing.";
			Option.bChecked = DevMenuConfig.bPauseOnScrub;
			Menu.AddOption(Option, FHazeContextDelegate(this, n"OnPauseOnScrubToggle"));
		}

		{
			FHazeContextOption Option;
			Option.Type = EHazeContextOptionType::Checkbox;
			Option.Label = "Highlight Watched Actors";
			Option.Tooltip = "Visualize the bounds of watched actor values in the world.";
			Option.bChecked = DevMenuConfig.bHighlightWatchedActors;
			Menu.AddOption(Option, FHazeContextDelegate(this, n"OnHighlightWatchedActorsToggle"));
		}

		{
			FHazeContextOption Option;
			Option.Type = EHazeContextOptionType::Checkbox;
			Option.Label = "Enable Controller Shortcuts";
			Option.Tooltip = "Whether to allow any controller buttons to control the temporal log";
			Option.bChecked = DevMenuConfig.bEnableControllerShortcuts;
			Menu.AddOption(Option, FHazeContextDelegate(this, n"OnToggleControllerShortcuts"));
		}

		{
			FHazeContextOption Option;
			Option.Type = EHazeContextOptionType::Checkbox;
			Option.Label = "Show Objects with No Data";
			Option.Tooltip = "Show entries for any object that doesn't have data for the current frame, but has still been logged at some point.";
			Option.bChecked = DevMenuConfig.bShowNodesWithNoData;
			Menu.AddOption(Option, FHazeContextDelegate(this, n"OnShowNodesWithNoDataToggle"));
		}

#if EDITOR
		Menu.AddSeparator();

		{
			UMovementDebugConfig RerunConfig = UMovementDebugConfig::Get();

			FHazeContextOption Option;
			Option.Type = EHazeContextOptionType::Checkbox;
			Option.Label = "Enable Movement Rerun";
			Option.Tooltip = "Enable data collection to re-run movement frames. Can only be toggled when PIE is not running.";
			Option.bChecked = RerunConfig.bEnableRerun;
			Option.bDisabled = Editor::IsPlaying();
			Menu.AddOption(Option, FHazeContextDelegate(this, n"OnToggleMovementRerun"));
		}

		{
			auto RerunConfig = Cast<UHazeCameraRerunSettingsPerUser>(UHazeCameraRerunSettingsPerUser.DefaultObject);

			FHazeContextOption Option;
			Option.Type = EHazeContextOptionType::Checkbox;
			Option.Label = "Enable Camera Rerun";
			Option.Tooltip = "Enable data collection to re-run camera frames. Can only be toggled when PIE is not running.";
			Option.bChecked = RerunConfig.bEnableCameraRerun;
			Option.bDisabled = Editor::IsPlaying();
			Menu.AddOption(Option, FHazeContextDelegate(this, n"OnToggleCameraRerun"));
		}

		Menu.AddSeparator();

		{
			FHazeContextOption Option;
			Option.Type = EHazeContextOptionType::Option;
			Option.Label = "Copy Events to Clipboard";
			Menu.AddOption(Option, FHazeContextDelegate(this, n"OnCopyEvents"));
		}

		{
			FHazeContextOption Option;
			Option.Type = EHazeContextOptionType::Option;
			Option.Label = "Copy All Values to Clipboard";
			Menu.AddOption(Option, FHazeContextDelegate(this, n"OnCopyValues"));
		}
#endif

		Menu.AddSeparator();

		if (TemporalLog != nullptr)
		{
			FHazeContextOption Option;
			Option.Type = EHazeContextOptionType::Option;
			Option.Label = f"Current Size: {TemporalLog.GetMemorySizeBytes() / 1024.0 / 1024.0 :.1} MiB";
			Option.Tooltip = "Displays the current size in memory of the temporal log that is being viewed.";
			Option.bDisabled = true;
			Menu.AddOption(Option, FHazeContextDelegate());
		}

		{
			FHazeContextOption Option;
			Option.Type = EHazeContextOptionType::Option;
			Option.Label = "Help";
			Option.Tooltip = "Open temporal log documentation on the wiki.";
			Menu.AddOption(Option, FHazeContextDelegate(this, n"OnShowHelp"));
		}

		Menu.ShowContextMenu();
	}

	UFUNCTION()
	private void OnToggleMovementRerun(FHazeContextOption Option)
	{
#if EDITOR
		UMovementDebugConfig RerunConfig = UMovementDebugConfig::Get();
		RerunConfig.bEnableRerun = !RerunConfig.bEnableRerun;
		RerunConfig.SaveConfig();
#endif
	}

	UFUNCTION()
	private void OnToggleCameraRerun(FHazeContextOption Option)
	{
#if EDITOR
		auto RerunConfig = Cast<UHazeCameraRerunSettingsPerUser>(UHazeCameraRerunSettingsPerUser.DefaultObject);
		RerunConfig.bEnableCameraRerun = !RerunConfig.bEnableCameraRerun;
		RerunConfig.SaveConfig();
#endif
	}

	UFUNCTION()
	private void OnCopyEvents(FHazeContextOption Option)
	{
#if EDITOR
		TArray<FString> Lines;
		for (auto Entry : EventList.Entries)
		{
			if (Entry.bShowFrameNumbers)
				Lines.Add(f"{Entry.Value.Frame} {Entry.Value.Event}");
			else
				Lines.Add(f"{Entry.Value.GameTime:.2} {Entry.Value.Event}");
		}

		FString JoinedLines = FString::Join(Lines, "\n");
		Editor::CopyToClipBoard(JoinedLines);
#endif
	}

	UFUNCTION()
	private void OnCopyValues(FHazeContextOption Option)
	{
#if EDITOR
		TArray<FString> Lines;
		for (auto Entry : ValueList.Entries)
		{
			Lines.Add(f"{Entry.DisplayName} = {Entry.Value.DataValue}");
		}

		FString JoinedLines = FString::Join(Lines, "\n");
		Editor::CopyToClipBoard(JoinedLines);
#endif
	}

	UFUNCTION()
	private void OnShowHelp(FHazeContextOption Option)
	{
		FPlatformProcess::LaunchURL("http://wiki.hazelight.se/en/Development/DevMenu/Temporal-Log");
	}

	UFUNCTION()
	private void OnToggleEventFrameNumbers(FHazeContextOption Option)
	{
		EventList.ToggleFrameNumbers();
	}

	UFUNCTION()
	private void OnClickPrevFrame()
	{
		Timeline.ScrollSelectedFrame(-1);
	}

	UFUNCTION()
	private void OnClickNextFrame()
	{
		Timeline.ScrollSelectedFrame(+1);
	}

	UFUNCTION()
	private void OnAnimationScrubToggle()
	{
		SetScrubAnimation(!DevMenuConfig.bScrubAnimation);
	}

	void SetScrubAnimation(bool bScrub)
	{
		DevMenuConfig.bScrubAnimation = bScrub;
		DevMenuConfig.Save();

		if (bScrub)
		{
			IgnoreScrubbables.Remove(UHazeMeshPoseDebugComponent);
			AnimationScrubButton.SetBackgroundColor(FLinearColor(0.5, 1.0, 0.5));
			AnimationScrubCrossMark.Visibility = ESlateVisibility::Collapsed;
		}
		else
		{
			IgnoreScrubbables.AddUnique(UHazeMeshPoseDebugComponent);
			AnimationScrubButton.SetBackgroundColor(FLinearColor(1.0, 0.5, 0.5, 0.5));
			AnimationScrubCrossMark.Visibility = ESlateVisibility::HitTestInvisible;
		}

		UpdateScrubbables();
	}

	UFUNCTION()
	private void OnCameraScrubToggle()
	{
		SetScrubCamera(!DevMenuConfig.bScrubCamera);
		UpdateScrubbables();
	}

	void SetScrubCamera(bool bScrub)
	{
		DevMenuConfig.bScrubCamera = bScrub;
		DevMenuConfig.Save();

		if (bScrub)
		{
			IgnoreScrubbables.Remove(UHazeCameraScrubbableDebugComponent);
			CameraScrubButton.SetBackgroundColor(FLinearColor(0.5, 1.0, 0.5));
			CameraScrubCrossMark.Visibility = ESlateVisibility::Collapsed;	
		}
		else
		{
			IgnoreScrubbables.AddUnique(UHazeCameraScrubbableDebugComponent);
			CameraScrubButton.SetBackgroundColor(FLinearColor(1.0, 0.5, 0.5, 0.5));
			CameraScrubCrossMark.Visibility = ESlateVisibility::HitTestInvisible;
		}
	}

	UFUNCTION()
	private void OnVisibleToggle()
	{
		SetVisible(!DevMenuConfig.bActorIsVisible);
		UpdateScrubbables();
	}

	void SetVisible(bool bVisible)
	{
		DevMenuConfig.bActorIsVisible = bVisible;
		DevMenuConfig.Save();

		if (bVisible)
		{
			IgnoreScrubbables.AddUnique(UTemporalLogScrubbableVisible);
			ActorVisibilityButton.SetBackgroundColor(FLinearColor(0.5, 1.0, 0.5));
			ActorVisibilityCrossMark.Visibility = ESlateVisibility::Collapsed;	
		}
		else
		{
			IgnoreScrubbables.Remove(UTemporalLogScrubbableVisible);
			ActorVisibilityButton.SetBackgroundColor(FLinearColor(1.0, 0.5, 0.5, 0.5));
			ActorVisibilityCrossMark.Visibility = ESlateVisibility::HitTestInvisible;
		}
	}

	UFUNCTION()
	private void OnPauseOnScrubToggle(FHazeContextOption Option)
	{
		SetPauseOnScrub(!DevMenuConfig.bPauseOnScrub);
	}

	void SetPauseOnScrub(bool bPauseOnScrub)
	{
		DevMenuConfig.bPauseOnScrub = bPauseOnScrub;
		DevMenuConfig.Save();
	}

	UFUNCTION()
	private void OnHighlightWatchedActorsToggle(FHazeContextOption Option)
	{
		DevMenuConfig.bHighlightWatchedActors = !DevMenuConfig.bHighlightWatchedActors;
		DevMenuConfig.Save();
	}

	UFUNCTION()
	private void OnToggleControllerShortcuts(FHazeContextOption Option)
	{
		DevMenuConfig.bEnableControllerShortcuts = !DevMenuConfig.bEnableControllerShortcuts;
		DevMenuConfig.Save();
	}

	UFUNCTION()
	private void OnShowNodesWithNoDataToggle(FHazeContextOption Option)
	{
		DevMenuConfig.bShowNodesWithNoData = !DevMenuConfig.bShowNodesWithNoData;
		DevMenuConfig.Save();
	}

	UFUNCTION()
	private void OnExplorerFilterChanged(FString SelectedItem, ESelectInfo SelectionType)
	{
		bRequiresUpdate = true;
	}

	void UpdateLogSelection()
	{
		const TArray<UHazeTemporalLog>& NewLogs = UHazeTemporalLog::GetAllRecordedLogs();
		if (NewLogs == AvailableLogs)
		{
			if (bShowingLatestLog)
			{
				SelectableLogs.SetSelectedIndex(0);
			}
			else
			{
				for (int i = 0, Count = AvailableLogs.Num(); i < Count; ++i)
				{
					if (AvailableLogs[i] == TemporalLog)
						SelectableLogs.SetSelectedIndex(i+1);
				}
			}
			return;
		}

		AvailableLogs = NewLogs;

		SelectableLogs.ClearOptions();
		SelectableLogs.AddOption("Latest Log");

		for (int i = 0, Count = AvailableLogs.Num(); i < Count; ++i)
		{
			UHazeTemporalLog Log = AvailableLogs[i];
			FString LogName = Log.LogName;

			LogName += " from ";
			if (Log.LogStartTime.GetDate() != FDateTime::Today())
				LogName += Log.LogStartTime.ToString("%Y-%m-%d at ");

			if (Log.bIsActive)
			{
				LogName += Log.LogStartTime.ToString("%H:%M:%S");
			}
			else
			{
				if (Log.LogStartTime.GetDate() == Log.LogEndTime.GetDate()
					&& Log.LogStartTime.Hour == Log.LogEndTime.Hour
					&& Log.LogStartTime.Minute == Log.LogEndTime.Minute)
				{
					LogName += Log.LogStartTime.ToString("%H:%M:%S");
					LogName += " to ";
					LogName += Log.LogEndTime.ToString("%H:%M:%S");
				}
				else
				{
					LogName += Log.LogStartTime.ToString("%H:%M");
					LogName += " to ";
					LogName += Log.LogEndTime.ToString("%H:%M");
				}
			}

			LogName += "  ";
			SelectableLogs.AddOption(LogName);

			if (AvailableLogs[i] == TemporalLog && !bShowingLatestLog)
				SelectableLogs.SetSelectedIndex(i+1);
		}

		if (bShowingLatestLog)
		{
			auto PreviousLog = TemporalLog;
			SelectableLogs.SetSelectedIndex(0);
			if (PreviousLog != TemporalLog)
				LockToLatestFrame(true);
		}
		else if (TemporalLog == nullptr && AvailableLogs.Num() != 0 && !bShowingLatestLog)
		{
			SelectableLogs.SetSelectedIndex(AvailableLogs.Num());
		}
	}

	void UpdateNetworkSideButton()
	{
		bool bShowButton = false;
		if (TemporalLog != nullptr && TemporalLog.PIESide != EHazeSelectPlayer::Both && TemporalLog.PIEIndex != -1)
		{
			NetworkSideButton.Visibility = ESlateVisibility::Visible;
			if (TemporalLog.PIESide == EHazeSelectPlayer::Zoe)
			{
				NetworkSideText.SetText(FText::FromString("Zoe Control"));

				FSlateColor SlateColor;
				SlateColor.ColorUseRule = ESlateColorStylingMode::UseColor_Specified;
				SlateColor.SpecifiedColor = FLinearColor(1.0, 0.2, 0.2, 1.0);
				NetworkSideText.ColorAndOpacity = SlateColor;
			}
			else
			{
				NetworkSideText.SetText(FText::FromString("Mio Control"));

				FSlateColor SlateColor;
				SlateColor.ColorUseRule = ESlateColorStylingMode::UseColor_Specified;
				SlateColor.SpecifiedColor = FLinearColor(0.2, 0.2, 1.0, 1.0);
				NetworkSideText.ColorAndOpacity = SlateColor;
			}
		}
		else
		{
			NetworkSideButton.Visibility = ESlateVisibility::Collapsed;
		}
	}

	UFUNCTION()
	private void OnToggleNetworkSide()
	{
		if (TemporalLog == nullptr)
			return;

		for (auto Log : AvailableLogs)
		{
			if (Log.PIEIndex != TemporalLog.PIEIndex)
				continue;
			if (Log.PIESide == TemporalLog.PIESide)
				continue;

			SelectTemporalLog(Log, bUpdateList = !bShowingLatestLog);
			break;
		}
	}

	UFUNCTION()
	void OnLogSelected(FString SelectedItem, ESelectInfo SelectionType)
	{
		int Index = SelectableLogs.GetSelectedIndex();
		if (Index == 0)
		{
			bShowingLatestLog = true;

			UHazeTemporalLog LatestLog;
			for (int LogIndex = AvailableLogs.Num() - 1; LogIndex >= 0; --LogIndex)
			{
				UHazeTemporalLog Log = AvailableLogs[LogIndex];
				if (LatestLog == nullptr || LatestLog.PIEIndex == Log.PIEIndex)
				{
					LatestLog = Log;
					if (TemporalLog != nullptr && TemporalLog.PIESide != EHazeSelectPlayer::Both
						&& TemporalLog.PIESide == Log.PIESide)
					{
						break;
					}

					continue;
				}
				else
				{
					break;
				}
			}

			SelectTemporalLog(LatestLog, false);
		}
		else
		{
			if (!AvailableLogs.IsValidIndex(Index-1))
				return;
			bShowingLatestLog = false;
			SelectTemporalLog(AvailableLogs[Index-1], false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Destruct()
	{
		NotifyStopScrub();
		if (bPausedFromScrubbing)
			SetWorldPaused(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnSetDevMenuIsActive(bool bIsActive)
	{
		if (!bIsActive)
		{
			NotifyStopScrub();
			if (bPausedFromScrubbing)
				SetWorldPaused(false);
		}
		else
		{
			if (bPausedFromScrubbing)
				SetWorldPaused(true);
		}
	}

	void NotifyScrub(int Frame)
	{
		if (ScrubbedFrame == Frame)
			return;

		if (TemporalLog != nullptr)
		{
			for (UHazeTemporalLogScrubbableComponent ScrubComp : TemporalLog.ScrubbableComponents)
			{
				if (IgnoreScrubbables.Contains(ScrubComp.Class))
					continue;

				ScrubComp.TriggerTemporalLogScrubbedToFrame(TemporalLog, Frame);
				ActiveScrubbables.AddUnique(ScrubComp);
			}
		}

		ScrubbedFrame = Frame;
		bIsScrubbing = true;

#if !RELEASE
		// Make materials use the game time from the frame
		FHazeTemporalLogFrameData FrameData;
		TemporalLog.ReportGlobalFrameData(ScrubbedFrame, FrameData);
		Console::SetConsoleVariableFloat("r.Test.OverrideTimeMaterialExpressions", FrameData.GameTime);
#endif

#if EDITOR
		auto ScrubSubsystem = UTemporalLogEditorScrubSubsystem::Get();
		ScrubSubsystem.ScrubToFrame(DevMenuConfig, TemporalLog, CurrentPath, ScrubbedFrame);
#endif
	}

	void NotifyStopScrub()
	{
		if (!bIsScrubbing)
			return;
		
		bIsScrubbing = false;
		ResetEditorCameraView();
        ResetPlayerCameraView(EHazePlayer::Mio);
        ResetPlayerCameraView(EHazePlayer::Zoe);

		if (TemporalLog != nullptr)
		{
			TemporalLog.bPauseLogPruning = false;

			if (ScrubbedFrame != -1)
			{
				for (auto ScrubPtr : ActiveScrubbables)
				{
					auto ScrubComp = ScrubPtr.Get();
					if (ScrubComp != nullptr)
						ScrubComp.TriggerTemporalLogStopScrubbing(TemporalLog);
				}
				ActiveScrubbables.Reset();
				ScrubbedFrame = -1;
			}
		}

#if !RELEASE
		// Reset materials to use the game world time
		Console::SetConsoleVariableFloat("r.Test.OverrideTimeMaterialExpressions", -1);
#endif

#if EDITOR
		auto ScrubSubsystem = UTemporalLogEditorScrubSubsystem::Get();
		ScrubSubsystem.StopScrubbing();
#endif
	}

	void UpdateScrubbables()
	{
		if (!bIsScrubbing)
			return;

		// Remove any scrubbables that were active before and ignored now
		for (int i = ActiveScrubbables.Num() - 1; i >= 0; --i)
		{
			UHazeTemporalLogScrubbableComponent ScrubComp = ActiveScrubbables[i].Get();
			if (ScrubComp != nullptr && IgnoreScrubbables.Contains(ScrubComp.Class))
				ScrubComp.TriggerTemporalLogStopScrubbing(TemporalLog);
		}

		// Scrub any new scrubbables
		if (TemporalLog != nullptr && ScrubbedFrame != -1)
		{
			for (UHazeTemporalLogScrubbableComponent ScrubComp : TemporalLog.ScrubbableComponents)
			{
				if (IgnoreScrubbables.Contains(ScrubComp.Class))
					continue;

				ScrubComp.TriggerTemporalLogScrubbedToFrame(TemporalLog, ScrubbedFrame);
				ActiveScrubbables.AddUnique(ScrubComp);
			}
		}

#if EDITOR
		auto ScrubSubsystem = UTemporalLogEditorScrubSubsystem::Get();
		ScrubSubsystem.ScrubToFrame(DevMenuConfig, TemporalLog, CurrentPath, ScrubbedFrame);
#endif
	}

	void SelectTemporalLog(UHazeTemporalLog NewLog, bool bUpdateList = true)
	{
		if (TemporalLog != nullptr)
			TemporalLog.bPauseLogPruning = false;

		if (ScrubbedFrame != -1)
			NotifyStopScrub();

		TemporalLog = NewLog;
		Timeline.TemporalLog = TemporalLog;

		ReportedFrame = -1;
		ScrubbedFrame = -1;

		// Clear all current watches
		Timeline.FrameTimeline = FHazeTemporalLogWatchReport();
		Timeline.StatusWatch = FHazeTemporalLogWatchReport();
		for (int i = 0, Count = ActiveWatches.Num(); i < Count; ++i)
		{
			Timeline.Watches[i] = FHazeTemporalLogWatchReport();
			Timeline.Graphs[i] = FHazeTemporalLogGraphReport();
		}

		// If the current frame doesn't exist in this log, go to a different frame
		FHazeTemporalLogFrameData FrameData;
		TemporalLog.ReportGlobalFrameData(CurrentFrame, FrameData);

		if (!FrameData.bHasData)
			CurrentFrame = -1;
		Timeline.Reset(CurrentFrame);

		if (bUpdateList)
			UpdateLogSelection();
		UpdateNetworkSideButton();
	}

	UFUNCTION()
	void OnExplorerNavigate(FString NewPath)
	{
		SetPath(NewPath);
	}

	UFUNCTION()
	private void OnExplorerBookmark(FString NewPath, bool bBookmark)
	{
		if (bBookmark)
			DevMenuConfig.Bookmarks.AddUnique(NewPath);
		else
			DevMenuConfig.Bookmarks.Remove(NewPath);

		DevMenuConfig.Save();
		UpdateExplorerView();
	}

	bool IsWorldPaused() const
	{
#if EDITOR
		return Editor::ArePIEWorldsPaused();
#else
		FScopeDebugPrimaryWorld WorldContext;
		return Game::IsPausedForAnyReason();
#endif
	}

	void SetWorldPaused(bool bPause)
	{
#if EDITOR
		Editor::SetPIEWorldsPaused(bPause);
#else
		FScopeDebugPrimaryWorld WorldContext;
		Game::SetGamePaused(this, bPause);
#endif
	}

	void ConditionalPauseFromScrubbing()
	{
		if (TemporalLog != nullptr && TemporalLog.bIsActive
			&& DevMenuConfig.bPauseOnScrub)
		{
			if (!bPausedFromScrubbing)
				SetWorldPaused(true);
			bPausedFromScrubbing = true;
		}
	}

	UFUNCTION()
	void OnFrameSelected(int Frame)
	{
		CurrentFrame = Frame;
		bLockedToLatestFrame = false;
		bIsPlaying = false;
		Timeline.SelectedFrame = CurrentFrame;
		ConditionalPauseFromScrubbing();
	}

	UFUNCTION()
	void OnTimelineShifted()
	{
		bLockedToLatestFrame = false;
		ConditionalPauseFromScrubbing();
	}

	UFUNCTION()
	void LockToLatestFrame(bool bLocked)
	{
		bLockedToLatestFrame = bLocked;
		if (bLockedToLatestFrame)
			Timeline.Reset(-1);
		else
			ConditionalPauseFromScrubbing();
	}

	UFUNCTION()
	void OnValueClicked(FString ValuePath)
	{
		if (ActiveWatches.Contains(ValuePath))
			RemoveWatch(ValuePath);
		else
			AddWatch(ValuePath);
	}

	UFUNCTION(BlueprintOverride)
	void OnAddedToFocusPath(FFocusEvent InFocusEvent)
	{
		bFocused = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemovedFromFocusPath(FFocusEvent InFocusEvent)
	{
		bFocused = false;
		bWaitingForFocus = false;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		auto NewWidget = Explorer.GetFocusEntry();
		if (NewWidget != nullptr)
			return FEventReply::Handled().SetUserFocus(NewWidget, InFocusEvent.Cause);
		
		bWaitingForFocus = true;
		WaitingFocusCause = InFocusEvent.Cause;
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	void OnFocusLost(FFocusEvent InFocusEvent)
	{
	}

	UFUNCTION()
	void OnEventClicked(int Frame)
	{
		int TargetFrame = Math::Clamp(Frame, TemporalLog.FirstLoggedFrame, TemporalLog.LastLoggedFrame);
		OnFrameSelected(TargetFrame);
		Timeline.ScrollFrameIntoView(TargetFrame);
	}

	UFUNCTION(BlueprintPure)
	bool HasHistoryBack()
	{
		return PathHistory.Num() != 0;
	}

	UFUNCTION()
	void HistoryBack()
	{
		if (PathHistory.Num() == 0)
			return;

		FString BrowsePath = PathHistory.Last();

		PathHistory.RemoveAt(PathHistory.Num() - 1);
		PathFuture.Insert(CurrentPath, 0);
		SetPath(BrowsePath, bAddToHistory = false);
	}

	UFUNCTION(BlueprintPure)
	bool HasHistoryForward()
	{
		return PathFuture.Num() != 0;
	}

	UFUNCTION()
	void HistoryForward()
	{
		if (PathFuture.Num() == 0)
			return;

		FString BrowsePath = PathFuture[0];

		PathFuture.RemoveAt(0);
		PathHistory.Add(CurrentPath);
		SetPath(BrowsePath, bAddToHistory = false);
	}

	void SetPath(FString NewPath, bool bAddToHistory = true)
	{
		if (NewPath == CurrentPath)
			return;

		if (bAddToHistory)
		{
			PathHistory.Add(CurrentPath);
			PathFuture.Empty();
		}

		CurrentPath = NewPath;
		DevMenuConfig.StartingPath = CurrentPath;
		
		bIsPlaying = false;
		bHasBrowsedToPath = true;
		JumpBackFrame = -1;
		OnPathChanged();

		TArray<FString> PathElements;
		NewPath.ParseIntoArray(PathElements, "/");
		PathElements.Insert("", 0);

		// Remove previous breadcrumbs
		for (auto Widget : PathCrumbs)
		{
			if (Widget != nullptr)
				Widget.RemoveFromParent();
		}
		PathCrumbs.Empty();

		// Create breadcrumbs for the path
		FString SubPath;
		for (int i = 0, Count = PathElements.Num(); i < Count; ++i)
		{
			if (SubPath != "/")
				SubPath += "/";
			SubPath += PathElements[i];

			auto NewCrumb = Cast<UTemporalLogPathCrumb>(Widget::CreateWidget(this, CrumbWidgetClass.Get()));

			FHazeTemporalObjectMetaData MetaData;
			if (TemporalLog != nullptr)
				MetaData = TemporalLog.GetNodeMetaData(SubPath);

			if (!MetaData.DisplayName.IsEmpty())
				NewCrumb.DisplayName = MetaData.DisplayName;
			else
				NewCrumb.DisplayName = GetTemporalLogDisplayName(PathElements[i]);

			NewCrumb.FullPath = SubPath;
			NewCrumb.bIsFirst = (i == 0);
			NewCrumb.bIsLast = (i == Count-1);
			NewCrumb.OnNavigateTemporalLog.AddUFunction(this, n"OnExplorerNavigate");
			NewCrumb.Update();

			CrumbBox.AddChild(NewCrumb);
			PathCrumbs.Add(NewCrumb);
		}

		UpdateScrubbables();
	}

	UFUNCTION(BlueprintOverride)
	void OnDebugActorChanged(AActor NewDebugActor)
	{
		#if !RELEASE
		if (NewDebugActor != nullptr)
			UTemporalLogScrubbableVisible::GetOrCreate(NewDebugActor);
		#endif

		if (TemporalLog != nullptr)
		{
			FString ActorPath;
			if (NewDebugActor != nullptr)
				ActorPath = TemporalLog.GetPathForObject(NewDebugActor);
			else if (GetDebugActorName() == n"Mio_0")
				ActorPath = "/Mio";
			else if (GetDebugActorName() == n"Zoe_0")
				ActorPath = "/Zoe";
			else if (GetDebugActorName() != NAME_None)
				ActorPath = "/" + GetDebugActorName();

			if (!ActorPath.IsEmpty() && TemporalLog.DoesNodeExist(ActorPath))
			{
				// If we can, browse to the same page within the new actor as we were on within the old actor
				if (CurrentPath.Len() >= 2)
				{
					int SlashPos = CurrentPath.Find("/", StartPosition = 1);
					if (SlashPos != -1)
					{
						FString SubPath = ActorPath + CurrentPath.Mid(SlashPos);
						if (TemporalLog.DoesNodeExist(SubPath))
							ActorPath = SubPath;
					}
				}

				if (bDevMenuActive)
				{
					// If we select an actor while the temporal dev menu is active, we always want to browse to that actor
					SetPath(ActorPath, false);
					bHasBrowsedToPath = false;
				}
				else
				{
					// If we haven't manually browsed anywhere or we are at the root, browse even if inactive
					if (!bHasBrowsedToPath || CurrentPath == "/")
					{
						SetPath(ActorPath, false);
						bHasBrowsedToPath = false;
					}
				}
			}
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnPathChanged() {}

	UFUNCTION(BlueprintEvent)
	void OnFrameChanged(FHazeTemporalLogFrameData FrameData) {}

	void DrawObjectHighlight(FString ValuePath, int FrameNumber)
	{
		UObject LoggedObject;
		if (!TemporalLog.GetObjectData(ValuePath, FrameNumber, LoggedObject))
			return;

		FString LogName;
		FTransform LogTransform;
		FBox LogBounds;
		if(TryGetBoundsFromLoggedObject(LoggedObject, LogName, LogTransform, LogBounds))
		{
			FAngelscriptGameThreadScopeWorldContext ScopeWorld(LoggedObject);

			Debug::DrawDebugBox(
				LogTransform.TransformPosition(LogBounds.Center),
				LogTransform.Scale3D * LogBounds.Extent.ComponentMax(FVector(50)),
				LogTransform.Rotator(),
				ColorDebug::Pink,
				10.0
			);

			Debug::DrawDebugString(
				LogTransform.TransformPosition(LogBounds.Center),
				LogName,
				ColorDebug::Fuchsia,
			);
		}
	}

	bool TryGetBoundsFromLoggedObject(UObject LoggedObject, FString&out OutLogName, FTransform&out OutLogTransform, FBox&out OutLogBounds) const
	{
		{
			const AActor LoggedActor = Cast<AActor>(LoggedObject);
			if (IsValid(LoggedActor))
			{
				OutLogName = LoggedActor.ActorNameOrLabel;
				OutLogBounds = LoggedActor.GetActorLocalBoundingBox(true);
				OutLogTransform = LoggedActor.ActorTransform;
				return true;
			}
		}

		const UActorComponent LoggedComponent = Cast<UActorComponent>(LoggedObject);
		if(IsValid(LoggedComponent) && IsValid(LoggedComponent.Owner))
		{
			// All components log the name the same way
			// ComponentName (ActorName)
			OutLogName = f"{LoggedComponent.Name} ({LoggedComponent.Owner.ActorNameOrLabel})";

			{
				const UPrimitiveComponent LoggedPrimitive = Cast<UPrimitiveComponent>(LoggedComponent);
				if (IsValid(LoggedPrimitive))
				{
					// Only show the bounds of colliding primitives
					OutLogBounds = LoggedPrimitive.GetLocalBoundingBoxOfChildren(true, false, true);
					OutLogTransform = LoggedPrimitive.WorldTransform;
					return true;
				}
			}

			{
				const UHazeMovablePlayerTriggerComponent LoggedTriggerComponent = Cast<UHazeMovablePlayerTriggerComponent>(LoggedComponent);
				if(IsValid(LoggedTriggerComponent))
				{
					// MovableTriggerComponent are not colliding, and not a primitive, so we just get the components own local bounds
					OutLogBounds = LoggedTriggerComponent.GetComponentLocalBoundingBox();
					OutLogTransform = LoggedTriggerComponent.WorldTransform;
					return true;
				}
			}

			// Fallback on the actor bounds and transform
			OutLogBounds = LoggedComponent.Owner.GetActorLocalBoundingBox(true);
			OutLogTransform = LoggedComponent.Owner.ActorTransform;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnEngineTick(float DeltaTime)
	{
		if (TemporalLog != nullptr)
		{
			for (int i = 0, Count = ActiveWatches.Num(); i < Count; ++i)
			{
				if (bLockedToLatestFrame)
				{
					// Draw the debug shape for this frame
					TemporalLog.DrawDebugShape(ActiveWatches[i], TemporalLog.LastLoggedFrame);

					// Draw bounding boxes around watched actors
					if (DevMenuConfig.bHighlightWatchedActors)
					{
						DrawObjectHighlight(ActiveWatches[i], TemporalLog.LastLoggedFrame);
					}
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		float StartTime = Time::PlatformTimeSeconds;

		// Update the selection box for temporal logs
		UpdateLogSelection();

		// Focus the right UI element if we want to
		if (bWaitingForFocus)
		{
			auto NewWidget = Explorer.GetFocusEntry();
			if (NewWidget != nullptr)
			{
				Widget::SetAllPlayerUIFocus(NewWidget, WaitingFocusCause);
				bWaitingForFocus = false;
			}
		}

		if (TemporalLog == nullptr)
			return;

		// Update game pause state depending on scrub
		if (TemporalLog.bIsActive)
		{
			if (bPausedFromScrubbing)
			{
				if (!IsWorldPaused())
				{
					// We resumed outside of the temporal log, so go back to the latest frame
					if (!bLockedToLatestFrame)
						LockToLatestFrame(true);
					bPausedFromScrubbing = false;
				}
				else if (bLockedToLatestFrame || !DevMenuConfig.bPauseOnScrub)
				{
					// We are no longer scrubbing, so unpause
					SetWorldPaused(false);
					bPausedFromScrubbing = false;
				}
			}
			else
			{
				if (!bLockedToLatestFrame && DevMenuConfig.bPauseOnScrub)
				{
					// We started scrubbing, pause
					SetWorldPaused(true);
					bPausedFromScrubbing = true;
				}
			}
		}
		else
		{
			if (bPausedFromScrubbing)
			{
				SetWorldPaused(false);
				bPausedFromScrubbing = false;
			}
		}

		// Update the current selected frame
		if ((CurrentFrame == -1 || bLockedToLatestFrame) && TemporalLog.HasData())
		{
			CurrentFrame = TemporalLog.LastLoggedFrame;
			Timeline.SelectedFrame = CurrentFrame;
			Timeline.bIsRangeSelected = false;
		}

		// Update 
		if (bIsPlaying)
			UpdatePlaying(InDeltaTime);

		// Update the currently displayed data
		if (CurrentFrame != ReportedFrame || ReportedPath != CurrentPath || bRequiresUpdate || Explorer.bFiltersUpdated)
		{
			FString StatusPath = CurrentPath + "/Status";

			ReportedFrame = CurrentFrame;
			ReportedPath = CurrentPath;
			bRequiresUpdate = false;

			{
				FHazeTemporalLogReport NewReport;

				FHazeTemporalLogReportParams ReportParams;
				ReportParams.ReportFrame = CurrentFrame;
				ReportParams.ReportPath = CurrentPath;
				ReportParams.EventHistoryCount = CurrentEventHistory;
				ReportParams.bIncludeNodesWithNoData = Explorer.HasSearchFilter() || DevMenuConfig.bShowNodesWithNoData;
				TemporalLog.ReportOnFrame(ReportParams, NewReport);
				ValueReport = NewReport;
			}

			if (ValueReport.ChildNodes.Num() == 0)
			{
				FString ParentPath = GetTemporalLogParentPath(CurrentPath);

				FHazeTemporalLogReport NewReport;

				FHazeTemporalLogReportParams ReportParams;
				ReportParams.ReportFrame = CurrentFrame;
				ReportParams.ReportPath = ParentPath;
				ReportParams.bIncludeNodesWithNoData = Explorer.HasSearchFilter() || DevMenuConfig.bShowNodesWithNoData;
				TemporalLog.ReportOnFrame(ReportParams, NewReport);

				ExploreReport = NewReport;

				if (!TemporalLog.DoesValueExist(StatusPath))
					StatusPath = ParentPath + "/Status";
			}
			else
			{
				ExploreReport = ValueReport;
			}
		
			ValueList.UpdateFromReport(ValueReport);
			ValueList.UpdateWatchStatus(ActiveWatches);
			EventList.UpdateFromReport(ValueReport);
			UpdateExplorerView();

			// Update data for the whole frame
			FHazeTemporalLogFrameData FrameData;
			TemporalLog.ReportGlobalFrameData(CurrentFrame, FrameData);
			OnFrameChanged(FrameData);

			FrameNumberText.SetText(FText::FromString(
				f"Frame {FrameData.GameFrameCounterModuloStart}"
			));
			FrameNumberText.SetToolTipText(
				FText::FromString(
					FrameData.DateTime.ToString(
						"%Y.%m.%d-%H.%M.%S:%s"
					)
				),
			);

			// Make sure the status path is still the same
			if (StatusPath != ReportedStatusPath)
			{
				Timeline.StatusWatch = FHazeTemporalLogWatchReport();
				ReportedStatusPath = StatusPath;
			}

			// Update step button visibility
			PrevFrameButton.IsEnabled = (CurrentFrame > TemporalLog.FirstLoggedFrame);
			NextFrameButton.IsEnabled = (CurrentFrame < TemporalLog.LastLoggedFrame);
		}

		// Update UI extenders of visible path
		UpdateUIExtenders();

		//PrintToScreen(f"{TemporalLog.GetMemorySizeBytes() / 1024.0 / 1024.0 :.4} MiB");

		// Update the global timeline with any new data that has been gathered
		if (TemporalLog.HasData() && TemporalLog.LastLoggedFrame != Timeline.FrameTimeline.EndFrame)
		{
			Timeline.DataStartFrame = TemporalLog.FirstLoggedFrame;
			TemporalLog.AppendGlobalFrameTimeline(TemporalLog.LastLoggedFrame, Timeline.FrameTimeline);
		}

		// Update the status watch in the timeline
		if (TemporalLog.HasData() && TemporalLog.LastLoggedFrame != Timeline.StatusWatch.EndFrame)
			TemporalLog.AppendWatch(ReportedStatusPath, TemporalLog.LastLoggedFrame, Timeline.StatusWatch);

        // Update all watches we are currently tracking
        FHazeTemporalLogVisualCamera VisualCamera;
        TPerPlayer<bool> HasCameraView;
        bool bHasEditorCameraView = false;
		for (int i = 0, Count = ActiveWatches.Num(); i < Count; ++i)
		{
			// Update watch bar
			FHazeTemporalLogWatchReport& WatchReport = Timeline.Watches[i];
			if (TemporalLog.HasData() && TemporalLog.LastLoggedFrame != WatchReport.EndFrame)
				TemporalLog.AppendWatch(ActiveWatches[i], TemporalLog.LastLoggedFrame, WatchReport);

			// Update graph for watch
			FHazeTemporalLogGraphReport& GraphReport = Timeline.Graphs[i];

			int StartGraphFrame = Timeline.FirstVisibleFrame;
			int EndGraphFrame = Timeline.LastVisibleFrame;
			int GraphInterval = Math::Max(1, Math::CeilToInt(float(EndGraphFrame - StartGraphFrame) / 800.0));

			if (TemporalLog.HasData())
			{
				if (StartGraphFrame != GraphReport.StartFrame
					|| EndGraphFrame != GraphReport.EndFrame
					|| GraphInterval != GraphReport.Interval)
				{
					float PrevMin = GraphReport.GraphMin;
					float PrevMax = GraphReport.GraphMax;

					TemporalLog.ReportGraph(ActiveWatches[i], StartGraphFrame, EndGraphFrame, GraphInterval, GraphReport);

					// Maintain previous minimum and maximum so the graph isn't jumpy
					if (PrevMin < GraphReport.GraphMin)
						GraphReport.GraphMin = PrevMin;
					if (PrevMax > GraphReport.GraphMax)
						GraphReport.GraphMax = PrevMax;
				}
			}

			// Draw the debug shape for the watch value if it has any
			if ((Timeline.bIsRangeSelected || Timeline.bIsSelectingRange) && !IsPlaying())
			{
				int SelectionStart = Math::Min(Timeline.RangeStartFrame, Timeline.RangeEndFrame);
				int SelectionEnd = Math::Max(Timeline.RangeStartFrame, Timeline.RangeEndFrame);

				for (int DrawFrame = SelectionStart; DrawFrame <= SelectionEnd; ++DrawFrame)
					TemporalLog.DrawDebugShape(ActiveWatches[i], DrawFrame);
			}
			else
			{
				if (!bLockedToLatestFrame)
				{
					// Draw the debug shape for this frame
					TemporalLog.DrawDebugShape(ActiveWatches[i], CurrentFrame);

					// Draw bounding boxes around watched actors
					if (DevMenuConfig.bHighlightWatchedActors)
						DrawObjectHighlight(ActiveWatches[i], CurrentFrame);
				}
			}

			// Check if this watch is a camera view
            if (TemporalLog.GetVisualCamera(ActiveWatches[i], CurrentFrame, VisualCamera))
            {
                EHazePlayer Player = EHazePlayer::Mio;
                if (ActiveWatches[i].StartsWith("/Zoe"))
                    Player = EHazePlayer::Zoe;

                ApplyPlayerCameraView(Player, VisualCamera);
                HasCameraView[Player] = true;

                ApplyEditorCameraView(VisualCamera);
                bHasEditorCameraView = true;
            }
		}

		// Apply the watched camera view if we have one
        if (!HasCameraView[EHazePlayer::Zoe])
            ResetPlayerCameraView(EHazePlayer::Zoe);
        if (!HasCameraView[EHazePlayer::Mio])
            ResetPlayerCameraView(EHazePlayer::Mio);
        if (!bHasEditorCameraView)
            ResetEditorCameraView();

		// If we are locked to the latest frame make sure we shift our timeline view
		if (bLockedToLatestFrame)
		{
			Timeline.ShiftToLatestFrame();

			if (ScrubbedFrame != -1)
				NotifyStopScrub();
		}
		else
		{
			NotifyScrub(CurrentFrame);
		}

		Timeline.LastDeltaTime = InDeltaTime;
		TemporalLog.bPauseLogPruning = !bLockedToLatestFrame;

		//PrintToScreen(f"Temporal Log update took: {(Time::PlatformTimeSeconds - StartTime) * 1000.0} ms");

#if EDITOR
		if (bIsScrubbing)
		{
			auto ScrubSubsystem = UTemporalLogEditorScrubSubsystem::Get();
			ScrubSubsystem.UpdateScrubbing();
		}
#endif
	}
	
    void ApplyPlayerCameraView(EHazePlayer Player, FHazeTemporalLogVisualCamera CameraValue)
    {
        IsControllingPlayerCamera[Player] = true;
        Debug::OverridePlayerCameraView(Player,
			FVector(CameraValue.Position),
			FRotator(CameraValue.Rotation), CameraValue.FieldOfView);
    }

    void ResetPlayerCameraView(EHazePlayer Player)
    {
        if (!IsControllingPlayerCamera[Player])
            return;

        IsControllingPlayerCamera[Player] = false;
        Debug::ClearPlayerCameraViewOverride(Player);
    }

    void ApplyEditorCameraView(FHazeTemporalLogVisualCamera CameraValue)
    {
        bIsControllingEditorCamera = true;

        Editor::SetEditorViewLocation(FVector(CameraValue.Position));
        Editor::SetEditorViewRotation(FRotator(CameraValue.Rotation));
        Editor::SetEditorViewFOV(CameraValue.FieldOfView);
    }

    void ResetEditorCameraView()
    {
        if (!bIsControllingEditorCamera)
            return;

        bIsControllingEditorCamera = false;
        Editor::SetEditorViewFOV(Editor::GetEditorViewFOV());
    }

	void UpdateExplorerView()
	{
		// Update bookmarks in explorer
		if (TemporalLog != nullptr && TemporalLog.HasData())
		{
			Explorer.Bookmarks.SetNum(DevMenuConfig.Bookmarks.Num());

			int ValidBookmarks = 0;
			for (int i = 0, Count = DevMenuConfig.Bookmarks.Num(); i < Count; ++i)
			{
				if (!TemporalLog.DoesNodeExist(DevMenuConfig.Bookmarks[i]))
					continue;

				FHazeTemporalLogReportParams ReportParams;
				ReportParams.ReportFrame = CurrentFrame;
				ReportParams.ReportPath = DevMenuConfig.Bookmarks[i];

				TemporalLog.ReportNodeInfo(ReportParams, Explorer.Bookmarks[ValidBookmarks]);
				ValidBookmarks += 1;
			}

			Explorer.Bookmarks.SetNum(ValidBookmarks);
			Explorer.UpdateFromReport(ExploreReport, CurrentPath);
		}
	}

	UFUNCTION(BlueprintPure)
	FString FormatGameTime(float GameTime)
	{
		return f"{GameTime : 4.2} s";
	}

	UFUNCTION(BlueprintPure)
	FString FormatDeltaTime(float DeltaTime)
	{
		return f"{DeltaTime : .3} s";
	}

	void UpdateUIExtenders()
	{
		int ExtenderIndex = 0;

		for (FName ExtenderClass : ValueReport.ExtenderClasses)
		{
			if (!UpdateExtender(ExtenderClass, ExtenderIndex, ValueReport))
				continue;
			ExtenderIndex += 1;
		}

		if (ExploreReport.ReportedPath != ValueReport.ReportedPath)
		{
			for (FName ExtenderClass : ExploreReport.ExtenderClasses)
			{
				if (ValueReport.ExtenderClasses.Contains(ExtenderClass))
					continue;
				if (!UpdateExtender(ExtenderClass, ExtenderIndex, ExploreReport))
					continue;
				ExtenderIndex += 1;
			}
		}

		for (int i = ExtenderIndex, Count = UIExtensions.Num(); i < Count; ++i)
			ValueSplitter.RemoveChild(UIExtensions[i]);

		UIExtensions.SetNum(ExtenderIndex);
	}

	bool UpdateExtender(FName ExtenderClass, int ExtenderIndex, FHazeTemporalLogReport& Report)
	{
		auto Extender = Cast<UClass>(FindObject(nullptr, "/Script/Angelscript."+ExtenderClass));
		if (Extender == nullptr)
		{
			devError("Cannot find Temporal UI extender class "+ExtenderClass);
			return false;
		}

		auto ExtenderObject = Cast<UTemporalLogUIExtender>(Extender.DefaultObject);
		if (ExtenderObject == nullptr)
			return false;

		ExtenderObject.TemporalLog = TemporalLog;
		const bool bShouldShow = ExtenderObject.ShouldShow(Report);
		ExtenderObject.TemporalLog = nullptr;
		
		if (!bShouldShow)
			return false;

		if (!UIExtensions.IsValidIndex(ExtenderIndex))
		{
			// Create new immediate extender
			auto NewPanel = Cast<UTemporalLogUIPanel>(
				Widget::CreateWidget(this, UIPanelClass)
			);

			auto SplitSlot = Cast<USplitterSlot>(
				ValueSplitter.AddChildAt(NewPanel, ExtenderIndex)
			);
			SplitSlot.SizeToContent = !ExtenderObject.ShouldBeResizable(Report);
			SplitSlot.Size = 1.0;

			UIExtensions.Add(NewPanel);
		}

		auto ImmediateWidget = UIExtensions[ExtenderIndex].ImmediateWidget;
		if (ImmediateWidget.Drawer.IsVisible())
		{
			ExtenderObject.TemporalLog = TemporalLog;
			ExtenderObject.TemporalDevMenu = this;
			ExtenderObject.DrawUI(ImmediateWidget.Drawer, Report);
			ExtenderObject.TemporalLog = nullptr;
			ExtenderObject.TemporalDevMenu = nullptr;
		}

		return true;
	}

	void AddWatch(FString PropertyPath)
	{
		auto WatchWidget = Cast<UTemporalLogWatchWidget>(Widget::CreateWidget(this, WatchEntryWidgetClass));
		WatchWidget.FullPath = PropertyPath;
		WatchWidget.DisplayName = GetTemporalLogDisplayName(GetTemporalLogBaseName(PropertyPath));
		WatchWidget.ObjectName = GetTemporalLogDisplayName(GetTemporalLogBaseName(GetTemporalLogParentPath(PropertyPath)));
		WatchWidget.OnWatchRemove.AddUFunction(this, n"OnWatchRemoveClicked");
		WatchWidget.OnNavigateTo.AddUFunction(this, n"OnExplorerNavigate");

		ActiveWatches.Add(PropertyPath);
		WatchWidgets.Add(WatchWidget);

		Timeline.Watches.Add(FHazeTemporalLogWatchReport());
		Timeline.Graphs.Add(FHazeTemporalLogGraphReport());

		WatchBox.AddChild(WatchWidget);
		WatchWidget.Update();

		ValueList.UpdateWatchStatus(ActiveWatches);
		DevMenuConfig.ActiveWatches = ActiveWatches;
	}

	void RemoveWatch(FString PropertyPath)
	{
		int Index = ActiveWatches.FindIndex(PropertyPath);
		if (Index == -1)
			return;

		WatchWidgets[Index].RemoveFromParent();

		ActiveWatches.RemoveAt(Index);
		Timeline.Watches.RemoveAt(Index);
		Timeline.Graphs.RemoveAt(Index);
		WatchWidgets.RemoveAt(Index);

		ValueList.UpdateWatchStatus(ActiveWatches);
		DevMenuConfig.ActiveWatches = ActiveWatches;
	}

	UFUNCTION()
	void OnWatchRemoveClicked(FString ValuePath)
	{
		RemoveWatch(ValuePath);
	}

	UFUNCTION()
	void Export()
	{
		TemporalLog.PromptExportToFile();
	}

	UFUNCTION()
	void Import()
	{
		UHazeTemporalLog ImportedLog = UHazeTemporalLog::PromptImportTemporalLog();
		if (ImportedLog != nullptr)
		{
			bShowingLatestLog = false;
			SelectTemporalLog(ImportedLog);
		}
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.EffectingButton == EKeys::ThumbMouseButton)
		{
			HistoryBack();
			return FEventReply::Handled();
		}
		else if (MouseEvent.EffectingButton == EKeys::ThumbMouseButton2)
		{
			HistoryForward();
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonUp(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.EffectingButton == EKeys::ThumbMouseButton)
		{
			return FEventReply::Handled();
		}
		else if (MouseEvent.EffectingButton == EKeys::ThumbMouseButton2)
		{
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (InKeyEvent.Key == EKeys::Gamepad_RightThumbstick
			|| InKeyEvent.Key == EKeys::G)
		{
			LockToLatestFrame(!bLockedToLatestFrame);
			return FEventReply::Handled();
		}
		else if (InKeyEvent.Key == EKeys::A
			|| InKeyEvent.Key == EKeys::Gamepad_FaceButton_Left)
		{
			Timeline.ScrollSelectedFrame(-1);
			return FEventReply::Handled();
		}
		else if (InKeyEvent.Key == EKeys::D
			|| InKeyEvent.Key == EKeys::Gamepad_FaceButton_Right)
		{
			Timeline.ScrollSelectedFrame(+1);
			return FEventReply::Handled();
		}
		else if (Timeline.bIsSelectingRange && InKeyEvent.Key == EKeys::Escape)
		{
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if ((InKeyEvent.Key == EKeys::Gamepad_RightThumbstick && DevMenuConfig.bEnableControllerShortcuts)
			|| InKeyEvent.Key == EKeys::G)
		{
			return FEventReply::Handled();
		}
		else if (InKeyEvent.Key == EKeys::A
			|| (InKeyEvent.Key == EKeys::Gamepad_FaceButton_Left && DevMenuConfig.bEnableControllerShortcuts))
		{
			return FEventReply::Handled();
		}
		else if (InKeyEvent.Key == EKeys::D
			|| (InKeyEvent.Key == EKeys::Gamepad_FaceButton_Right && DevMenuConfig.bEnableControllerShortcuts))
		{
			return FEventReply::Handled();
		}
		else if ((Timeline.bIsSelectingRange || Timeline.bIsRangeSelected) && InKeyEvent.Key == EKeys::Escape)
		{
			Timeline.bIsSelectingRange = false;
			Timeline.bIsRangeSelected = false;
			Timeline.RangeStartFrame = -1;
			Timeline.RangeEndFrame = -1;
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnAnalogValueChanged(FGeometry MyGeometry, FAnalogInputEvent InAnalogInputEvent)
	{
		if (DevMenuConfig.bEnableControllerShortcuts)
		{
			if (InAnalogInputEvent.Key == EKeys::Gamepad_RightX)
			{
				float Value = InAnalogInputEvent.GetAnalogValue();
				if (Math::Abs(Value) > 0.3)
					Timeline.AnalogMovement((Math::Abs(Value) - 0.3) / 0.7 * Math::Sign(Value));
				return FEventReply::Handled();
			}
			else if (InAnalogInputEvent.Key == EKeys::Gamepad_LeftTriggerAxis)
			{
				float Value = -InAnalogInputEvent.GetAnalogValue();
				if (Math::Abs(Value) > 0.3)
					Timeline.AnalogZoom((Math::Abs(Value) - 0.3) / 0.7 * Math::Sign(Value));
				return FEventReply::Handled();
			}
			else if (InAnalogInputEvent.Key == EKeys::Gamepad_RightTriggerAxis)
			{
				float Value = InAnalogInputEvent.GetAnalogValue();
				if (Math::Abs(Value) > 0.3)
					Timeline.AnalogZoom((Math::Abs(Value) - 0.3) / 0.7 * Math::Sign(Value));
				return FEventReply::Handled();
			}
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION()
	void TogglePlaying()
	{
		bIsPlaying = !bIsPlaying;
		bLockedToLatestFrame = false;
		StoredPlayDelta = 0.0;
		if (bIsPlaying)
			JumpBackFrame = CurrentFrame;
		ConditionalPauseFromScrubbing();
	}

	UFUNCTION(BlueprintPure)
	bool IsPlaying()
	{
		return bIsPlaying;
	}

	UFUNCTION(BlueprintPure)
	bool CanPlay()
	{
		if (TemporalLog == nullptr)
			return false;
		if (!TemporalLog.HasData())
			return false;
		if (CurrentFrame >= Timeline.FrameTimeline.EndFrame)
			return false;
		return true;
	}

	UFUNCTION(BlueprintPure)
	bool CanJumpBack()
	{
		return JumpBackFrame != -1;
	}

	UFUNCTION()
	void JumpBack()
	{
		if (JumpBackFrame != -1)
		{
			OnFrameSelected(JumpBackFrame);
			bIsPlaying = false;
		}
	}

	void UpdatePlaying(float DeltaTime)
	{
		if (!bIsPlaying)
			return;

		if (Timeline.bIsRangeSelected)
		{
			int SelectionStart = Math::Min(Timeline.RangeStartFrame, Timeline.RangeEndFrame);
			int SelectionEnd = Math::Max(Timeline.RangeStartFrame, Timeline.RangeEndFrame);

			if (CurrentFrame >= SelectionEnd)
				CurrentFrame = SelectionStart;
		}
		else if (CurrentFrame >= Timeline.FrameTimeline.EndFrame)
		{
			// Reached the end of the timeline, stop playing
			bIsPlaying = false;
			return;
		}

		StoredPlayDelta += (DeltaTime * PlayRate.GetValue());

		// Look up what the delta to the next frame is
		while (true)
		{
			if (Timeline.bIsRangeSelected)
			{
				int SelectionStart = Math::Min(Timeline.RangeStartFrame, Timeline.RangeEndFrame);
				int SelectionEnd = Math::Max(Timeline.RangeStartFrame, Timeline.RangeEndFrame);

				if (CurrentFrame >= SelectionEnd)
					CurrentFrame = SelectionStart;
			}
			else if (CurrentFrame >= Timeline.FrameTimeline.EndFrame)
			{
				// Reached the end of the timeline, stop playing
				bIsPlaying = false;
				return;
			}

			FHazeTemporalLogFrameData FrameData;
			TemporalLog.ReportGlobalFrameData(CurrentFrame+1, FrameData);

			if (!FrameData.bHasData)
			{
				// No data  for this frame, skip it
				CurrentFrame += 1;
				continue;
			}
			else if (StoredPlayDelta >= FrameData.DeltaTime)
			{
				// We've reached this frame with our delta, continue on
				CurrentFrame += 1;
				StoredPlayDelta -= FrameData.DeltaTime;
				continue;
			}
			else
			{
				// Not enough accumulated delta to go to this frame yet
				break;
			}
		}

		Timeline.SelectedFrame = CurrentFrame;
	}
};

class UTemporalLogWatchWidget : UHazeUserWidget
{
	UPROPERTY()
	FString DisplayName;

	UPROPERTY()
	FString ObjectName;

	UPROPERTY()
	FString FullPath;

	UPROPERTY()
	FOnWatchRemove OnWatchRemove;

	UPROPERTY()
	FOnNavigateTemporalLog OnNavigateTo;

	UFUNCTION(BlueprintEvent)
	void Update() {}

	UFUNCTION()
	void NavigateToWatch()
	{
		OnNavigateTo.Broadcast(GetTemporalLogParentPath(FullPath));
	}
};

class UTemporalLogPathCrumb : UHazeUserWidget
{
	UPROPERTY()
	UComboBoxString Dropdown;

	UPROPERTY()
	FString DisplayName;

	UPROPERTY()
	FString FullPath;

	UPROPERTY()
	bool bIsFirst = false;

	UPROPERTY()
	bool bIsLast = false;

	UPROPERTY()
	bool bFocused = false;

	UPROPERTY()
	FOnNavigateTemporalLog OnNavigateTemporalLog;

	default bIsFocusable = true;
	TArray<FString> OptionPaths;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		Dropdown.OnOpening.AddUFunction(this, n"AddOpenOptions");
		Dropdown.OnSelectionChanged.AddUFunction(this, n"OnOptionSelected");
	}

	UFUNCTION()
	void AddOpenOptions()
	{
		Dropdown.ClearOptions();
		OptionPaths.Empty();

		auto DevMenu = Cast<UTemporalLogDevMenu>(GetParentWidgetOfClass(UTemporalLogDevMenu));
		if (DevMenu == nullptr)
			return;
		if (DevMenu.TemporalLog == nullptr)
			return;

		FHazeTemporalLogReportParams Params;
		Params.ReportFrame = DevMenu.CurrentFrame;
		Params.ReportPath = GetTemporalLogParentPath(FullPath);

		FHazeTemporalLogReport Report;
		DevMenu.TemporalLog.ReportOnFrame(Params, Report);

		for (auto Child : Report.ChildNodes)
		{
			Dropdown.AddOption(GetTemporalLogDisplayName(Child.DisplayName));
			OptionPaths.Add(Child.Path);
		}
	}

	UFUNCTION()
	void OnOptionSelected(FString SelectedItem, ESelectInfo SelectionType)
	{
		int Selected = Dropdown.SelectedIndex;
		FString SelectedPath;

		if (OptionPaths.IsValidIndex(Selected))
			SelectedPath = OptionPaths[Selected];

		Dropdown.ClearOptions();

		if (SelectedPath.Len() == 0)
			return;

		auto DevMenu = Cast<UTemporalLogDevMenu>(GetParentWidgetOfClass(UTemporalLogDevMenu));
		if (DevMenu == nullptr)
			return;

		FString NewPath = DevMenu.CurrentPath;
		NewPath.RemoveFromStart(FullPath);
		NewPath = SelectedPath + NewPath;

		// Go up the tree until we find something that exists
		while (NewPath != "/" && !DevMenu.TemporalLog.DoesNodeExist(NewPath))
			NewPath = GetTemporalLogParentPath(NewPath);

		DevMenu.OnExplorerNavigate(NewPath);
	}

	UFUNCTION(BlueprintEvent)
	void Update() {}

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

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (bFocused)
		{
			if (InKeyEvent.Key == EKeys::Virtual_Accept)
				return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (bFocused)
		{
			if (InKeyEvent.Key == EKeys::Virtual_Accept)
			{
				OnNavigateTemporalLog.Broadcast(FullPath);
				return FEventReply::Handled();
			}
		}

		return FEventReply::Unhandled();
	}
};

class UTemporalLogUIPanel : UHazeUserWidget
{
	UPROPERTY(Meta = (BindWidget))
	UHazeImmediateWidget ImmediateWidget;
};

void BrowseTemporalLog(const UTemporalLogUIExtender Extender, FString NewPath)
{
	auto DevMenu = Cast<UTemporalLogDevMenu>(Extender.TemporalDevMenu);
	if (DevMenu == nullptr)
		return;

	DevMenu.OnExplorerNavigate(NewPath);
}