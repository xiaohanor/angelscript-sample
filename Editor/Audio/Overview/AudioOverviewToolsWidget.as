

struct FHazeAudioImportVOSelectionData
{
	bool bShowFiles = false;
};

class UAudioOverviewToolsWidget : UHazeAudioOverviewToolsWidget
{
	UPROPERTY(Meta = (BindWidget))
	UHazeImmediateWidget Content;

	private bool bShowOnlyThoseWithUpdates = true;
	private bool bShowOnlyThoseWithOriginals = false;
	private FString SearchFilter = "";
	private TArray<FString> SearchWords;
	private FHazeAudioVOImportEventsData EventsData;
	private TSet<FString> SelectedImports;
	private TSet<FString> SelectedOriginals;
	private TSet<FString> SelectedDeletes;
	private TSet<FString> SelectedUnmarked;
	private TArray<FName> ExternalAudioTypes;
	default ExternalAudioTypes.SetNum(EHazeAudioExternalAudioType::EHazeAudioExternalAudioType_MAX);

	private int32 SelectedExternalAudioType = int(EHazeAudioExternalAudioType::RenderedAudio);

	private TArray<FHazeAudioVOImportData> OriginalsOnlyData;
	private TSet<int32> OriginalsIsTTS;
	bool bRefreshData = false;

	private TArray<FHazeAudioVOImportData> ImportData;
	private TMap<FString, FHazeAudioImportVOSelectionData> SelectionDatas;

	private FLinearColor DeleteColor = FLinearColor(0.89, 0.27, 0.00, 0.57);
	private FLinearColor UpdateColor = FLinearColor(0.01, 0.77, 0.22, 0.57);
	private FLinearColor ErrorColor = FLinearColor(0.84, 0.01, 0.01);

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		for (int i=0; i < int(EHazeAudioExternalAudioType::EHazeAudioExternalAudioType_MAX); ++i)
		{
			ExternalAudioTypes[i] = FName(f"{EHazeAudioExternalAudioType(i) :n}");
		}
	}

	void TickWidget(FGeometry MyGeometry, float InDeltaTime)
	{
		if (Content == nullptr)
			return;

		if (!Content.Drawer.IsVisible())
			return;

		bool bIsPlaying = Editor::IsPlaying();
		bool bIsConnected = AudioUtility::IsWaapiConnected();

		auto ContentSection = Content.Drawer.Begin("Tools");

		ContentSection.Text("Tools & Other editor functionality will be called here.");
		
		auto GenerateBanksBox = ContentSection.VerticalBox();
		{
			if (GenerateBanksBox.Button("Generate Banks") 
				&& IsCallValid("Generate Banks", bIsPlaying, bIsConnected))
			{
				UHazeAudioAssetUtility::GenerateBanks();
			}

			GenerateBanksBox.Splitter();

			GenerateBanksBox.Text("TTS").Bold().Scale(2).Color(FLinearColor::Blue);

			if (GenerateBanksBox.Button("ImportTTS & Generate")
				.BackgroundColor(FLinearColor(0.00, 0.48, 1.00))
				&& IsCallValid("ImportTTS & Generate", bIsPlaying, bIsConnected))
			{
				UHazeAudioAssetUtility::ImportTTSAndGenerateBanks();
			}

			// So we can't get a infinite cycle of popups.
			if (bIsPlaying || !bIsConnected)
			{
				bRefreshData = false;
			}

			GenerateBanksBox.Splitter();
			GenerateBanksBox.Text("IMPORT VO").Bold().Scale(2).Color(FLinearColor(1,0.3,0));

			if ((GenerateBanksBox.Button("Refresh VO Import Data")
				.BackgroundColor(FLinearColor(1,0.3,0)) || bRefreshData)
				&& IsCallValid("Refresh VO Import Data", bIsPlaying, bIsConnected))
			{
				bRefreshData = false;
				
				UHazeAudioAssetUtility::StartGatheringWavsImportData();
				SelectedImports.Reset();
				SelectedDeletes.Reset();
				SelectedUnmarked.Reset();

				UHazeAudioAssetUtility::TryGetVOImportData(EventsData);

				OriginalsOnlyData.Reset();

				// Select data only existing in originals/wwise.
				// Should maybe filter this in c++ instead? When finalized.
				for (const auto& NameAndData : EventsData.ImportData)
				{
					auto& Data = NameAndData.Value;

					if (Data.SourcePairs.Num() == 0)
					{
						auto VOEvent = Cast<UHazeAudioVOEvent>(Data.Event);
						if (VOEvent != nullptr && !VOEvent.bMarkedForDelete)
						{
							// Ignore haze ones, for example if source has mismatching names.
							if (Data.Event.Media.Num() > 0)
								continue;

							OriginalsOnlyData.Add(Data);
						}
						continue;
					}

					auto& LastSource = Data.SourcePairs.Last();
					bool bAnyOriginals = LastSource.Source.IsEmpty();

					if (Data.SourcePairs.Num() > 1 )
						continue;

					if (bAnyOriginals == false)
						continue;

					if (bAnyOriginals && Data.FilesToDelete.Contains(LastSource.Originals))
						continue;

					if (LastSource.Originals.Contains("/VoiceLines/"))
						continue;
					
					if (LastSource.Originals.Contains("_TTS_"))
					{
						if (Data.Event != nullptr)
							OriginalsIsTTS.Add(Data.Event.ShortID);
					}

					OriginalsOnlyData.Add(Data);
				}
			}
		}

		if (EventsData.ImportData.Num() > 0)
		{
			auto ImportSection = ContentSection.Section("VO Import");

			auto TopBarSection = ImportSection.HorizontalBox();
			auto SearchBox = TopBarSection
				.SearchBox()
				.Tooltip("Filter out which items to show, spaces indicate multiple search words")
				.Value(SearchFilter);

			SearchFilter = SearchBox;

			SearchWords.Reset();
			SearchFilter.ParseIntoArray(SearchWords, " ");

			if (TopBarSection.Button("Import/Update Selection").BackgroundColor(UpdateColor))
			{
				ImportData.Reset(); 
				TArray<FString> EventsToDelete;

				for (auto NameAndData : EventsData.ImportData)
				{
					auto& Data = NameAndData.Value;

					if (SelectedImports.Contains(Data.GroupName) == false)
						continue;

					if (Data.bSourcesHasMultipleCategories)
						continue;

					ImportData.Add(Data);
				}

				for (auto Selected: SelectedDeletes)
				{
					UHazeAudioEvent AudioEvent;
					if (EventsData.EventsToDelete.Find(Selected, AudioEvent) == false)
						continue;

					EventsToDelete.Add(Selected);
				}

				UHazeAudioAssetUtility::StartWavsImport(ImportData, EventsToDelete);

				SelectedDeletes.Reset();
				SelectedImports.Reset();

				bRefreshData = true;
			}

			auto ShowUpdatesOnlyCheckBox = TopBarSection
					.CheckBox()
					.Checked(bShowOnlyThoseWithUpdates)
					.Label("Updates Only")
					.Tooltip("Shows only those with Update, Delete or Error");

			bShowOnlyThoseWithUpdates = ShowUpdatesOnlyCheckBox;

			auto ImportScrollbar = ContentSection.VerticalBox()
				.SlotMaxHeight(MyGeometry.LocalSize.Y * 0.75 - 150)
				.SlotPadding(20, 10)
				.ScrollBox();

			auto ScrollbarImportSection = ImportScrollbar.Section();

			DrawImports(ScrollbarImportSection);
			DrawOriginalsOnly(ScrollbarImportSection);
			DrawDeletions(ScrollbarImportSection);
			DrawUnmarkedEvents(ScrollbarImportSection);
		}

		Content.Drawer.End();
	}

	void DrawImports(const FHazeImmediateSectionHandle& SectionHandle)
	{	
		SectionHandle.Text("IMPORTS ONLY").Bold().Scale(2).Color(FLinearColor::Gray);

		auto TopColumns = SectionHandle.HorizontalBox();
		{
			TopColumns.Text("Import /").Bold().Color(FLinearColor::Gray);
			TopColumns.SlotPadding(3, 3);
			TopColumns.Text("Name /").Bold().Color(FLinearColor::Gray);
			TopColumns.SlotPadding(3, 3);
			TopColumns.Text("Status |").Bold().Color(FLinearColor::Gray);
			TopColumns.SlotPadding(3, 3);
			TopColumns.Text("Update").Bold().Color(UpdateColor);
			TopColumns.SlotPadding(3, 3);
			TopColumns.Text("Delete").Bold().Color(DeleteColor);
			TopColumns.SlotPadding(3, 3);
			TopColumns.Text("Error").Bold().Color(ErrorColor).Tooltip("Can't be imported");
		}

		if (SectionHandle.Button("Copy Selection To 📋"))
		{
			FString SelectionText ="";
			for (const auto& Selection: SelectedImports)
			{
				SelectionText += f"{Selection}, \n";
			}
			Editor::CopyToClipBoard(SelectionText);
		}

		if (SectionHandle.Button("Toggle selection for filtered"))
		{
			for (const auto& NameAndData : EventsData.ImportData)
			{
				auto& Data = NameAndData.Value;

				if (Contains(SearchWords, Data.GroupName) == false)
					continue;
				
				if (!Data.bValidatedForImport)
					continue;

				if (SelectedImports.Remove(Data.GroupName) == false)
				{
					SelectedImports.Add(Data.GroupName);
				}
			}
		}

		auto VerticalBox = SectionHandle
			.VerticalBox()
			.SlotMaxHeight(250)
			.SlotPadding(20, 10)
			.ScrollBox();

		for (const auto& NameAndData : EventsData.ImportData)
		{
			auto& Data = NameAndData.Value;

			if (Contains(SearchWords, Data.GroupName) == false)
				continue;

			auto AudioEvent = Cast<UHazeAudioVOEvent>(Data.Event);
			
			if (!Data.bValidatedForImport)
				continue;
			
			if (bShowOnlyThoseWithUpdates && 
				Data.bRequiresUpdate == false
				)
				continue;

			auto& SelectionData = SelectionDatas.FindOrAdd(Data.GroupName);

			auto HorizontalBox = VerticalBox
				.HorizontalBox();

			auto EventColor = FLinearColor::White;
			FString StatusTooltip = "";

			if(Data.bSourcesHasMultipleCategories)
			{
				EventColor = ErrorColor;
				StatusTooltip = "Duplicate Sources, See files for the path information";
			}
			else if (Data.bRequiresUpdate)
			{
				EventColor = UpdateColor;

				if (Data.SourcePairs.Num() == Data.FilesToDelete.Num())
					EventColor = DeleteColor;
			}
			else if (AudioEvent != nullptr && AudioEvent.bMarkedForDelete)
			{
				EventColor = DeleteColor;
			}

			bool bChecked = SelectedImports.Contains(Data.GroupName);
			auto CheckBox = HorizontalBox
				.CheckBox()
				.Checked(bChecked)
				.Tooltip(StatusTooltip);

			HorizontalBox
				.Text(Data.GroupName)
				.Color(EventColor)
				.Tooltip(StatusTooltip);

			if (HorizontalBox.Button("📋"))
			{
				Editor::CopyToClipBoard(Data.GroupName);
			}

			if (CheckBox != bChecked)
			{
				if (bChecked)
					SelectedImports.Remove(Data.GroupName);
				else
					SelectedImports.Add(Data.GroupName);
			}

			if (!bChecked)
				continue;

			auto DataSection = HorizontalBox
				.CheckBox()
				.Label("Show Files")
				.Checked(SelectionData.bShowFiles);

			SelectionData.bShowFiles = DataSection;

			if (DataSection)
			{
				for (const auto& File: Data.SourcePairs)
				{
					if (bShowOnlyThoseWithUpdates && !File.bRequiresUpdate)
						continue;

					auto FileColor = !bShowOnlyThoseWithUpdates && File.bRequiresUpdate ? FLinearColor(0.01, 0.77, 0.22, 0.57) : FLinearColor::White;

					VerticalBox
						.SlotPadding(10, 0)
						.Text(f"Originals: {File.Originals}")
						.Color(FLinearColor::Gray);

					VerticalBox
						.SlotPadding(10, 0)
						.Text(f"Source: {File.Source}")
						.Color(FileColor);
				}

				for (const auto& File: Data.FilesToDelete)
				{
					VerticalBox
						.SlotPadding(10, 0)
						.Text(f"Delete: {File}")
						.Color(DeleteColor);
				}
			}
		}
	}

	void DrawOriginalsOnly(const FHazeImmediateSectionHandle& SectionHandle)
	{	
		SectionHandle.Text("EXISTS ONLY IN WWISE")
			.Bold()
			.Scale(2)
			.Color(FLinearColor::Gray);

		SectionHandle
			.Text("All of these has no source in Wavs folder OR no source AT ALL. \n Be careful not to delete valid TTS")
			.Color(FLinearColor::Gray);

		auto TopColumns = SectionHandle.HorizontalBox();
		{
			TopColumns.Text("DELETE (!) /").Bold().Color(FLinearColor::Gray);
			TopColumns.SlotPadding(3, 3);
			TopColumns.Text("Name /").Bold().Color(FLinearColor::Gray);
			TopColumns.SlotPadding(3, 3);
			TopColumns.Text("TTS /").Bold().Color(FLinearColor::Yellow);
			TopColumns.SlotPadding(3, 3);
			TopColumns.Text("Has NO Source files").Bold().Color(FLinearColor::Red);
		}

		if (SectionHandle.Button("Copy Selection To 📋"))
		{
			FString SelectionText ="";
			for (const auto& Selection: SelectedOriginals)
			{
				SelectionText += f"{Selection}, \n";
			}
			Editor::CopyToClipBoard(SelectionText);
		}

		if (SectionHandle.Button("Toggle selection for filtered"))
		{
			for (const auto& Data : OriginalsOnlyData)
			{
				if (Contains(SearchWords, Data.GroupName) == false)
					continue;

				if (SelectedOriginals.Remove(Data.GroupName) == false)
				{
					SelectedOriginals.Add(Data.GroupName);
				}
			}
		}

		if (SectionHandle
			.Button("Mark Selection for DELETE")
			.Tooltip("If you have selections they will be marked as delete, and a refresh of data will be done!"))
		{
			if (SelectedOriginals.Num() > 0)
			{
				bRefreshData = true;

				for (auto& Data : OriginalsOnlyData)
				{
					auto AudioEvent = Cast<UHazeAudioVOEvent>(Data.Event);
					if (AudioEvent == nullptr)
						continue;

					if (!SelectedOriginals.Contains(Data.GroupName))
						continue;
						
					AudioEvent.Modify();
					AudioEvent.bMarkedForDelete = true;
				}
			}
		}

		auto VerticalBox = SectionHandle
			.VerticalBox()
			.SlotMaxHeight(250)
			.SlotPadding(20, 10)
			.ScrollBox();

		for (const auto& Data : OriginalsOnlyData)
		{
			if (Contains(SearchWords, Data.GroupName) == false)
				continue;

			auto AudioEvent = Cast<UHazeAudioVOEvent>(Data.Event);

			auto& SelectionData = SelectionDatas.FindOrAdd(Data.GroupName);
			auto HorizontalBox = VerticalBox
				.HorizontalBox();

			auto EventColor = FLinearColor::White;
			FString StatusTooltip = "";

			if(Data.bSourcesHasMultipleCategories)
			{
				EventColor = ErrorColor;
				StatusTooltip = "Duplicate Sources, See files for the path information";
			}
			else if (AudioEvent != nullptr && OriginalsIsTTS.Contains(AudioEvent.ShortID))
				EventColor = FLinearColor::Yellow;
			else if (Data.SourcePairs.Num() == 0)
			{
				if (AudioEvent == nullptr)
				{
					StatusTooltip = "Must be deleted manually in Wwise!";
				}
				EventColor = FLinearColor::Red;
			}

			bool bChecked = SelectedOriginals.Contains(Data.GroupName);
			auto CheckBox = HorizontalBox
				.CheckBox()
				.Checked(bChecked)
				.Tooltip(StatusTooltip);

			HorizontalBox
				.Text(Data.GroupName)
				.Color(EventColor)
				.Tooltip(StatusTooltip);

			if (HorizontalBox.Button("📋"))
			{
				Editor::CopyToClipBoard(Data.GroupName);
			}

			if (CheckBox != bChecked)
			{
				if (bChecked)
					SelectedOriginals.Remove(Data.GroupName);
				else
					SelectedOriginals.Add(Data.GroupName);
			}

			if (!bChecked)
				continue;

			auto DataSection = HorizontalBox
				.CheckBox()
				.Label("Show Files")
				.Checked(SelectionData.bShowFiles);

			SelectionData.bShowFiles = DataSection;

			if (DataSection)
			{
				for (const auto& File: Data.SourcePairs)
				{
					VerticalBox
						.SlotPadding(10, 0)
						.Text(f"Originals: {File.Originals}")
						.Color(FLinearColor::Gray);

					VerticalBox
						.SlotPadding(10, 0)
						.Text(f"Source: {File.Source}")
						.Color(FLinearColor::Gray);
				}

				for (const auto& File: Data.FilesToDelete)
				{
					VerticalBox
						.SlotPadding(10, 0)
						.Text(f"Delete: {File}")
						.Color(DeleteColor);
				}
			}
		}
	}


	void DrawDeletions(const FHazeImmediateSectionHandle& SectionHandle)
	{
		auto Top = SectionHandle.HorizontalBox();
		{
			Top.SlotPadding(3, 3);
			Top.Text("EVENTS TO DELETE").Bold().Scale(2).Color(FLinearColor::Gray);
		}

		if (SectionHandle.Button("Copy Selection To 📋"))
		{
			FString SelectionText ="";
			for (const auto& Selection: SelectedDeletes)
			{
				SelectionText += f"{Selection}, \n";
			}
			Editor::CopyToClipBoard(SelectionText);
		}

		if (SectionHandle.Button("Toggle selection for filtered"))
		{
			for (const auto& NameAndEvent : EventsData.EventsToDelete)
			{
				auto& EventName = NameAndEvent.Key;

				if (Contains(SearchWords, EventName) == false)
					continue;

				if (SelectedDeletes.Remove(EventName) == false)
				{
					SelectedDeletes.Add(EventName);
				}
			}
		}

		auto DeleteBox = SectionHandle
				.VerticalBox()
				.SlotMaxHeight(250)
				.SlotPadding(20, 10)
				.ScrollBox();

		for (const auto& NameAndEvent : EventsData.EventsToDelete)
		{
			if (Contains(SearchWords, NameAndEvent.Key) == false)
				continue;

			auto AudioEvent = Cast<UHazeAudioVOEvent>(NameAndEvent.Value);
			
			if (AudioEvent == nullptr || AudioEvent.bMarkedForDelete == false)
				continue;

			auto HorizontalBox = DeleteBox
				.HorizontalBox();

			auto EventColor = FLinearColor::White;
			if (AudioEvent.bMarkedForDelete)
				EventColor = DeleteColor;

			bool bChecked = SelectedDeletes.Contains(NameAndEvent.Key);
			auto CheckBox = HorizontalBox
				.CheckBox()
				.Checked(bChecked);

			HorizontalBox
				.Text(NameAndEvent.Key)
				.Color(EventColor);

			if (CheckBox != bChecked)
			{
				if (bChecked)
					SelectedDeletes.Remove(NameAndEvent.Key);
				else
					SelectedDeletes.Add(NameAndEvent.Key);
			}
		}
	}

	void DrawUnmarkedEvents(const FHazeImmediateSectionHandle& SectionHandle)
	{
		auto Top = SectionHandle.HorizontalBox();
		{
			Top.SlotPadding(3, 3);
			Top.Text("Unmarked Events").Bold().Color(FLinearColor::Gray);
		}

		if (SectionHandle.Button("Copy Selection To 📋"))
		{
			FString SelectionText ="";
			for (const auto& Selection: SelectedUnmarked)
			{
				SelectionText += f"{Selection}, \n";
			}
			Editor::CopyToClipBoard(SelectionText);
		}

		auto Actions = SectionHandle.HorizontalBox();
		{
			Actions.SlotPadding(3, 3);
			if (Actions.Button("Convert Selected Events to ->"))
			{
				for (auto Selected: SelectedUnmarked)
				{
					UHazeAudioEvent AudioEvent;
					if (EventsData.UnmarkedVOEvents.Find(Selected, AudioEvent) == false)
						continue;

					auto Event = Cast<UHazeAudioVOEvent>(AudioEvent);

					if (Event == nullptr)
						continue;
					
					Event.Modify();
					Event.ExternalAudioType = EHazeAudioExternalAudioType(SelectedExternalAudioType);
				}
			}

			auto ExternalTypeComboBox = Actions
				.ComboBox()
				.Items(ExternalAudioTypes)
				.Value(ExternalAudioTypes[SelectedExternalAudioType]);

			SelectedExternalAudioType = ExternalTypeComboBox.SelectedIndex;
		}

		auto UnmarkedBox = SectionHandle
			.VerticalBox()
			.SlotMaxHeight(250)
			.SlotPadding(20, 10)
			.ScrollBox();

		for (const auto& NameAndEvent : EventsData.UnmarkedVOEvents)
		{
			if (Contains(SearchWords, NameAndEvent.Key) == false)
				continue;

			auto AudioEvent = Cast<UHazeAudioVOEvent>(NameAndEvent.Value);
			
			if (AudioEvent == nullptr)
				continue;

			if (NameAndEvent.Key.Contains("_PREVIS_"))
				continue;

			if (bShowOnlyThoseWithUpdates && 
				AudioEvent.bMarkedForDelete == false)
				continue;

			auto HorizontalBox = UnmarkedBox
				.HorizontalBox();

			auto EventColor = FLinearColor::White;
			if (AudioEvent.bMarkedForDelete)
				EventColor = DeleteColor;

			bool bChecked = SelectedUnmarked.Contains(NameAndEvent.Key);
			auto CheckBox = HorizontalBox
				.CheckBox()
				.Checked(bChecked);
				// .Label(NameAndEvent.Key);

			HorizontalBox
				.Text(NameAndEvent.Key)
				.Color(EventColor);

			if (CheckBox != bChecked)
			{
				if (bChecked)
					SelectedUnmarked.Remove(NameAndEvent.Key);
				else
					SelectedUnmarked.Add(NameAndEvent.Key);
			}
		}
	}

	private bool Contains(const TArray<FString>& Filters, const FString& InName) const
	{
		if (Filters.Num() == 0)
			return true;

		for (const auto& Filter: Filters)
		{
			if (!InName.Contains(Filter))
				return false;
		}

		return true;
	}

	// If they don't need to check just pass true
	bool IsCallValid(
		FString NameOfFunc,
		bool bIsPlaying = true, 
		bool bConnectedToWwise = true
		)
	{
		if (bIsPlaying)
		{
			const FText Title = FText::FromString(f"Can't {NameOfFunc} be called right now");
			const FText Message = FText::FromString(f"{NameOfFunc} can't be called during gameplay, end pie to use it!");
			EditorDialog::ShowMessage(Title, Message, EAppMsgType::Ok, EAppReturnType::Ok);

			return false;
		}

		if (!bConnectedToWwise)
		{
			const FText Title = FText::FromString("Wwise isn't connected");
			const FText Message = FText::FromString(f"{NameOfFunc} can't be called without a connection to Wwise!");
			EditorDialog::ShowMessage(Title, Message, EAppMsgType::Ok, EAppReturnType::Ok);

			return false;
		}

		return true;
	}
}