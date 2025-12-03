class UAudioDebugCutscenes: UAudioDebugTypeHandler
{
	EHazeAudioDebugType Type() override { return EHazeAudioDebugType::Cutscenes; }

	FString GetTitle() override
	{
		return "Cutscene";
	}

	TArray<int> BanksWithSelectedState;
	EBankLoadState PreviousState = EBankLoadState(-1);
	TMap<FString, int> BanksMediaSizes;
	float TotalMediaSizeShown = 0;

	TArray<AActor> LevelSequenceActors;

	void Menu(UHazeAudioDevMenu DevMenu, UAudioDebugManager DebugManager, const FHazeImmediateScrollBoxHandle& Section) override
	{
		auto MenuConfig = DevMenu.MenuDebugConfig;

		auto BankStateBox = Section.HorizontalBox();
		BankStateBox.Text("Cutscene with tag:");

		auto CutsceneTagComboBox = BankStateBox
			.ComboBox()
			.Tooltip("Which cutscenes with selected tag to see")
			.Items(DevMenu.CutsceneTagSelections)
			.Value(DevMenu.CutsceneTagSelections[MenuConfig.MiscFlags.CutsceneTagSelected]);

		if (CutsceneTagComboBox.GetSelectedIndex() != int(MenuConfig.MiscFlags.CutsceneTagSelected))
		{
			MenuConfig.MiscFlags.CutsceneTagSelected = EHazeLevelSequenceTag(CutsceneTagComboBox.GetSelectedIndex());
			MenuConfig.Save();
		}
	}

	void Draw(UAudioDebugManager DebugManager, const FHazeImmediateSectionHandle& Section) override
	{
		auto MenuConfig = DebugManager.MenuDebugConfig;

		FString TagBeingShown = "Showing all sequences";
		if (MenuConfig.MiscFlags.CutsceneTagSelected != EHazeLevelSequenceTag::Undefined)
		{
			TagBeingShown = "" + MenuConfig.MiscFlags.CutsceneTagSelected;
		}

		Section
			.Text(f"CUTSCENES - {TagBeingShown}")
			.Color(FLinearColor::Yellow)
			.Bold()
			.Scale(2.0);

		DebugManager.GetSequenceActors(LevelSequenceActors);

		auto AllSequencesVerticalBox = Section.VerticalBox();

		for	(auto Actor: LevelSequenceActors)
		{
			FString ActorName = Actor.ActorNameOrLabel;

			if (DebugManager.IsFiltered(ActorName, false, EDebugAudioFilter::Cutscenes))
				continue;

			auto LevelSequenceActor = Cast<AHazeLevelSequenceActor>(Actor);
			auto Sequence = LevelSequenceActor.Sequence;

			if (Sequence == nullptr)
				continue;
			
			EHazeLevelSequenceTag LevelTag = EHazeLevelSequenceTag::Undefined;
#if EDITOR
			LevelTag = LevelSequenceActor.LevelSequenceAsset.Tag;
			if (MenuConfig.MiscFlags.CutsceneTagSelected != EHazeLevelSequenceTag::Undefined
				&& MenuConfig.MiscFlags.CutsceneTagSelected != LevelTag)
			{
				continue;
			}
#endif
			if (!LevelSequenceActor.GetSequencePlayer().IsPlaying())
				continue;
			
			auto VerticalBox = AllSequencesVerticalBox.VerticalBox();

			VerticalBox.Text(f"{Sequence.Name.ToString()} - {LevelTag}").Color(FLinearColor::Green);

			VerticalBox
				.SlotPadding(25,0)
				.Text(f"Playtime: {LevelSequenceActor.DurationAsSeconds - LevelSequenceActor.TimeRemaining}");

			VerticalBox
				.SlotPadding(25,0)
				.Text(f"Duration: {LevelSequenceActor.DurationAsSeconds}");

			const auto& SequenceActors = DebugManager.GetSequenceControlledActors(LevelSequenceActor);

			auto GlobalEmitter = DebugManager.GetGlobalEmitter(Actor);
			if (GlobalEmitter != nullptr && GlobalEmitter.IsPlaying())
			{
				auto HorizontalBox = VerticalBox.VerticalBox();
				HorizontalBox
					.SlotPadding(25,0)
					.Text(f"Global Actor");

				DrawEmitter(GlobalEmitter, "Global Emitter", HorizontalBox, Sequence.Name.ToString());
			}

			auto GlobalMusicEmitter = UHazeAudioMusicManager::Get().Emitter;
			if (GlobalMusicEmitter != nullptr && GlobalMusicEmitter.IsPlaying())
			{
				auto HorizontalBox = VerticalBox.VerticalBox();
				HorizontalBox
					.SlotPadding(25,0)
					.Text(f"Global Actor");

				DrawEmitter(GlobalMusicEmitter, "Music", HorizontalBox, Sequence.Name.ToString());
			}

			for (auto SequenceActor: SequenceActors)
			{
				if (SequenceActor == nullptr)
					continue;

				auto AudioComponent = UHazeAudioComponent::Get(SequenceActor);

				if (AudioComponent == nullptr)
					continue;

				auto HorizontalBox = VerticalBox.VerticalBox();
				HorizontalBox
					.SlotPadding(25,0)
					.Text(f"{SequenceActor.Name}");

				for (const auto& EmitterPair: AudioComponent.EmitterPairs)
				{
					DrawEmitter(EmitterPair.Emitter, EmitterPair.Name.ToString(), HorizontalBox);
				}
			}
		}
	}

	void DrawEmitter(UHazeAudioEmitter Emitter, const FString& EmitterName, const FHazeImmediateVerticalBoxHandle& HorizontalBox, FString SequenceName = "")
	{
		if (Emitter.IsPlaying() == false)
			return;

		bool bPostedEmitterName = false;

		for (const auto& EventInstance : Emitter.ActiveEventInstances())
		{
			const auto EventName = EventInstance.EventName();
			
			if (EventName.Contains("_SEQ_", ESearchCase::CaseSensitive) == false)
				continue;

			// if (SequenceName.IsEmpty() == false && EventName.Contains(SequenceName) == false)
			// 	continue;

			int TimeInMs = 0;
			float32 PlayRate = 0;
			Audio::GetSourcePlayPosition(EventInstance.PlayingID, TimeInMs, PlayRate, true);
			float TimeInSeconds = TimeInMs / 1000.;

			if (bPostedEmitterName == false)
			{
				bPostedEmitterName = true;

				HorizontalBox
					.SlotPadding(50,0)
					.Text(f"{EmitterName}");
			}

			HorizontalBox
				.SlotPadding(75,0)
				.Text(f"{EventInstance.EventName()} - {TimeInSeconds}");
		}
	}
}