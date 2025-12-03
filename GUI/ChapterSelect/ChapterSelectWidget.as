struct FChapterSelectionItem
{
	FString Id;
	FText Name;
	FHazeProgressPointRef ChapterRef;
	FHazeProgressPointRef ProgressPointRef;
	TSoftObjectPtr<UTexture2D> Image;
	bool bChapterUnlocked = true;
	bool bIsSideContent = false;
	bool bIsSideContentUnlocked = false;
	bool bIsSideContentCompleted = false;
};

struct FChapterSelectionGroup
{
	FString Id;
	FText Name;
	FHazeChapterGroup ChapterGroup;

	TArray<FChapterSelectionItem> Items;
};

event void FOnChapterSelectItem(ULobbyChapterSelectItemWidget Widget, FChapterSelectionItem Item);

const FConsoleVariable CVar_DevChapterSelect("Haze.DevChapterSelect", DefaultValue = false);

UCLASS(Abstract)
class UChapterSelectWidget : UHazeUserWidget
{
	default bCustomNavigation = true;

	UPROPERTY(BindWidget)
	UTextBlock CurrentGroupName;
	UPROPERTY(BindWidget)
	UChapterImageWidget CurrentChapterImage;

	UPROPERTY(BindWidget)
	UMenuArrowButtonWidget PreviousGroupButton;
	UPROPERTY(BindWidget)
	UMenuArrowButtonWidget NextGroupButton;

	UPROPERTY()
	UMaterialInterface ChapterImageWhileLoading;
	UPROPERTY(BindWidget)
	UScrollBox ItemList;

	UPROPERTY()
	TSubclassOf<ULobbyChapterSelectItemWidget> ItemWidgetClass;

	FOnChapterSelectItem OnItemSelectionChanged;

	UHazeChapterDatabase ChapterDatabase;

	TArray<FChapterSelectionGroup> SelectionGroups;
	TArray<ULobbyChapterSelectItemWidget> ItemWidgets;
	int SelectedGroup = 0;
	int SelectedItem = 0;

	bool bCanNavigate = true;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		ChapterDatabase = UHazeChapterDatabase::GetChapterDatabase();

		NextGroupButton.OnClicked.AddUFunction(this, n"NextGroupClicked");
		PreviousGroupButton.OnClicked.AddUFunction(this, n"PreviousGroupClicked");
	}

	void Refresh()
	{
		GenerateChapterSelectionItems();
		RefreshItemWidgets();
		UpdateWidgetsFromSelectionChange();

		PreviousGroupButton.bDisabled = !CanNavigate();
		NextGroupButton.bDisabled = !CanNavigate();
	}

	bool ShouldShowDevProgressPoints() const
	{
#if TEST
		if (Debug::IsUXTestBuild())
			return false;
		if (DemoUpsell::NeedsUpsell())
			return false;
		if (!CVar_DevChapterSelect.GetBool())
			return false;
		return true;
#else
		return false;
#endif
	}

	UFUNCTION()
	private void NextGroupClicked(UMenuArrowButtonWidget Widget)
	{
		NavigateGroupNext();
	}

	UFUNCTION()
	private void PreviousGroupClicked(UMenuArrowButtonWidget Widget)
	{
		NavigateGroupPrevious();
	}

	void GenerateChapterSelectionItems()
	{
		FString SelectedGroupId;
		FString SelectedItemId;

		if (SelectionGroups.IsValidIndex(SelectedGroup))
		{
			SelectedGroupId = SelectionGroups[SelectedGroup].Id;
			if (SelectionGroups[SelectedGroup].Items.IsValidIndex(SelectedItem))
				SelectedItemId = SelectionGroups[SelectedGroup].Items[SelectedItem].Id;
		}

		SelectionGroups.Reset();
		SelectedGroup = 0;
		SelectedItem = 0;

		// Groups for chapter select
		int GroupCount = ChapterDatabase.GetChapterGroupCount();
		for (int i = 0; i < GroupCount; ++i)
		{
			FHazeChapterGroup ChapterGroup = ChapterDatabase.GetChapterGroupByIndex(i);

			// On the host, we don't create entries for stuff that isn't unlocked at all.
			// On the client this is handled by the bUnlocked bool, because the
			// host might still select something we don't have unlocked
			// ourselves.
			if (bCanNavigate)
			{
				if (!Save::IsChapterSelectUnlocked(ChapterGroup.ProgressPoint))
					continue;
			}

			TArray<FHazeChapter> Chapters = ChapterDatabase.GetChaptersInGroup(i);
			if (Chapters.Num() == 0)
				continue;

			FChapterSelectionGroup SelectionGroup;
			SelectionGroup.Id = Progress::GetProgressPointRefID(ChapterGroup.ProgressPoint);
			SelectionGroup.Name = ChapterGroup.GroupName;
			SelectionGroup.ChapterGroup = ChapterGroup;

			if (SelectedGroupId == SelectionGroup.Id)
				SelectedGroup = SelectionGroups.Num();

			for (FHazeChapter& Chapter : Chapters)
			{
				FChapterSelectionItem Item;
				Item.Id = Progress::GetProgressPointRefID(Chapter.ProgressPoint);
				Item.Name = Chapter.Name;
				Item.ChapterRef = Chapter.ProgressPoint;
				Item.ProgressPointRef = Chapter.ProgressPoint;
				Item.Image = Chapter.Image;

				if (Chapter.bIsSideContent)
				{
					Item.bChapterUnlocked = Save::IsChapterSelectUnlocked(ChapterDatabase.GetPreviousGameChapterForSideContent(Chapter.ProgressPoint).ProgressPoint);
					Item.bIsSideContent = true;
					Item.bIsSideContentUnlocked = Save::IsSideContentUnlocked(Chapter.ProgressPoint);
					Item.bIsSideContentCompleted = Save::IsSideContentCompleted(Chapter.ProgressPoint);
				}
				else
				{
					Item.bChapterUnlocked = Save::IsChapterSelectUnlocked(Chapter.ProgressPoint);
				}

				if (bCanNavigate)
				{
					if (!Item.bChapterUnlocked)
						continue;
				}

				if (SelectedGroup == SelectionGroups.Num() && Item.Id == SelectedItemId)
					SelectedItem = SelectionGroup.Items.Num();

				SelectionGroup.Items.Add(Item);
			}

			SelectionGroups.Add(SelectionGroup);
		}

		// Group for dev progress points
		if (ShouldShowDevProgressPoints())
		{
			TSet<FString> AddedLevelGroups;

			ULevelFlowSettings LevelFlow = Cast<ULevelFlowSettings>(ULevelFlowSettings.DefaultObject);
			for (auto Section : LevelFlow.Sections)
			{
				for (auto Level : Section.Levels)
				{
					FString Group = Progress::GetLevelGroup(Progress::GetShortLevelName(Level.PersistentPath));
					if (AddedLevelGroups.Contains(Group))
						continue;

					AddDevProgressPointsFromLevelGroup(Group, SelectedGroupId, SelectedItemId);
					AddedLevelGroups.Add(Group);
				}
			}

			TArray<FString> LevelGroups = Progress::GetLevelGroupsWithProgressPoints();
			for (FString LevelGroup : LevelGroups)
			{
				if (Progress::IsLevelTestMap(LevelGroup))
					continue;
				if (AddedLevelGroups.Contains(LevelGroup))
					continue;

				AddDevProgressPointsFromLevelGroup(LevelGroup, SelectedGroupId, SelectedItemId);
				AddedLevelGroups.Add(LevelGroup);
			}
		}
	}

	void AddDevProgressPointsFromLevelGroup(FString LevelGroup, FString& SelectedGroupId, FString& SelectedItemId)
	{
		FString AbbrevGroup = Progress::GetShortLevelName(LevelGroup);
		FString ShortGroup = AbbrevGroup;
		int Pos = -1;
		if (ShortGroup.FindChar('/', Pos))
			ShortGroup = ShortGroup.Mid(0, Pos);

		AbbrevGroup.RemoveFromStart(ShortGroup+"/");

		TArray<FHazeProgressPoint> ProgressPoints = Progress::GetProgressPointsInLevelGroup(LevelGroup);
		if (ProgressPoints.Num() == 0)
			return;

		FString GroupId = f"DEV:{ShortGroup}";
		bool bHadSelectedGroup = false;
		if (SelectedGroupId == GroupId)
			bHadSelectedGroup = true;

		// Build items for all the progress points in this
		TArray<FChapterSelectionItem> Items;

		int HadSelectedItem = -1;
		for (FHazeProgressPoint ProgressPoint : ProgressPoints)
		{
			if (ProgressPoint.bDevOnly)
				continue;

			FChapterSelectionItem Item;
			Item.Id = "DEV:"+Progress::GetProgressPointID(ProgressPoint);

			Item.Name = FText::FromString(f"{AbbrevGroup}: {ProgressPoint.Name}");
			Item.ChapterRef = Progress::GetProgressPointRefFromID(Progress::GetProgressPointID(ProgressPoint));
			Item.ProgressPointRef = Item.ChapterRef;

			if (bHadSelectedGroup && Item.Id == SelectedItemId)
				HadSelectedItem = Items.Num();

			Items.Add(Item);
		}

		if (Items.Num() == 0)
			return;

		bool bExistingGroup = false;
		for (FChapterSelectionGroup& Group : SelectionGroups)
		{
			if (Group.Id == GroupId)
			{
				bExistingGroup = true;
				if (HadSelectedItem != -1)
					SelectedItem = HadSelectedItem + Group.Items.Num();
				Group.Items.Append(Items);
			}
		}

		if (!bExistingGroup)
		{
			FChapterSelectionGroup SelectionGroup;
			SelectionGroup.Id = GroupId;
			SelectionGroup.Name = FText::FromString("(DEV) "+ShortGroup);
			SelectionGroup.Items = Items;

			if (bHadSelectedGroup)
				SelectedGroup = SelectionGroups.Num();
			if (HadSelectedItem != -1)
				SelectedItem = HadSelectedItem;

			SelectionGroups.Add(SelectionGroup);
		}
	}

	void RefreshItemWidgets()
	{
		for (auto Widget : ItemWidgets)
			Widget.RemoveFromParent();
		ItemWidgets.Reset();

		if (!SelectionGroups.IsValidIndex(SelectedGroup))
			return;

		const FChapterSelectionGroup& ActiveGroup = SelectionGroups[SelectedGroup];
		for (auto Item : ActiveGroup.Items)
		{
			auto Widget = Cast<ULobbyChapterSelectItemWidget>(Widget::CreateWidget(this, ItemWidgetClass));
			Widget.SetItem(Item);
			Widget.OnClicked.AddUFunction(this, n"OnClickedWidget");
			Widget.bClickable = CanNavigate();

			ItemList.AddChild(Widget);
			ItemWidgets.Add(Widget);
		}

		UMenuEffectEventHandler::Trigger_OnChapterSelectItemsRefresh(
			Menu::GetAudioActor(), FChapterSelectItemsRefreshData(this));
	}

	UFUNCTION()
	private void OnClickedWidget(UChapterSelectItemWidget Item)
	{
		SetSelectedItem(Item.SelectionItem.ChapterRef, Item.SelectionItem.ProgressPointRef);
		UpdateWidgetsFromSelectionChange();
		BroadcastSelectionChange();
	}

	void UpdateWidgetsFromSelectionChange()
	{
		if (!SelectionGroups.IsValidIndex(SelectedGroup))
			return;

		const FChapterSelectionGroup& ActiveGroup = SelectionGroups[SelectedGroup];
		if (!ActiveGroup.Items.IsValidIndex(SelectedItem))
			return;

		const FChapterSelectionItem& ActiveItem = ActiveGroup.Items[SelectedItem];

		CurrentGroupName.Text = ActiveGroup.Name;
		CurrentChapterImage.SetChapterImage(ActiveItem.Image);

		if (SelectedGroup > 0)
			PreviousGroupButton.Visibility = ESlateVisibility::Visible;
		else
			PreviousGroupButton.Visibility = ESlateVisibility::Hidden;

		if (SelectedGroup < SelectionGroups.Num()-1)
			NextGroupButton.Visibility = ESlateVisibility::Visible;
		else
			NextGroupButton.Visibility = ESlateVisibility::Hidden;

		for (int i = 0, Count = ItemWidgets.Num(); i < Count; ++i)
		{
			ItemWidgets[i].bSelected = (i == SelectedItem);
			if (i == SelectedItem || ItemWidgets[i].SelectionItem.bChapterUnlocked)
				ItemWidgets[i].Visibility = ESlateVisibility::Visible;
			else
				ItemWidgets[i].Visibility = ESlateVisibility::Collapsed;
		}
	}

	bool CanNavigate() const
	{
		return bCanNavigate;
	}

	void BroadcastSelectionChange()
	{
		if (ItemWidgets.IsValidIndex(SelectedItem))
			OnItemSelectionChanged.Broadcast(ItemWidgets[SelectedItem], ItemWidgets[SelectedItem].SelectionItem);
	}

	FChapterSelectionItem GetSelectedItem()
	{
		if (ItemWidgets.IsValidIndex(SelectedItem))
			return ItemWidgets[SelectedItem].SelectionItem;
		return FChapterSelectionItem();
	}

	bool SetSelectedItem(FHazeProgressPointRef Chapter, FHazeProgressPointRef ProgressPoint)
	{
		int PreviousGroup = SelectedGroup;
		int PreviousItem = SelectedItem;

		FString ChapterId = Progress::GetProgressPointRefID(Chapter);
		FString ProgressPointId = Progress::GetProgressPointRefID(ProgressPoint);

		// Check if we have any item that matches the start type we want
		bool bFoundItem = false;
		for (int GroupIndex = 0, GroupCount = SelectionGroups.Num(); GroupIndex < GroupCount; ++GroupIndex)
		{
			FChapterSelectionGroup& Group = SelectionGroups[GroupIndex];
			for (int ItemIndex = 0, ItemCount = Group.Items.Num(); ItemIndex < ItemCount; ++ItemIndex)
			{
				FChapterSelectionItem& Item = Group.Items[ItemIndex];
				if (Progress::GetProgressPointRefID(Item.ChapterRef) == ChapterId
				 && Progress::GetProgressPointRefID(Item.ProgressPointRef) == ProgressPointId)
				{
					bFoundItem = true;
					SelectedGroup = GroupIndex;
					SelectedItem = ItemIndex;

					break;
				}
			}

			if (bFoundItem)
				break;
		}

		if (SelectedGroup != PreviousGroup)
			RefreshItemWidgets();

		if (SelectedGroup != PreviousGroup || SelectedItem != PreviousItem)
		{
			UpdateWidgetsFromSelectionChange();
			return true;
		}
		else
		{
			return false;
		}
	}

	void NavigateGroupPrevious()
	{
		if (!CanNavigate())
			return;

		SelectedGroup -= 1;
		SelectedGroup = Math::Clamp(SelectedGroup, 0, SelectionGroups.Num()-1);
		SelectedItem = 0;
		RefreshItemWidgets();
		UpdateWidgetsFromSelectionChange();
		ScrollToSelectedItem();
		BroadcastSelectionChange();
	}

	void NavigateGroupNext()
	{
		if (!CanNavigate())
			return;

		SelectedGroup += 1;
		SelectedGroup = Math::Clamp(SelectedGroup, 0, SelectionGroups.Num()-1);
		SelectedItem = 0;
		RefreshItemWidgets();
		UpdateWidgetsFromSelectionChange();
		ScrollToSelectedItem();
		BroadcastSelectionChange();
	}

	void NavigateItemPrevious()
	{
		if (!CanNavigate())
			return;
		if (!SelectionGroups.IsValidIndex(SelectedGroup))
			return;

		const FChapterSelectionGroup& ActiveGroup = SelectionGroups[SelectedGroup];
		SelectedItem -= 1;
		SelectedItem = Math::Clamp(SelectedItem, 0, ActiveGroup.Items.Num()-1);
		UpdateWidgetsFromSelectionChange();
		ScrollToSelectedItem();
		BroadcastSelectionChange();
	}

	void NavigateItemNext()
	{
		if (!CanNavigate())
			return;
		if (!SelectionGroups.IsValidIndex(SelectedGroup))
			return;

		const FChapterSelectionGroup& ActiveGroup = SelectionGroups[SelectedGroup];
		SelectedItem += 1;
		SelectedItem = Math::Clamp(SelectedItem, 0, ActiveGroup.Items.Num()-1);
		UpdateWidgetsFromSelectionChange();
		ScrollToSelectedItem();
		BroadcastSelectionChange();
	}

	void ScrollToSelectedItem()
	{
		if (ItemWidgets.IsValidIndex(SelectedItem))
			ItemList.ScrollWidgetIntoView(ItemWidgets[SelectedItem], false, Padding=100);
	}

	UFUNCTION(BlueprintOverride)
	UWidget OnCustomNavigation(FGeometry Geometry, FNavigationEvent Event, EUINavigationRule& OutRule)
	{
		if (CanNavigate())
			return nullptr;

		// We respond to navigation here,
		// so analog stick can be used as well as dpad or keyboard.
		// We don't use the simulated buttons for the left stick,
		// because those are not nicely deadzoned.
		if (Event.NavigationType == EUINavigation::Left)
			NavigateGroupPrevious();
		if (Event.NavigationType == EUINavigation::Right)
			NavigateGroupNext();
		if (Event.NavigationType == EUINavigation::Up)
			NavigateItemPrevious();
		if (Event.NavigationType == EUINavigation::Down)
			NavigateItemNext();

		return nullptr;
	}
}

event void FOnChapterSelectItemClicked(UChapterSelectItemWidget Item);
class UChapterSelectItemWidget : UHazeUserWidget
{
	default bIsFocusable = false;
	default Visibility = ESlateVisibility::Visible;

	UPROPERTY(BindWidget)
	UScalableSlicedImage Background;
	UPROPERTY(BindWidget)
	UTextBlock NameWidget;
	UPROPERTY(BindWidget)
	UWidget SidePortalUnknownWidget;
	UPROPERTY(BindWidget)
	UWidget SidePortalWidget;
	UPROPERTY(BindWidget)
	UWidget SidePortalCompletedWidget;

	UPROPERTY()
	FOnChapterSelectItemClicked OnClicked;

	UPROPERTY()
	FOnChapterSelectItemClicked OnFocused;

	UPROPERTY(BlueprintReadOnly)
	bool bSelected = false;

	UPROPERTY(BlueprintReadOnly)
	bool bHovered = false;

	UPROPERTY(BlueprintReadOnly)
	bool bPressed = false;

	UPROPERTY(EditAnywhere)
	bool bClickable = true;

	UPROPERTY(EditDefaultsOnly)
	UTexture2D NormalTexture;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D HoveredTexture;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D PressedTexture;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D SelectedTexture;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D SelectedHoveredTexture;

	UPROPERTY(EditDefaultsOnly)
	UTexture2D NormalTexture_Mio;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D HoveredTexture_Mio;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D PressedTexture_Mio;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D SelectedTexture_Mio;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D SelectedHoveredTexture_Mio;

	UPROPERTY(EditDefaultsOnly)
	UTexture2D NormalTexture_Zoe;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D HoveredTexture_Zoe;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D PressedTexture_Zoe;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D SelectedTexture_Zoe;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D SelectedHoveredTexture_Zoe;

	FChapterSelectionItem SelectionItem;

	void SetItem(FChapterSelectionItem Item)
	{
		SelectionItem = Item;

		NameWidget.Text = Item.Name;
		if (SelectionItem.bIsSideContent)
		{
			if (!SelectionItem.bIsSideContentUnlocked)
				NameWidget.Text = FText::FromString("???");
			else
				NameWidget.ColorAndOpacity = FLinearColor::White;

			if (SelectionItem.bIsSideContentCompleted)
			{
				SidePortalWidget.Visibility = ESlateVisibility::Collapsed;
				SidePortalCompletedWidget.Visibility = ESlateVisibility::HitTestInvisible;
				SidePortalUnknownWidget.Visibility = ESlateVisibility::Collapsed;
			}
			else if (SelectionItem.bIsSideContentUnlocked)
			{
				SidePortalWidget.Visibility = ESlateVisibility::HitTestInvisible;
				SidePortalCompletedWidget.Visibility = ESlateVisibility::Collapsed;
				SidePortalUnknownWidget.Visibility = ESlateVisibility::Collapsed;
			}
			else
			{
				SidePortalWidget.Visibility = ESlateVisibility::Collapsed;
				SidePortalCompletedWidget.Visibility = ESlateVisibility::Collapsed;
				SidePortalUnknownWidget.Visibility = ESlateVisibility::HitTestInvisible;
			}
		}
		else
		{
			SidePortalWidget.Visibility = ESlateVisibility::Collapsed;
			SidePortalCompletedWidget.Visibility = ESlateVisibility::Collapsed;
			SidePortalUnknownWidget.Visibility = ESlateVisibility::Collapsed;
		}
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		return FEventReply::Handled();
	}

	UFUNCTION(BlueprintOverride)
	void OnFocusLost(FFocusEvent InFocusEvent)
	{
		bPressed = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseEnter(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.CursorDelta.IsNearlyZero())
			return;
		if (!bClickable)
			return;
		bHovered = true;
		OnFocused.Broadcast(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseLeave(FPointerEvent MouseEvent)
	{
		if (!bClickable)
			return;
		bHovered = false;
		bPressed = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		EHazeSelectPlayer ShowForPlayer = EHazeSelectPlayer::Both;
		// UHazeGameInstance HazeGameInstance = Game::HazeGameInstance;
		// if (HazeGameInstance != nullptr)
		// 	ShowForPlayer = HazeGameInstance.PausingPlayer;

		if (bSelected)
		{
			NameWidget.ColorAndOpacity = FLinearColor::Black;

			if (bPressed)
			{
				switch (ShowForPlayer)
				{
					case EHazeSelectPlayer::Mio:
						Background.SetBrushFromTexture(PressedTexture_Mio);
					break;
					case EHazeSelectPlayer::Zoe:
						Background.SetBrushFromTexture(PressedTexture_Zoe);
					break;
					default:
						Background.SetBrushFromTexture(PressedTexture);
					break;
				}
			}
			else if (bHovered)
			{
				switch (ShowForPlayer)
				{
					case EHazeSelectPlayer::Mio:
						Background.SetBrushFromTexture(SelectedHoveredTexture_Mio);
					break;
					case EHazeSelectPlayer::Zoe:
						Background.SetBrushFromTexture(SelectedHoveredTexture_Zoe);
					break;
					default:
						Background.SetBrushFromTexture(SelectedHoveredTexture);
					break;
				}
			}
			else
			{
				switch (ShowForPlayer)
				{
					case EHazeSelectPlayer::Mio:
						Background.SetBrushFromTexture(SelectedTexture_Mio);
					break;
					case EHazeSelectPlayer::Zoe:
						Background.SetBrushFromTexture(SelectedTexture_Zoe);
					break;
					default:
						Background.SetBrushFromTexture(SelectedTexture);
					break;
				}
			}
		}
		else
		{
			if (bPressed)
				NameWidget.ColorAndOpacity = FLinearColor::Black;
			else
				NameWidget.ColorAndOpacity = FLinearColor::White;

			if (bPressed)
			{
				switch (ShowForPlayer)
				{
					case EHazeSelectPlayer::Mio:
						Background.SetBrushFromTexture(PressedTexture_Mio);
					break;
					case EHazeSelectPlayer::Zoe:
						Background.SetBrushFromTexture(PressedTexture_Zoe);
					break;
					default:
						Background.SetBrushFromTexture(PressedTexture);
					break;
				}
			}
			else if (bHovered)
			{
				switch (ShowForPlayer)
				{
					case EHazeSelectPlayer::Mio:
						Background.SetBrushFromTexture(HoveredTexture_Mio);
					break;
					case EHazeSelectPlayer::Zoe:
						Background.SetBrushFromTexture(HoveredTexture_Zoe);
					break;
					default:
						Background.SetBrushFromTexture(HoveredTexture);
					break;
				}
			}
			else
			{
				switch (ShowForPlayer)
				{
					case EHazeSelectPlayer::Mio:
						Background.SetBrushFromTexture(NormalTexture_Mio);
					break;
					case EHazeSelectPlayer::Zoe:
						Background.SetBrushFromTexture(NormalTexture_Zoe);
					break;
					default:
						Background.SetBrushFromTexture(NormalTexture);
					break;
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (!bClickable)
			return FEventReply::Unhandled();

		if (MouseEvent.EffectingButton == EKeys::LeftMouseButton && !MouseEvent.IsRepeat())
		{
			bPressed = true;
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonUp(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (!bClickable)
			return FEventReply::Unhandled();

		if (MouseEvent.EffectingButton == EKeys::LeftMouseButton && !MouseEvent.IsRepeat())
		{
			if (bPressed)
			{
				bPressed = false;
				OnClicked.Broadcast(this);
			}
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}
};