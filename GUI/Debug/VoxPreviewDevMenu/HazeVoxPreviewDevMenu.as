
class UHazeVoxPreviewDevMenu : UHazeDevMenuEntryWidget
{
	UPROPERTY(Meta = (BindWidget))
	UHazeImmediateWidget Content;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AVoxDebugVoActor> TempVoActorClass;

	private bool bNeedsIndexing = true;

	private FName SelectedFilterId;
	private TArray<FHazeAssetData> FilteredAssets;
	private TArray<FHazeAssetData> VoxAssetDatas;

	private FHazeAssetData ContextMenuAsset;
	private FString SearchBoxString;

	private TMap<FName, AVoxDebugVoActor> TempVoActors;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
#if EDITOR
		if (!Content.Drawer.IsVisible())
			return;

		auto RootBox = Content.Drawer.BeginVerticalBox();

		auto Toolbar = RootBox.HorizontalBox();

		bool bRefreshClicked = Toolbar.Button("Refresh");
		if (bNeedsIndexing || bRefreshClicked)
		{
			IndexVoxAssets();
			bNeedsIndexing = false;
		}

		FString PreviousSearch = SearchBoxString;
		SearchBoxString = Toolbar.SlotFill().SearchBox().Value(PreviousSearch);
		if (PreviousSearch != SearchBoxString)
		{
			FilterAssets();
		}

		const bool bHasGameWorld = Editor::HasPrimaryGameWorld();

		if (!bHasGameWorld && TempVoActors.Num() > 0)
		{
			TempVoActors.Reset();
		}

		auto AssetsList = RootBox.SlotFill().ListView(FilteredAssets.Num()).ShowSelected(false);
		for (int ItemIndex : AssetsList)
		{
			auto Item = AssetsList.Item(FilteredAssets[ItemIndex].AssetName);
			Item.Text(f"{FilteredAssets[ItemIndex].AssetName.ToString()}");
			if (!bHasGameWorld)
			{
				Item.BackgroundColor(FLinearColor(1.0, 0.0, 0.0, 0.1));
			}

			if (Item.WasRightClicked())
			{
				ContextMenuAsset = FilteredAssets[ItemIndex];

				FHazeContextDelegate MenuDelegate(this, n"HandleContextOptionClicked");

				FHazeContextMenu ContextMenu;

				FHazeContextOption CopyAssetNameOption;
				CopyAssetNameOption.Icon = n"GenericCommands.Copy";
				CopyAssetNameOption.DelegateParam = n"CopyAssetName";
				CopyAssetNameOption.Label = "Copy Asset Name";
				ContextMenu.AddOption(CopyAssetNameOption, MenuDelegate);

				FHazeContextOption OpenAssetOption;
				OpenAssetOption.Icon = n"SystemWideCommands.SummonOpenAssetDialog";
				OpenAssetOption.DelegateParam = n"OpenAsset";
				OpenAssetOption.Label = "Edit Asset";
				ContextMenu.AddOption(OpenAssetOption, MenuDelegate);

				FHazeContextOption BrowseToAssetOption;
				BrowseToAssetOption.Icon = n"SystemWideCommands.FindInContentBrowser";
				BrowseToAssetOption.DelegateParam = n"BrowserToAsset";
				BrowseToAssetOption.Label = "Browse to Asset";
				ContextMenu.AddOption(BrowseToAssetOption, MenuDelegate);

				ContextMenu.ShowContextMenu();
			}

			if (bHasGameWorld && Item.WasDoubleClicked())
			{
				FScopeDebugPrimaryWorld WorldContext;

				UObject VoxAssetObj = Editor::LoadAsset(FName(FilteredAssets[ItemIndex].ObjectPath));
				UHazeVoxAsset VoxAsset = Cast<UHazeVoxAsset>(VoxAssetObj);

				TArray<UHazeVoxCharacterTemplate> NeededCharacters;
				for (const FHazeVoxVoiceLine& VL : VoxAsset.VoiceLines)
				{
					if (VL.CharacterTemplate == nullptr)
						continue;

					if (VL.CharacterTemplate.bIsPlayer == true)
						continue;

					NeededCharacters.AddUnique(VL.CharacterTemplate);
				}

				if (NeededCharacters.Num() > 0)
				{
					TArray<AHazeActor> TempActors;
					FindOrCreateTempActors(NeededCharacters, TempActors);
					HazePlayVox(VoxAsset, TempActors);
				}
				else
				{
					HazePlayVox(VoxAsset);
				}
			}
		}
		Content.Drawer.End();
#endif
	}

	private void FindOrCreateTempActors(TArray<UHazeVoxCharacterTemplate>& NeededCharacters, TArray<AHazeActor>&out OutTempActors)
	{
#if EDITOR
		for (UHazeVoxCharacterTemplate& NeededCharacter : NeededCharacters)
		{
			AVoxDebugVoActor TempActor = nullptr;
			const bool bFoundActor = TempVoActors.Find(NeededCharacter.CharacterName, TempActor);
			if (bFoundActor == true && IsValid(TempActor))
			{
				OutTempActors.AddUnique(TempActor);
			}
			else
			{
				AVoxDebugVoActor NewTempActor = SpawnActor(TempVoActorClass, Game::Mio.ActorLocation);
				NewTempActor.CharacterTemplateComponent.CharacterTemplate = NeededCharacter;
				TempVoActors.FindOrAdd(NeededCharacter.CharacterName) = NewTempActor;

				OutTempActors.Add(NewTempActor);
			}
		}
#endif
	}

	UFUNCTION()
	void HandleContextOptionClicked(FHazeContextOption Option)
	{
#if EDITOR
		if (ContextMenuAsset.AssetName.IsNone())
		{
			Log("Bad ContextMenuAsset");
			return;
		}

		if (Option.DelegateParam == n"CopyAssetName")
		{
			Editor::CopyToClipBoard(ContextMenuAsset.AssetName.ToString());
		}
		else if (Option.DelegateParam == n"OpenAsset")
		{
			Editor::OpenEditorForAsset(ContextMenuAsset.ObjectPath);
		}
		else if (Option.DelegateParam == n"BrowserToAsset")
		{
			TArray<FHazeAssetData> ToFocus;
			ToFocus.Add(ContextMenuAsset);
			Editor::SyncContentBrowserToHazeAssets(ToFocus);
		}

		ContextMenuAsset = FHazeAssetData();
#endif
	}

	private void FilterAssets()
	{
#if EDITOR
		if (SearchBoxString.IsEmpty())
		{
			FilteredAssets = VoxAssetDatas;
			return;
		}

		FilteredAssets.Reset();
		TArray<FString> SearchParts;
		SearchBoxString.ParseIntoArray(SearchParts, " ");

		for (auto AssetData : VoxAssetDatas)
		{
			bool bMatches = true;
			const FString AssetName = AssetData.AssetName.ToString();
			for (auto Part : SearchParts)
			{
				if (!AssetName.Contains(Part))
				{
					bMatches = false;
					break;
				}
			}

			if (bMatches)
				FilteredAssets.Add(AssetData);
		}

#endif
	}

	private void IndexVoxAssets()
	{
#if EDITOR
		FilteredAssets.Reset();
		VoxAssetDatas.Reset();
		Editor::GetAssetsOfClassInPath(FTopLevelAssetPath(UHazeVoxAsset), "/Game/", VoxAssetDatas);
		VoxEditor::SortVoxAssetData(VoxAssetDatas);
		FilterAssets();
#endif
	}
}
