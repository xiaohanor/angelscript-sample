class UAudioDebugSoundDefs: UAudioDebugTypeHandler
{
	EHazeAudioDebugType Type() override { return EHazeAudioDebugType::SoundDefs; }

	default bUseViewportDrawer = false;

	bool bSkipDeactivated = false;

	FString GetTitle() override
	{
		return "SoundDefs";
	}
	
	uint LastViewFilterTime = 0;
	uint LastWorldFilterTime = 0;
	TArray<UHazeSoundDefBase> ViewFilteredObjects;
	TArray<UHazeSoundDefBase> WorldFilteredObjects;

	bool bShowDeactivatedByController = false;

	void Menu(UHazeAudioDevMenu DevMenu, UAudioDebugManager DebugManager,
			  const FHazeImmediateScrollBoxHandle& Section) override
	{
		auto& MenuDebugConfig = DevMenu.MenuDebugConfig;

		bool bShowDisabledSoundDefsCheckBoxEnabled = Section
			.CheckBox()
			.Checked(MenuDebugConfig.MiscFlags.bShowDisabledSoundDefs)
			.Label("Show Disabled SoundDefs")
			.Tooltip("If to show SDs that are disabled!");

		if (MenuDebugConfig.MiscFlags.bShowDisabledSoundDefs != bShowDisabledSoundDefsCheckBoxEnabled)
		{
			MenuDebugConfig.MiscFlags.bShowDisabledSoundDefs = bShowDisabledSoundDefsCheckBoxEnabled;
			MenuDebugConfig.Save();
		}
	}

	int MaxRenderedCount = 20;

	const TArray<UHazeSoundDefBase>& GetViewSoundDefs(UAudioDebugManager DebugManager, int& TotalFiltered)
	{
		if (LastViewFilterTime == Time::FrameNumber)
			return ViewFilteredObjects;

		LastViewFilterTime = Time::FrameNumber;
		
		if (DebugManager.IsFilterEmpty(false, EDebugAudioFilter::SoundDefs))
		{
			ViewFilteredObjects = DebugManager.GetRegisteredSoundDefs();
			TotalFiltered = ViewFilteredObjects.Num();
			ViewFilteredObjects.SetNum(MaxRenderedCount);
		}
		else
		{
			ViewFilteredObjects.Reset();
			for (auto SoundDef : DebugManager.GetRegisteredSoundDefs())
			{
				if (DebugManager.IsFiltered(SoundDef.Name.ToString(), false, EDebugAudioFilter::SoundDefs))
					continue;

				if (!DebugManager.MiscFlags.bShowDisabledSoundDefs && SoundDef.GetActivationState() == ESoundDefActivationState::Deactive)
					continue;

				ViewFilteredObjects.Add(SoundDef);
			}

			TotalFiltered = ViewFilteredObjects.Num();
			ViewFilteredObjects.SetNum(MaxRenderedCount);
		}

		return ViewFilteredObjects;
	}

	const TArray<UHazeSoundDefBase>& GetWorldSoundDefs(UAudioDebugManager DebugManager, int& TotalFiltered)
	{
		if (LastWorldFilterTime == Time::FrameNumber)
			return WorldFilteredObjects;

		LastWorldFilterTime = Time::FrameNumber;
		
		if (DebugManager.IsFilterEmpty(true, EDebugAudioFilter::SoundDefs))
		{
			WorldFilteredObjects = DebugManager.GetRegisteredSoundDefs();
			TotalFiltered = WorldFilteredObjects.Num();
			WorldFilteredObjects.SetNum(MaxRenderedCount);
		}
		else
		{
			WorldFilteredObjects.Reset();
			for (auto SoundDef : DebugManager.GetRegisteredSoundDefs())
			{
				if (DebugManager.IsFiltered(SoundDef.Name.ToString(), true, EDebugAudioFilter::SoundDefs))
						continue;

				WorldFilteredObjects.Add(SoundDef);
			}
			TotalFiltered = WorldFilteredObjects.Num();
		}

		return WorldFilteredObjects;
	}

	void Draw(UAudioDebugManager DebugManager, const FHazeImmediateSectionHandle& Section) override
	{
		Super::Draw(DebugManager, Section);

				Section.Text("Editing; ")
				.Bold()
				.Color(FLinearColor::Yellow);
				// .Scale(1.25);

		auto OpenedSoundDefs = UHazeAudioDebugManager::GetEditorOpenedSoundDefs();
		{
			FScopeDebugPrimaryWorld ScopeWorld;

			for (auto SoundDefClass : OpenedSoundDefs)
			{
				auto SoundDefClassBox = Section.HorizontalBox()
					.SlotPadding(5, 0, 5, 0);

				SoundDefClassBox
					.Text("Solo")
					.Tooltip("Solo all emitters handled by sounddef");

				auto bSoloChecked = UHazeAudioDebugManager::IsSoloed(SoundDefClass);
				bool bChecked = SoundDefClassBox.CheckBox().Checked(bSoloChecked);
				if (bChecked != bSoloChecked)
				{
					UHazeAudioDebugManager::Solo(SoundDefClass, bChecked);
				}

				auto bMutedChecked = UHazeAudioDebugManager::IsMuted(SoundDefClass);
				SoundDefClassBox
					.Text("Mute")
					.Tooltip("Mute all emitters handled by sounddef");

				bChecked = SoundDefClassBox.CheckBox().Checked(bMutedChecked);
				if (bChecked != bMutedChecked)
				{
					UHazeAudioDebugManager::Mute(SoundDefClass, bChecked);
				}

				SoundDefClassBox.Text(SoundDefClass.Name.ToString());
			}
		}

		if (DebugManager == nullptr)
			return;
		
		auto QueuedSDs = DebugManager.GetQueuedSoundDefs();

		if (QueuedSDs.Num() > 0)
		{
			Section.Text("Queued; ")
				.Bold()
				.Color(FLinearColor::Yellow);
				// .Scale(1.25);

			for (const auto& SoundDefData: QueuedSDs)
			{
				auto SoundDefClassBox = Section.HorizontalBox()
					.SlotPadding(5, 0, 5, 0);

				FString OwnerName = "";
				if (SoundDefData.SoundDefParams.HazeOwner != nullptr)
				{
					OwnerName = SoundDefData.SoundDefParams.HazeOwner.GetActorNameOrLabel();
				}

				FString SoundDefName = SoundDefData.SoundDefParams.SoundDef.Get().Name.ToString();

				SoundDefClassBox
					.Text(f"{SoundDefName} - {OwnerName}")
					.Color(FLinearColor::Yellow);
			}
		}

		int FilteredCount = 0;
		const auto& SoundDefs = GetViewSoundDefs(DebugManager, FilteredCount);

		auto LaneSection = Section
			.Section(f"SoundDefs ({DebugManager.GetNumSoundDefs()}), Filtered({FilteredCount}) Displaying({SoundDefs.Num()}) - Limit search to see more")
			.Color(FLinearColor::Transparent);

		for	(auto SoundDef : SoundDefs)
		{
			DrawSoundDef(DebugManager, Section, SoundDef);
		}

		if (Section.Button("Toggle Disabled By Controller"))
			bShowDeactivatedByController = !bShowDeactivatedByController;

		if (!bShowDeactivatedByController)
			return;

		auto DisabledBox = Section.Section("Disabled by controller:", true);
		// Reset before next drawing
		bSkipDeactivated = false;
		
		for (auto SoundDef : DebugManager.GetSoundDefsDeactivatedByController())
		{
			DrawSoundDef(DebugManager, DisabledBox, SoundDef, true);
		}
	}

	bool DrawSoundDef(UAudioDebugManager DebugManager, const FHazeImmediateSectionHandle& Section, UHazeSoundDefBase SoundDef, bool bOnlyShowName = false)
	{
		if (SoundDef == nullptr)
			return false;

		if (bSkipDeactivated && SoundDef.ActivationState == ESoundDefActivationState::Deactive)
			return false;

		FString ActorNameOrOneShot = SoundDef.HazeOwner != nullptr ? SoundDef.HazeOwner.Name.ToString() : "Oneshot";
		FString SoundDefName = f"{SoundDef.Name.ToString()} - {ActorNameOrOneShot}";

		auto& CheckBoxesAndName = Section.HorizontalBox()
			.SlotPadding(5,0,5,0);

		// We now keep everything on one line
		if (!bOnlyShowName)
		{
			bool bIsAnyFlagSet = UHazeAudioDebugManager::IsDebugging(SoundDef) || UHazeAudioDebugManager::IsClassOpenedInEditor(SoundDef.Class);
			CheckBoxesAndName.Text("Debug");
			bool bTriggerDebug = CheckBoxesAndName
					.CheckBox()
					.Checked(bIsAnyFlagSet)
					.Tooltip("If the sounddef is being edited the debugging can't be turned off!");

			if (bTriggerDebug != bIsAnyFlagSet || (!UHazeAudioDebugManager::IsDebugging(SoundDef) && UHazeAudioDebugManager::IsClassOpenedInEditor(SoundDef.Class)))
			{
				DebugManager.SetDebugFlag(SoundDef, 0, bTriggerDebug);
			}

			auto& SoundDefSoloMuteBox = CheckBoxesAndName;

			CheckBoxesAndName
				.Text("Solo")
				.Tooltip("Solo all emitters handled by sounddef");

			auto bSoloChecked = UHazeAudioDebugManager::IsSoloed(SoundDef);
			bool bChecked = SoundDefSoloMuteBox.CheckBox().Checked(bSoloChecked);
			if (bChecked != bSoloChecked)
			{
				UHazeAudioDebugManager::Solo(SoundDef, bChecked);
			}

			auto bMutedChecked = UHazeAudioDebugManager::IsMuted(SoundDef);
			CheckBoxesAndName
				.Text("Mute")
				.Tooltip("Mute all emitters handled by sounddef");

			bChecked = SoundDefSoloMuteBox.CheckBox().Checked(bMutedChecked);
			if (bChecked != bMutedChecked)
			{
				UHazeAudioDebugManager::Mute(SoundDef, bChecked);
			}

		}

		CheckBoxesAndName
			.Text(SoundDefName)
			.Color(SoundDef.ActivationState == ESoundDefActivationState::Active ? FLinearColor::Green : FLinearColor::Red);

		if (CheckBoxesAndName.Button("Teleport") && SoundDef.AudioComponents.Num() > 0)
		{
			FAngelscriptGameThreadScopeWorldContext WorldScope(SoundDef);

			for (auto Player: Game::GetPlayers())
			{
				Player.TeleportActor(SoundDef.AudioComponents[0].WorldLocation, Player.ActorRotation, SoundDef);
			}
		}

		if (CheckBoxesAndName.Button("🔍"))
		{
			auto AssetPath = SoundDef.Class.GetPathName();
			// So it doesn't open the blueprintclass instead of SD.
			AssetPath.RemoveFromEnd("_C");
			Editor::OpenEditorForAsset(AssetPath);
		}

		return true;
	}

	void Visualize(UAudioDebugManager DebugManager) override
	{
		if (AudioDebug::IsEnabled(EDebugAudioWorldVisualization::AudioComponents))
			return;

		auto Players = Game::Players;

		int FilteredCount = 0;
		for (auto SoundDef: GetWorldSoundDefs(DebugManager, FilteredCount))
		{
			if (SoundDef == nullptr)
				continue;

			if (!DebugManager.MiscFlags.bShowDisabledSoundDefs && SoundDef.GetActivationState() == ESoundDefActivationState::Deactive)
					continue;

			for	(auto Component : SoundDef.AudioComponents)
			{
				if (AudioDebug::FilterAudioComponent(Players, Component))
					continue;

				AudioDebug::VisualizeAudioComponent(DebugManager, Component);
			}
		}
	}
	
	bool InViewOrRange(const TArray<AHazePlayerCharacter>& Players, AActor Actor)
	{
		if (Actor == nullptr)
			return true;

		for (auto Player: Players)
		{
			if (!SceneView::ViewFrustumPointRadiusIntersection(Player, Actor.ActorLocation, 50, 15000))
				continue;

			return true;
		}

		return false;
	}
}