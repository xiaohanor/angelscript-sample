

struct FVoxOphanedEventsItem
{
	FName EventName;
	FVoxOrphanedEventsResult Result;
	bool bSelected = false;
}

class UVoxOrphanedEventsFinderUtilityWidget : UEditorUtilityWidget
{
	UPROPERTY(BindWidget)
	UHazeImmediateWidget ImmediateWidget;

	private bool bWaitingForRecords = false;
	private TArray<FName> RecodsResult;

	private float WaitingTime = 0.0;

	private TArray<FName> PendingSheetsToGet;

	private TArray<FVoxOphanedEventsItem> Events;
	private FName LastSelectedEvent;

	private bool bShowHasVoxAsset = true;
	private bool bShowReferenced = true;
	private bool bShowUnreferenced = true;

	private bool bShowOnlyNoIds = false;

	private bool bShowTypeTTS = true;
	private bool bShowTypeRendered = true;
	private bool bShowTypeNone = true;

	private const FLinearColor TTSColor = FLinearColor::MakeFromHex(0xff009c56);
	private const FLinearColor TempColor = FLinearColor::MakeFromHex(0xff053bce);
	private const FLinearColor RenderedColor = FLinearColor::MakeFromHex(0xff05adce);

	private const FLinearColor ReferencedColor = FLinearColor::MakeFromHex(0xffce6d05);
	private const FLinearColor WavColor = FLinearColor::MakeFromHex(0xffcb0000);
	private const FLinearColor NoIdsColor = FLinearColor::MakeFromHex(0xff00fc3b);

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		auto Drawer = ImmediateWidget.GetDrawer();
		if (!Drawer.IsVisible())
			return;

		auto Root = Drawer.BeginVerticalBox();

		if (bWaitingForRecords)
		{
			TickGetAllSheets(InDeltaTime);
			Root.Text(f"Downloading Records... {WaitingTime:0.2}s");
			return;
		}

		if (RecodsResult.IsEmpty())
		{
			const bool bPressed = Root.Button("Do the thing");
			if (bPressed)
			{
				WaitingTime = 0.0;

				PendingSheetsToGet.Add(n"VoiceLines");
				PendingSheetsToGet.Add(n"NonSpokenLines");
				StartGetNextSheet();
			}
			return;
		}

		auto ToolbarBox = Root.BorderBox().BackgroundStyle("DetailsView.CategoryTop").HorizontalBox();

		ToolbarBox.Text("Referenced:").Bold();
		bShowHasVoxAsset = ToolbarBox.CheckBox().Label("Has VoxAsset").Checked(bShowHasVoxAsset);
		bShowReferenced = ToolbarBox.CheckBox().Label("Event Referenced").Checked(bShowReferenced);
		bShowUnreferenced = ToolbarBox.CheckBox().Label("Event Unreferenced").Checked(bShowUnreferenced);

		ToolbarBox.Text("Asset Type:").Bold();
		bShowTypeTTS = ToolbarBox.CheckBox().Label("TTS").Checked(bShowTypeTTS);
		bShowTypeRendered = ToolbarBox.CheckBox().Label("Renderd").Checked(bShowTypeRendered);
		bShowTypeNone = ToolbarBox.CheckBox().Label("None").Checked(bShowTypeNone);

		ToolbarBox.Text("Others:").Bold();
		bShowOnlyNoIds = ToolbarBox.CheckBox().Label("Only NoIds").Checked(bShowOnlyNoIds);

		TArray<int> FilteredEvents;
		FilteredEvents.Reserve(Events.Num());

		for (int i = 0; i < Events.Num(); ++i)
		{
			const auto& Event = Events[i];

			if (!bShowHasVoxAsset && !Event.Result.VoxAssetData.AssetName.IsNone())
			{
				Events[i].bSelected = false;
				continue;
			}

			if (!bShowReferenced && Event.Result.bReferenced)
			{
				Events[i].bSelected = false;
				continue;
			}

			if (!bShowUnreferenced && !Event.Result.bReferenced)
			{
				Events[i].bSelected = false;
				continue;
			}

			if (bShowOnlyNoIds && !Event.Result.bNoEventIds)
			{
				Events[i].bSelected = false;
				continue;
			}

			if (!bShowTypeRendered && Event.Result.ExternalAudioType == EHazeAudioExternalAudioType::RenderedAudio)
			{
				Events[i].bSelected = false;
				continue;
			}

			if (!bShowTypeTTS && Event.Result.ExternalAudioType == EHazeAudioExternalAudioType::TextToSpeech)
			{
				Events[i].bSelected = false;
				continue;
			}

			if (!bShowTypeNone && Event.Result.ExternalAudioType == EHazeAudioExternalAudioType::None)
			{
				Events[i].bSelected = false;
				continue;
			}

			FilteredEvents.Add(i);
		}

		auto ListBox = Root.SlotFill().BorderBox().BackgroundStyle("DetailsView.CategoryBottom").VerticalBox();

		auto AssetsList = ListBox.SlotFill().ListView(FilteredEvents.Num()).ShowSelected(false);
		for (int ItemIndex : AssetsList)
		{
			const int EventIndex = FilteredEvents[ItemIndex];
			FVoxOphanedEventsItem& Event = Events[EventIndex];
			auto Item = AssetsList.Item(Event.EventName);
			auto ItemBox = Item.HorizontalBox();

			auto NameBorder = ItemBox.SlotFill(0.5).BorderBox();
			NameBorder.Text(f"{Event.EventName}");

			auto TimeBorder = ItemBox.SlotFill(0.07).BorderBox();
			if (!Event.Result.ModifiedTime.IsEmpty())
			{
				TimeBorder.Text(Event.Result.ModifiedTime);
			}

			auto TypeBorder = ItemBox.SlotFill(0.07).BorderBox();
			if (Event.Result.ExternalAudioType == EHazeAudioExternalAudioType::TextToSpeech)
			{
				TypeBorder.BorderBox().BackgroundColor(TTSColor).Text("TextToSpeech");
			}
			else if (Event.Result.ExternalAudioType == EHazeAudioExternalAudioType::TempAudio)
			{
				TypeBorder.BorderBox().BackgroundColor(TempColor).Text("TempAudio");
			}
			else if (Event.Result.ExternalAudioType == EHazeAudioExternalAudioType::RenderedAudio)
			{
				TypeBorder.BorderBox().BackgroundColor(RenderedColor).Text("RenderedAudio");
			}

			auto ReferencedOrWavBox = ItemBox.SlotFill(0.07).HorizontalBox();
			if (Event.Result.bReferenced)
			{
				ReferencedOrWavBox.SlotFill().BorderBox().BackgroundColor(ReferencedColor).Text("REFERENCED");
			}

			if (Event.Result.bHasWav)
			{
				ReferencedOrWavBox.SlotFill().BorderBox().BackgroundColor(WavColor).Text("WAV");
			}

			if (Event.Result.bNoEventIds)
			{
				ReferencedOrWavBox.SlotFill().BorderBox().BackgroundColor(NoIdsColor).Text("No IDs");
			}

			auto ButtonsBox = ItemBox.SlotFill(0.3).HorizontalBox();
			if (!Event.Result.VoxAssetData.AssetName.IsNone())
			{
				if (ButtonsBox.SlotFill().Button("Browse to VoxAsset").Tooltip(f"{Event.Result.VoxAssetData.AssetName}"))
				{
					TArray<FHazeAssetData> Assets;
					Assets.Add(Event.Result.VoxAssetData);
					Editor::SyncContentBrowserToHazeAssets(Assets);
				}
			}

			if (ButtonsBox.SlotFill().Button("Browse to Event"))
			{
				TArray<FHazeAssetData> Assets;
				Assets.Add(Event.Result.AssetData);
				Editor::SyncContentBrowserToHazeAssets(Assets);
			}

			if (ButtonsBox.SlotFill().Button("Open"))
			{
				TArray<FHazeAssetData> Assets;
				Editor::OpenEditorForAsset(Event.Result.AssetData.ObjectPath);
			}

			FHazeImmediateModifierKeys Modifiers;
			if (Item.WasClicked(Modifiers))
			{
				if (Modifiers.bShiftDown && !LastSelectedEvent.IsNone())
				{
					SelectBetween(LastSelectedEvent, Event.EventName, !Event.bSelected);
					LastSelectedEvent = Event.EventName;
				}
				else
				{
					Event.bSelected = !Event.bSelected;
					LastSelectedEvent = Event.EventName;
				}
			}

			if (Item.IsHovered() && Event.bSelected)
				Item.BackgroundStyle("ContentBrowser.AssetTileItem.NameAreaSelectedHoverBackground");
			else if (Item.IsHovered())
				Item.BackgroundStyle("ContentBrowser.AssetTileItem.NameAreaHoverBackground");
			else if (Event.bSelected)
				Item.BackgroundStyle("ContentBrowser.AssetTileItem.NameAreaSelectedBackground");
		}

		auto BottomToolbar = ListBox.BorderBox().BackgroundStyle("DetailsView.CategoryTop").HorizontalBox();
		if (BottomToolbar.Button("Reset Tool"))
		{
			Reset();
		}

		BottomToolbar.SlotFill().Spacer(0);
		if (BottomToolbar.Button("Mark For Delete").Padding(30, 10))
		{
			MarkSelectedForDelete();
		}
	}

	private void TickGetAllSheets(float InDeltaTime)
	{
		if (bWaitingForRecords)
		{
			WaitingTime += InDeltaTime;

			const bool bHasResult = VoxOrphanedEventsFinder::GetGridlyRecordsResult(RecodsResult);
			if (bHasResult)
			{
				bWaitingForRecords = false;
			}
		}

		if (bWaitingForRecords == false)
		{
			if (PendingSheetsToGet.Num() > 0)
			{
				StartGetNextSheet();
			}
			else
			{
				TArray<FVoxOrphanedEventsResult> Results;
				Results.Reserve(RecodsResult.Num());
				VoxOrphanedEventsFinder::FindOrphanedAudioEvents(RecodsResult, Results);

				Events.Reset(Results.Num());
				for (const FVoxOrphanedEventsResult& Result : Results)
				{
					FVoxOphanedEventsItem NewEvent;
					NewEvent.EventName = Result.EventName;
					NewEvent.Result = Result;
					NewEvent.bSelected = false;
					Events.Add(NewEvent);
				}
			}
		}
	}

	private void StartGetNextSheet()
	{
		devCheck(PendingSheetsToGet.Num() > 0);

		FName NextSheet = PendingSheetsToGet[0];
		PendingSheetsToGet.RemoveAt(0);

		bWaitingForRecords = true;
		VoxOrphanedEventsFinder::StartGettingAllGridlyRecords(NextSheet);
	}

	private int32 FindItemIndex(FName EventName)
	{
		for (int32 i = 0; i < Events.Num(); ++i)
		{
			if (Events[i].EventName == EventName)
			{
				return i;
			}
		}
		return -1;
	}

	private void SelectBetween(FName First, FName Second, bool bSelected)
	{
		// Find index of levels
		const int32 FirstIndex = FindItemIndex(First);
		const int32 SecondIndex = FindItemIndex(Second);

		if (FirstIndex == -1 || SecondIndex == +1)
			return;

		// Always loop over from min to max
		const int32 StartIndex = Math::Min(FirstIndex, SecondIndex);
		const int32 EndIndex = Math::Max(FirstIndex, SecondIndex);

		// Loop over inclusive and mark selected
		for (int32 Index = StartIndex; Index <= EndIndex; ++Index)
		{
			Events[Index].bSelected = bSelected;
		}
	}

	private void MarkSelectedForDelete()
	{
		FString MessageText = "Mark following assets for delete?\n";
		TArray<FHazeAssetData> ToMark;
		for (const auto& Event : Events)
		{
			if (Event.bSelected)
			{
				ToMark.Add(Event.Result.AssetData);
				MessageText += f"{Event.EventName}\n";
			}
		}

		if (ToMark.IsEmpty())
			return;

		EAppReturnType Answer = FMessageDialog::Open(
			EAppMsgCategory::Info,
			EAppMsgType::YesNo,
			FText::FromString(MessageText),
			FText::FromString("Vox Orphaned Events Finder"));

		if (Answer != EAppReturnType::Yes)
			return;

		VoxOrphanedEventsFinder::MarkEventsForDelete(ToMark);

		// Reset stuff after since it will be invalid
		Reset();
	}

	private void Reset()
	{
		RecodsResult.Reset();
		PendingSheetsToGet.Reset();
		Events.Reset();
		LastSelectedEvent = NAME_None;
	}
}
