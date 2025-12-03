

struct FBakeLightLevelItem
{
	FName PersistentPathName;
	FString PersistentPath;
	FString ShortName;
	bool bSelected = false;
}

class UBakeLightingStarterUtilityWidget : UEditorUtilityWidget
{
	UPROPERTY(BindWidget)
	UHazeImmediateWidget ImmediateWidget;

	TArray<FName> QualityItems;
	default QualityItems.Add(n"Production");
	default QualityItems.Add(n"High");
	default QualityItems.Add(n"Medium");
	default QualityItems.Add(n"Preview");

	const FName DefaultQuality = n"Production";

	FName SelectedQuality;

	TArray<FBakeLightLevelItem> Levels;
	FName LastSelectedLevel;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		auto Drawer = ImmediateWidget.GetDrawer();
		if (!Drawer.IsVisible())
			return;

		if (Levels.Num() == 0)
		{
			UpdateLevels();
		}

		auto Root = Drawer.BeginVerticalBox();

		// Top toolbar panel
		{
			auto TopToolbar = Root.BorderBox().BackgroundStyle("DetailsView.CategoryTop").HorizontalBox();
			TopToolbar.SlotVAlign(EVerticalAlignment::VAlign_Center).Text("Bake Quality:");
			auto ComboBox = TopToolbar.ComboBox();
			ComboBox.Items(QualityItems);
			if (ComboBox.SelectedIndex == -1)
			{
				ComboBox.Value(DefaultQuality);
			}
			SelectedQuality = ComboBox.SelectedItem;
		}

		// Level list panel
		auto LevelList = Root.SlotFill()
		.BorderBox().BackgroundStyle("DetailsView.CategoryBottom")
		.ScrollBox(EOrientation::Orient_Vertical)
		.VerticalBox();

		int32 NumSelected = 0;
		for (FBakeLightLevelItem& Level : Levels)
		{
			auto LevelBox = LevelList.BorderBox();
			LevelBox.Text(Level.ShortName);
			LevelBox.Tooltip(Level.PersistentPath);

			// bool bShiftDown = false;
			FHazeImmediateModifierKeys Modifiers;
			if (LevelBox.WasClicked(Modifiers))
			{
				if (Modifiers.bShiftDown && !LastSelectedLevel.IsNone())
				{
					SelectBetween(LastSelectedLevel, Level.PersistentPathName, !Level.bSelected);
					LastSelectedLevel = Level.PersistentPathName;
				}
				else
				{
					Level.bSelected = !Level.bSelected;
					LastSelectedLevel = Level.PersistentPathName;
				}
			}

			if (LevelBox.IsHovered() && Level.bSelected)
				LevelBox.BackgroundStyle("ContentBrowser.AssetTileItem.NameAreaSelectedHoverBackground");
			else if (LevelBox.IsHovered())
				LevelBox.BackgroundStyle("ContentBrowser.AssetTileItem.NameAreaHoverBackground");
			else if (Level.bSelected)
				LevelBox.BackgroundStyle("ContentBrowser.AssetTileItem.NameAreaSelectedBackground");

			if (Level.bSelected)
				NumSelected++;
		
		}

		// Bottom toolbar panel
		{
			auto BottomToolbar = Root.BorderBox()
			.BackgroundStyle("DetailsView.CategoryTop")
			.HorizontalBox();

			BottomToolbar.Text(f"{NumSelected} Selected");

			BottomToolbar.SlotFill().Spacer(0);

			auto ImportButton = BottomToolbar
			.Button("Bake Lighting!");
			if (ImportButton)
			{
				TriggerBuild();
			}
		}
	}


	private int32 FindLevelIndex(FName PersistentPathName)
	{
		for (int32 i=0; i<Levels.Num(); ++i)
		{
			if (Levels[i].PersistentPathName == PersistentPathName)
			{
				return i;
			}
		}
		return -1;
	}

	private void SelectBetween(FName First, FName Second, bool bSelected)
	{
		// Find index of levels
		const int32 FirstIndex = FindLevelIndex(First);
		const int32 SecondIndex = FindLevelIndex(Second);

		if (FirstIndex == -1 || SecondIndex == +1)
			return;

		// Always loop over from min to max
		const int32 StartIndex = Math::Min(FirstIndex, SecondIndex);
		const int32 EndIndex = Math::Max(FirstIndex, SecondIndex);

		// Loop over inclusive and mark selected
		for (int32 Index = StartIndex; Index <= EndIndex; ++Index)
		{
			Levels[Index].bSelected = bSelected;
		}

	}

	private void UpdateLevels()
	{
		const ULevelFlowSettings LevelFlow = Cast<ULevelFlowSettings>(ULevelFlowSettings.DefaultObject);
		int32 NumLevels = 0;
		for (FLevelFlowSection Section : LevelFlow.Sections)
		{
			NumLevels += Section.Levels.Num();
		}
				
		Levels.Reset(NumLevels);

		if (NumLevels < 1)
			return;

		for (FLevelFlowSection Section : LevelFlow.Sections)
		{
			for (FLevelFlowLevel Level : Section.Levels)
			{
				FBakeLightLevelItem NewLevel;
				NewLevel.PersistentPathName = FName(Level.PersistentPath);
				NewLevel.PersistentPath = Level.PersistentPath;
				NewLevel.ShortName = FPaths::GetBaseFilename(Level.PersistentPath);
				NewLevel.bSelected = false;
				
				Levels.Add(NewLevel);
			}
		}
	}

	private void TriggerBuild()
	{
		if (SelectedQuality.IsNone())
			return;

		const FString Quality = SelectedQuality.ToString();

		FString MessageText = "Start Build Lighting for following levels?\n";
		TArray<FString> SelectedLevelPaths;
		for (FBakeLightLevelItem& Level : Levels)
		{
			if (Level.bSelected)
			{
				SelectedLevelPaths.Add(Level.PersistentPath);
				MessageText += f"\n{Level.ShortName}";
			}
		}

		if (SelectedLevelPaths.Num() == 0)
			return;

		EAppReturnType Answer = FMessageDialog::Open(
			EAppMsgCategory::Info,
			EAppMsgType::YesNo,
			FText::FromString(MessageText),
			FText::FromString("Bake Lighting Starter")
		);

		if (Answer == EAppReturnType::Yes)
		{
			BuildLightingStarter::TriggerBuildLightingJob(SelectedLevelPaths, Quality);
		}
	}
}

