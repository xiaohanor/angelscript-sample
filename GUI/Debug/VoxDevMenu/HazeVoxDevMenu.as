

#if EDITOR
struct FHazeVoxDevValidationResult
{
	TWeakObjectPtr<AActor> TriggerActor;
	FVoxValidationHelpers::FValidationResult ValidationResult;
}
#endif

class UHazeVoxDevMenu : UHazeDevMenuEntryWidget
{
	UPROPERTY(Meta = (BindWidget))
	UHazeImmediateWidget Content;

	UPROPERTY(Meta = (BindWidget))
	UVoxDevTimelineWidget VoxTimeline;

#if TEST
	const FName FakeTab_Default = n"Default";
	const FName FakeTab_TriggerValidation = n"Trigger Validation";

	TArray<FName> FakeTabs;
	default FakeTabs.Add(FakeTab_Default);
	default FakeTabs.Add(FakeTab_TriggerValidation);
	int SelectedFakeTab = 0;

	#if EDITOR
	bool bValidateOnTick = true;
	TArray<FHazeVoxDevValidationResult> ValidationResults;
	bool bFindDisabledOnTrick = true;
	TArray<TWeakObjectPtr<AActor>> DisabledTriggers;
	#endif

	TArray<FHazeDebugEffectEvent> DebugEvents;

	bool bLockedToLatestFrame = true;
	int CurrentFrame = -1;

	UHazeVoxDebugConfig DebugConfig;

	bool bHasEditorWorld = false;
#endif

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
#if TEST
		DebugConfig = Cast<UHazeVoxDebugConfig>(UHazeVoxDebugConfig.DefaultObject);

		VoxTimeline.OnFrameSelected.AddUFunction(this, n"OnFrameSelected");
		VoxTimeline.OnTimelineShifted.AddUFunction(this, n"OnTimelineShifted");
#endif
	}

	UFUNCTION()
	void OnFrameSelected(int Frame)
	{
#if TEST
		CurrentFrame = Frame;
		bLockedToLatestFrame = false;
		VoxTimeline.SelectedFrame = CurrentFrame;
#endif
	}

	UFUNCTION()
	void OnTimelineShifted()
	{
#if TEST
		bLockedToLatestFrame = false;
#endif
	}

	UFUNCTION()
	void LockToLatestFrame(bool bLocked)
	{
#if TEST
		bLockedToLatestFrame = bLocked;
		if (bLockedToLatestFrame)
			VoxTimeline.Reset(-1);
#endif
	}

#if TEST
	private void ResetTimelineSlots()
	{
		// Reset
		bLockedToLatestFrame = true;
		VoxTimeline.Reset(-1);

		auto VoxRunner = UHazeVoxRunner::Get();
		VoxTimeline.TimelineStartFrame = int(VoxRunner.DebugStartFrame);
		VoxTimeline.DataStartFrame = int(VoxRunner.DebugStartFrame);
		VoxTimeline.TimelineEndFrame = -1;

		VoxTimeline.Lanes.Reset();
	}

	private void DrawVoxAsset(FVoxDebugRuntimeAsset RuntimeDebug, FHazeImmediateSectionHandle& Section)
	{
		auto AssetBox = Section.HorizontalBox();
		AssetBox.Text(RuntimeDebug.Name);
		AssetBox.Text(RuntimeDebug.State).Color(RuntimeDebug.Color);

		for (const FVoxDebugVoiceLine& VL : RuntimeDebug.VoiceLines)
		{
			auto VLBox = Section.HorizontalBox();
			VLBox.SlotPadding(100, 0, 0, 0).Text(f"{VL.Index:<2}:{VL.AssetName:>40}");
			VLBox.SlotPadding(0).Text(VL.State).Color(VL.Color);
		}
	}

	private void DrawDebugCheckboxes(FHazeImmediateSectionHandle Section)
	{
		Section.Text("Debug Config:");
		{
			const bool bIsChecked = DebugConfig.bTrackPlayingEvents;
			const bool bCheckboxChecked = Section.CheckBox().Checked(bIsChecked).Label("Track Playing Events");
			if (bIsChecked != bCheckboxChecked)
			{
				DebugConfig.bTrackPlayingEvents = bCheckboxChecked;
				DebugConfig.SaveConfig();
			}
		}

		{
			const bool bIsChecked = DebugConfig.bShowTriggerVisualizers;
			const bool bCheckboxChecked = Section.CheckBox().Checked(bIsChecked).Label("Show Trigger Visualizers");
			if (bIsChecked != bCheckboxChecked)
			{
				DebugConfig.bShowTriggerVisualizers = bCheckboxChecked;
				DebugConfig.SaveConfig();
			}
		}

		{
			const bool bIsChecked = DebugConfig.bRotateTriggerVisualizers;
			const bool bCheckboxChecked = Section.CheckBox().Checked(bIsChecked).Label("Rotate Trigger Visualizers");
			if (bIsChecked != bCheckboxChecked)
			{
				DebugConfig.bRotateTriggerVisualizers = bCheckboxChecked;
				DebugConfig.SaveConfig();
			}
		}

		{
			const bool bIsChecked = DebugConfig.bShowPlayerDistances;
			const bool bCheckboxChecked = Section.CheckBox().Checked(bIsChecked).Label("Show Distance Between Players");
			if (bIsChecked != bCheckboxChecked)
			{
				DebugConfig.bShowPlayerDistances = bCheckboxChecked;
				DebugConfig.SaveConfig();
			}
		}

		Section.Text("Debug Console Commands:");
		{

			bool bIsChecked = VoxCVar::HazeVoxDisablePlayOnce.GetInt() != 0;
			bool bCheckboxChecked = Section.CheckBox()
										.Checked(bIsChecked)
										.Label("Disable Play Once")
										.Tooltip("Console Command: HazeVox.DisablePlayOnce");
			if (bIsChecked != bCheckboxChecked)
			{
				Console::SetConsoleVariableInt("HazeVox.DisablePlayOnce", bCheckboxChecked ? 1 : 0, bOverrideValueSetByConsole = true);
			}
		}

		{
			bool bIsChecked = VoxCVar::HazeVoxDisableCooldown.GetInt() != 0;
			bool bCheckboxChecked = Section.CheckBox()
										.Checked(bIsChecked)
										.Label("Disable Cooldowns")
										.Tooltip("Console Command: HazeVox.DisableCooldown");
			if (bIsChecked != bCheckboxChecked)
			{
				Console::SetConsoleVariableInt("HazeVox.DisableCooldown", bCheckboxChecked ? 1 : 0, bOverrideValueSetByConsole = true);
			}
		}

		{
			bool bIsChecked = VoxCVar::HazeVoxAutoResetTriggers.GetInt() != 0;
			bool bCheckboxChecked = Section.CheckBox()
										.Checked(bIsChecked)
										.Label("Auto Reset Vox Triggers")
										.Tooltip("NOTE: This can effect gameplay also using the triggers\nConsole Command: HazeVox.AutoResetTriggers");
			if (bIsChecked != bCheckboxChecked)
			{
				Console::SetConsoleVariableInt("HazeVox.AutoResetTriggers", bCheckboxChecked ? 1 : 0, bOverrideValueSetByConsole = true);
			}
		}

		{
			bool bIsChecked = VoxCVar::HazeVoxShowViewportTimeline.GetInt() != 0;
			bool bCheckboxChecked = Section.CheckBox()
										.Checked(bIsChecked)
										.Label("Show Viewport Timeline Overlay")
										.Tooltip("Console Command: HazeVox.ShowViewportTimeline");
			if (bIsChecked != bCheckboxChecked)
			{
				Console::SetConsoleVariableInt("HazeVox.ShowViewportTimeline", bCheckboxChecked ? 1 : 0, bOverrideValueSetByConsole = true);
			}
		}

	#if EDITOR
		{
			bool bIsChecked = Console::GetConsoleVariableInt("HazeVox.LoadFaceAnims") != 0;
			bool bCheckboxChecked = Section.CheckBox()
										.Checked(bIsChecked)
										.Label("Load Face Animations in Editor")
										.Tooltip("Console Command: HazeVox.LoadFaceAnims");
			if (bIsChecked != bCheckboxChecked)
			{
				Console::SetConsoleVariableInt("HazeVox.LoadFaceAnims", bCheckboxChecked ? 1 : 0, bOverrideValueSetByConsole = true);
			}
		}
	#endif
	}

	private void PlayerDistanceRow(FHazeImmediateSectionHandle Section, FString Label, FString Value)
	{
		auto HBox = Section.HorizontalBox();
		const bool bCopy = HBox.Button("📋").Tooltip("Copy to Clipboard").Padding(0, 0).WasClicked();
		if (bCopy)
		{
			Editor::CopyToClipBoard(Value);
		}
		HBox.SlotFill().Text(f"{Label} {Value}");
	}

	private void ValidateVoxTriggersInWorld()
	{
	#if EDITOR
		FScopeDebugEditorWorld EditorWorld;

		TArray<AVoxAdvancedPlayerTrigger> AdvancedTriggers;
		AdvancedTriggers.Append(Editor::GetAllEditorWorldActorsOfClass(AVoxAdvancedPlayerTrigger));

		ValidationResults.Reset(AdvancedTriggers.Num());
		for (auto Trigger : AdvancedTriggers)
		{
			FVoxValidationHelpers::FValidationResult ValidationResult;
			bool bOk = FVoxValidationHelpers::ValidateTrigger(Trigger, ValidationResult);
			if (!bOk)
			{
				Log(n"VoxValidate", f"Failed to validate {Trigger.ActorNameOrLabel}");
				continue;
			}

			FHazeVoxDevValidationResult NewResult;
			NewResult.TriggerActor = Trigger;
			NewResult.ValidationResult = ValidationResult;

			ValidationResults.Add(NewResult);
		}
	#endif
	}

	private void FindDisabledVoxTriggersInWorld()
	{
	#if EDITOR
		FScopeDebugEditorWorld EditorWorld;

		DisabledTriggers.Reset();

		TArray<AVoxPlayerTrigger> PlayerTriggers;
		PlayerTriggers.Append(Editor::GetAllEditorWorldActorsOfClass(AVoxPlayerTrigger));
		for (auto Trigger : PlayerTriggers)
		{
			if (Trigger.bTriggerForMio == false && Trigger.bTriggerForZoe == false)
			{
				DisabledTriggers.Add(Trigger);
			}
		}

		TArray<AVoxAdvancedPlayerTrigger> AdvancedTriggers;
		AdvancedTriggers.Append(Editor::GetAllEditorWorldActorsOfClass(AVoxAdvancedPlayerTrigger));
		for (auto Trigger : AdvancedTriggers)
		{
			if (Trigger.bTriggerForMio == false && Trigger.bTriggerForZoe == false)
			{
				DisabledTriggers.Add(Trigger);
			}
		}

		TArray<AVoxDuoPlayerTrigger> DuoTriggers;
		DuoTriggers.Append(Editor::GetAllEditorWorldActorsOfClass(AVoxDuoPlayerTrigger));
		for (auto Trigger : DuoTriggers)
		{
			if (Trigger.bTriggerForMio == false && Trigger.bTriggerForZoe == false)
			{
				DisabledTriggers.Add(Trigger);
			}
		}

		TArray<AVoxPlayerLookAtTrigger> LookAtTriggers;
		LookAtTriggers.Append(Editor::GetAllEditorWorldActorsOfClass(AVoxPlayerLookAtTrigger));
		for (auto Trigger : LookAtTriggers)
		{
			if (Trigger.LookAtTrigger.Players == EHazeSelectPlayer::None)
			{
				DisabledTriggers.Add(Trigger);
			}
		}
	#endif
	}

	private void DrawTriggerValidation(FHazeImmediateSectionHandle Section, float WindowHeight)
	{
	#if EDITOR
		// Do nothing if playing
		if (Editor::HasPrimaryGameWorld())
		{
			return;
		}

		auto OuterBox = Section.HorizontalBox();
		auto LeftBox = OuterBox.SlotFill().VerticalBox();
		auto RightBox = OuterBox.SlotFill().VerticalBox();

		const FLinearColor ErrorColor = FLinearColor::MakeFromHex(0xff8a4300);
		const FLinearColor InfoColor = FLinearColor::MakeFromHex(0xff005885);

		auto ToolbarBox = LeftBox.HorizontalBox();
		bValidateOnTick = ToolbarBox.CheckBox().Checked(bValidateOnTick).Label("Validate On Tick");
		if (bValidateOnTick)
		{
			ValidateVoxTriggersInWorld();
		}

		bFindDisabledOnTrick = ToolbarBox.CheckBox().Checked(bFindDisabledOnTrick).Label("Find Disabled On Tick");
		if (bFindDisabledOnTrick)
		{
			FindDisabledVoxTriggersInWorld();
		}

		auto OuterResultsBox = LeftBox.VerticalBox().SlotFill();

		if (ValidationResults.Num() > 0)
		{
			bool bAnyErrors = false;
			for (auto Result : ValidationResults)
			{
				const auto ValidationResult = Result.ValidationResult;
				const bool bHasErrors = ValidationResult.Infos.Num() > 0 || ValidationResult.Errors.Num() > 0;
				if (bHasErrors)
				{
					bAnyErrors = true;
					auto ResultBorder = OuterResultsBox.BorderBox().BackgroundColor(FLinearColor::Black);
					auto ResultBox = ResultBorder.VerticalBox();
					auto ResultTitle = ResultBox.HorizontalBox();
					const bool bSelect = ResultTitle.Button("Select");
					ResultTitle.SlotVAlign(EVerticalAlignment::VAlign_Center).Text(ValidationResult.TriggerName);

					if (bSelect)
					{
						if (Result.TriggerActor.IsValid())
						{
							Editor::SelectActor(Result.TriggerActor);
						}
					}

					for (auto InfoMsg : ValidationResult.Infos)
					{
						ResultBox.BorderBox().BackgroundColor(InfoColor).Text(InfoMsg);
					}
					for (auto ErrorMsg : ValidationResult.Errors)
					{
						ResultBox.BorderBox().BackgroundColor(ErrorColor).Text(ErrorMsg);
					}
				}
			}
			if (!bAnyErrors)
			{
				OuterResultsBox.Text("No Validation Issues");
			}
		}

		RightBox.Text("Disabled Triggers:").Scale(2.0f).Bold();

		if (DisabledTriggers.Num() > 0)
		{
			// Hax to ensure the scrollbox works
			const float SlotHeight = WindowHeight - 100.0;

			auto TriggersBox = RightBox.SlotMaxHeight(SlotHeight).SlotFill().ScrollBox().VerticalBox();
			for (auto Trigger : DisabledTriggers)
			{
				auto TriggerBorder = TriggersBox.BorderBox().BackgroundColor(FLinearColor::Black);
				auto TriggerBox = TriggerBorder.HorizontalBox();
				const bool bSelect = TriggerBox.Button("Select");
				if (Trigger.IsValid())
				{
					TriggerBox.SlotVAlign(EVerticalAlignment::VAlign_Center).Text(Trigger.Get().ActorNameOrLabel);
				}

				if (bSelect)
				{
					Editor::SelectActor(Trigger);
				}
			}
		}
		else
		{
			RightBox.Text("No Disabled Triggers Found");
		}
	#endif
	}

#endif

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
#if TEST
		if (!Content.Drawer.IsVisible())
			return;

		// Draw global stuff
		auto RootSection = Content.Drawer.Begin();
		auto TopToolbar = RootSection.HorizontalBox();

		auto FakeTabDropdown = TopToolbar.ComboBox().Items(FakeTabs).Value(FakeTabs[SelectedFakeTab]);
		if (FakeTabDropdown.SelectedIndex != SelectedFakeTab)
		{
			SelectedFakeTab = FakeTabDropdown.SelectedIndex;
			if (FakeTabs[SelectedFakeTab] == FakeTab_Default)
			{
				VoxTimeline.SetVisibility(ESlateVisibility::Visible);
			}
			else if (FakeTabs[SelectedFakeTab] == FakeTab_TriggerValidation)
			{
				VoxTimeline.SetVisibility(ESlateVisibility::Collapsed);
			}
		}

		// Draw trigger validation and return instead of doing default
		if (FakeTabs[SelectedFakeTab] == FakeTab_TriggerValidation)
		{
			DrawTriggerValidation(RootSection, MyGeometry.LocalSize.Y);
			return;
		}

		auto RootBox = RootSection.HorizontalBox();
		auto ConfigSection = RootBox.SlotFill().Section();

		DrawDebugCheckboxes(ConfigSection);

		// Early out if not playing
		if (!Editor::HasPrimaryGameWorld())
		{
			bHasEditorWorld = false;
			// Update timeline here if we don't have any changes
			VoxTimeline.UpdateTimeline(InDeltaTime);
			return;
		}

		// ----------------------------------------------------------------------
		// ------------ Things below this are only runs while playing -------------
		// ----------------------------------------------------------------------

		FScopeDebugPrimaryWorld ScopeWorld;

		if (!bHasEditorWorld)
		{
			// Reset timeline when there is a new world
			bHasEditorWorld = true;
			ResetTimelineSlots();
		}

		CurrentFrame = int(GFrameNumber);

		// Update tracking if it was changed while playing
		auto VoxRunner = UHazeVoxRunner::Get();
		if (DebugConfig.bTrackPlayingEvents != VoxRunner.bTrackPlayingEvents)
		{
			VoxRunner.bTrackPlayingEvents = DebugConfig.bTrackPlayingEvents;
		}

		VoxTimeline.TimelineEndFrame = CurrentFrame;

		if (bLockedToLatestFrame)
		{
			VoxTimeline.SelectedFrame = CurrentFrame;
			VoxTimeline.ShiftToLatestFrame();
		}

		VoxTimeline.Lanes = VoxRunner.DebugTimelineLanes;

		// Update timeline
		VoxTimeline.UpdateTimeline(InDeltaTime);

		// Draw runtime stuff
		auto RuntimeSection = RootBox.SlotFill().SlotVAlign(EVerticalAlignment::VAlign_Bottom).Section();

		if (DebugConfig.bShowPlayerDistances)
		{
			const FVector MioLocation = Game::Mio.ActorLocation;
			const FVector ZoeLocation = Game::Zoe.ActorLocation;

			float PlayerDistanceFlattened = MioLocation.Dist2D(ZoeLocation, FVector::UpVector);
			const float PlayerDistance = Game::DistanceBetweenPlayers;

			PlayerDistanceRow(RuntimeSection, "Mio Location", MioLocation.ToString());
			PlayerDistanceRow(RuntimeSection, "Zoe Location", ZoeLocation.ToString());

			PlayerDistanceRow(RuntimeSection, "Player Distance XY", f"{PlayerDistanceFlattened:0.3}");
			PlayerDistanceRow(RuntimeSection, "Player Distance", f"{PlayerDistance:0.3}");

			RuntimeSection.Spacer(10);
		}

		auto VoxController = UHazeVoxController::Get();
		RuntimeSection.Text(f"VoxManager State: {VoxController.IsManagerActive()}");

		bool bLockToFrame = RuntimeSection.Button("LockToLatestFrame");
		if (bLockToFrame)
		{
			LockToLatestFrame(!bLockedToLatestFrame);
		}

		// Reminder to turn on data for timelien
		if (DebugConfig.bTrackPlayingEvents == false && VoxRunner.DebugTimelineLanes.Num() == 0)
		{
			RootSection.Text("No timeline events available. Turn on 'Track Playing Events' to see the timeline").Color(FLinearColor::Yellow);
		}
#endif
	}
};