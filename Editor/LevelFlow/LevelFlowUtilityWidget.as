const FConsoleCommand Command_OutputCookList("Haze.OutputCookList", n"ConsoleOutputCookList");

class ULevelFlowUtilityWidget : UEditorUtilityWidget
{
	default TabDisplayName = FText::FromString("Level Flow");

	UPROPERTY(BindWidget)
	UHazeImmediateWidget ImmediateWidget;

	FString SelectedLevel;

	FString LevelFilterText;
	TArray<FString> LevelFilterParts;

	bool bAutoClose = true;

	const TArray<FString> LevelFilterDelimiters;
	default LevelFilterDelimiters.Add(" ");
	default LevelFilterDelimiters.Add(",");

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		auto Drawer = ImmediateWidget.GetDrawer();
		if (!Drawer.IsVisible())
			return;

		ULevelFlowSettings LevelFlow = Cast<ULevelFlowSettings>(ULevelFlowSettings.DefaultObject);

		FHazeImmediateWidgetHandle ScrollToWidget;
		bool bScrollIntoView = false;

#if EDITOR
		if (SelectedLevel.IsEmpty())
		{
			SelectedLevel = "/Game/Maps/"+Progress::GetEditorLevelName();
			bScrollIntoView = true;
		}
#endif

		auto Root = Drawer.BeginVerticalBox();

		auto ToolbarBox = Root.HorizontalBox();
		auto LevelFlowBox = Root.SlotFill().ScrollBox();

		const FString PrevFilter = LevelFilterText;
		auto SearchBox = ToolbarBox.SlotFill().SearchBox()
			.Hint("Filter Levels...");
		Drawer.SetDefaultFocus(SearchBox);
		LevelFilterText = SearchBox.Value(LevelFilterText);
		if (PrevFilter != LevelFilterText)
		{
			const FString NewFilterText = LevelFilterText.TrimStartAndEnd();
			NewFilterText.ParseIntoArray(LevelFilterParts, LevelFilterDelimiters);
		}

		auto AutoClose = ToolbarBox
			.CheckBox()
			.Label("Auto-Close Window")
			.Tooltip("Whether to automatically close the level flow window after opening a level")
		;

		bAutoClose = AutoClose.Checked(bAutoClose);
		ToolbarBox.Spacer(20);

		for (FLevelFlowSection Section : LevelFlow.Sections)
		{
			TArray<int> IncludedLevels;
			bool bHasLevels = FilterLevels(Section, IncludedLevels);

			if (!bHasLevels)
				continue;

			auto Box = LevelFlowBox
				.Section(Section.SectionName)
				.WrapBox()
				.WrapSize(MyGeometry.LocalSize.X - 30);

			int NumSectionLevels = 0;
			for (int LevelIndex : IncludedLevels)
			{
				if (NumSectionLevels > 0)
				{
					Box
						.SlotVAlign(EVerticalAlignment::VAlign_Center)
						.BorderBox()
						.Text("➔");
				}

				if (LevelIndex == -1)
				{
					Box
						.SlotVAlign(EVerticalAlignment::VAlign_Center)
						.BorderBox()
						.Text("...");

					NumSectionLevels++;
					continue;
				}

				auto Level = Section.Levels[LevelIndex];

				FString ShortName = FPaths::GetBaseFilename(Level.PersistentPath);

				NumSectionLevels++;

				auto Border = Box
					.SlotHAlign(EHorizontalAlignment::HAlign_Left)
					.BorderBox()
					.WidthOverride(185)
					.HeightOverride(185);

				auto Content = Border.BorderBox();

				auto LevelBox = Content.VerticalBox();

				LevelBox
					.BorderBox()
					.MinDesiredHeight(150)
					.MinDesiredWidth(150)
					.AssetThumbnail(Level.PersistentPath, 150)
					.Tooltip(Level.PersistentPath);

				LevelBox
					.SlotHAlign(EHorizontalAlignment::HAlign_Center)
					.Text(ShortName);

				Content.BackgroundStyle("ContentBrowser.AssetTileItem.ThumbnailAreaBackground");
				bool bSelected = (SelectedLevel == Level.PersistentPath);

				if (Border.IsHovered() && bSelected)
					Border.BackgroundStyle("ContentBrowser.AssetTileItem.SelectedHoverBorder");
				else if (Border.IsHovered())
					Border.BackgroundStyle("ContentBrowser.AssetTileItem.HoverBorder");
				else if (bSelected)
					Border.BackgroundStyle("ContentBrowser.AssetTileItem.SelectedBorder");

				if (Border.WasClicked())
				{
					SelectedLevel = Level.PersistentPath;
				}

				if (Border.WasRightClicked())
				{
					SelectedLevel = Level.PersistentPath;

					FHazeContextDelegate MenuDelegate(this, n"HandleContextOptionClicked");

					FHazeContextMenu ContextMenu;

					FHazeContextOption BrowseToLevelOption;
					BrowseToLevelOption.Icon = n"SystemWideCommands.FindInContentBrowser";
					BrowseToLevelOption.DelegateParam = n"BrowserToLevel";
					BrowseToLevelOption.Label = "Browse to Asset";
					ContextMenu.AddOption(BrowseToLevelOption, MenuDelegate);

					ContextMenu.ShowContextMenu();
				}

				if (Border.WasDoubleClicked())
				{
					Editor::OpenMapInEditor(Level.PersistentPath);
					if (bAutoClose)
					{
						UEditorUtilitySubsystem::Get().CloseTabByID(n"/Game/Editor/LevelFlow/WBP_LevelFlow.WBP_LevelFlow_ActiveTab");
					}
				}

				if (bSelected && bScrollIntoView)
					ScrollToWidget = Border;
			}

			if (bScrollIntoView && !SelectedLevel.IsEmpty())
				LevelFlowBox.ScrollIntoView(ScrollToWidget, false, EDescendantScrollDestination::Center);
		}

		Drawer.End();
	}

	UFUNCTION()
	void HandleContextOptionClicked(FHazeContextOption Option)
	{
		if (Option.DelegateParam == n"BrowserToLevel")
		{
			if (SelectedLevel.IsEmpty())
				return;

			int LastSplit = -1;
			SelectedLevel.FindLastChar('/', LastSplit);

			FString LevelPath = SelectedLevel.Left(LastSplit);
			TArray<FHazeAssetData> Assets;
			Editor::GetAssetsInPath(LevelPath, Assets);

			TArray<FHazeAssetData> SelectedLevelAssets;
			for (auto Asset : Assets)
			{
				if (Asset.PackageName == SelectedLevel)
				{
					SelectedLevelAssets.Add(Asset);
					break;
				}
			}

			Editor::SyncContentBrowserToHazeAssets(SelectedLevelAssets);
		}
	}

	bool FilterLevels(const FLevelFlowSection& Section, TArray<int>& OutIncludedLevels) const
	{
		bool bIncludeAllLevels = LevelInFilter(Section.SectionName);
		if (bIncludeAllLevels)
		{
			OutIncludedLevels.SetNum(Section.Levels.Num());
			for (int i = 0, Count = Section.Levels.Num(); i < Count; ++i)
			{
				OutIncludedLevels[i] = i;
			}
			return true;
		}

		OutIncludedLevels.Reserve(Section.Levels.Num());
		bool bHasAnyLevels = false;
		for (int i = 0, Count = Section.Levels.Num(); i < Count; ++i)
		{
			FString ShortName = FPaths::GetBaseFilename(Section.Levels[i].PersistentPath);
			bool bLevelInFilter = LevelInFilter(ShortName);
			if (bLevelInFilter)
			{
				OutIncludedLevels.Add(i);
				bHasAnyLevels = true;
			}
			else
			{
				if (OutIncludedLevels.IsEmpty() || OutIncludedLevels.Last() != -1)
				{
					OutIncludedLevels.Add(-1);
				}
			}
		}
		return bHasAnyLevels;
	}

	bool LevelInFilter(const FString& LevelName) const
	{
		if (LevelFilterParts.IsEmpty())
			return true;

		for (const FString& Filter : LevelFilterParts)
		{
			if (LevelName.Contains(Filter))
				return true;
		}
		return false;
	}
}

void ConsoleOutputCookList(TArray<FString> Arguments)
{
	FString CookList;
	FString ChunkList;

	int ChunkPriority = 500;
	int ChunkId = 0;
	int SectionIndex = 0;

	const int InitialSectionCountInChunkZero = 2;

	auto ChapterDatabase = UHazeChapterDatabase::GetChapterDatabase();
	ULevelFlowSettings LevelFlow = Cast<ULevelFlowSettings>(ULevelFlowSettings.DefaultObject);

	TArray<FString> AllPersistents;
	TSet<FString> ChunkedPersistents;
	for (FLevelFlowSection Section : LevelFlow.Sections)
	{
		for (int i = 0, Count = Section.Levels.Num(); i < Count; ++i)
			AllPersistents.Add(Section.Levels[i].PersistentPath);
	}

	for (FLevelFlowSection Section : LevelFlow.Sections)
	{
		CookList += f"\n; {Section.SectionName}\n";
		ChunkList += f"\n; {Section.SectionName}\n";

		for (int i = 0, Count = Section.Levels.Num(); i < Count; ++i)
		{
			auto Level = Section.Levels[i];

			CookList += f"+Map={Level.PersistentPath}\n";

			if (!ChunkedPersistents.Contains(Level.PersistentPath))
			{
				ChunkList += f"+PrimaryAssetRules=(PrimaryAssetId=\"Map:{Level.PersistentPath}\",Rules=(Priority={ChunkPriority},ChunkId={ChunkId},CookRule=Unknown))\n";

				// All side content designated to this level should go here as well
				bool bWasThisLevel = false;
				for (int ChapterIndex = 0, ChapterCount = ChapterDatabase.ChapterCount; ChapterIndex < ChapterCount; ++ChapterIndex)
				{
					FHazeChapter Chapter = ChapterDatabase.GetChapterByIndex(ChapterIndex);
					if (Chapter.bIsSideContent)
					{
						if (bWasThisLevel)
						{
							for (FString Persistent : AllPersistents)
							{
								if (ChunkedPersistents.Contains(Persistent))
									continue;

								if (Progress::GetLevelGroup(Persistent) == Progress::GetLevelGroup(Chapter.ProgressPoint.InLevel))
								{
									ChunkList += f"+PrimaryAssetRules=(PrimaryAssetId=\"Map:{Persistent}\",Rules=(Priority={ChunkPriority},ChunkId={ChunkId},CookRule=Unknown))\n";
									ChunkedPersistents.Add(Persistent);
								}
							}
						}
					}
					else if (Progress::GetLevelGroup(Chapter.ProgressPoint.InLevel) == Progress::GetLevelGroup(Level.PersistentPath))
					{
						bWasThisLevel = true;
					}
					else
					{
						bWasThisLevel = false;
					}
				}
			}
		}

		ChunkPriority -= 10;
		SectionIndex += 1;
		if (SectionIndex >= InitialSectionCountInChunkZero)
			ChunkId += 1;
	}

	Log("Cook List:\n"+CookList);
	Log("Chunk List:\n"+ChunkList);
}