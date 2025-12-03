class ULocalWirelessFindLanGamesWidget : UMainMenuStateWidget
{
	default bShowMenuBackground = true;
	default bShowButtonBarBackground = true;

	UPROPERTY(BindWidget)
	UListView LanGameList;

	UPROPERTY(BindWidget)
	UTextBlock EAAccountNameText;

	UPROPERTY(BindWidget)
	UMenuPromptOrButton BackButton;

	UPROPERTY(BindWidget)
	UMenuPromptOrButton SearchButton;

	UPROPERTY(BindWidget)
	UWidget LanGameListLoadingSpinner;

	TArray<UObject> LanGameObjects;
	TArray<UHazeOnlineLanGame> LanGames;

	bool bAwaitingFocus = false;
	EFocusCause AwaitingFocusCause;

	bool bIsSearching = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		BackButton.OnPressed.AddUFunction(this, n"ReturnToMainMenu");
		SearchButton.OnPressed.AddUFunction(this, n"FindLanGames");
	}

	UFUNCTION(BlueprintOverride)
	void Destruct()
	{
		if (bIsSearching)
		{
			// Online::StopFriendSearch();
			bIsSearching = false;
		}
	}

	bool IsLanGameListLoading()
	{
		// return Online::IsFriendsListLoading();
		return false;
	}

	void OnTransitionEnter(EMainMenuState PreviousState, bool bSnap) override
	{
		Super::OnTransitionEnter(PreviousState, bSnap);

		RefreshLanGames();
	}

	void RefreshLanGames()
	{
		EAAccountNameText.SetText(FText::FromString(Online::GetEAUsername()));

		TArray<UHazeOnlineLanGame> LanGameData;
		bool bIsSearchSuccessful = Online::GetLanGames(LanGameData);

		if (!bIsSearchSuccessful)
		{
			ReturnToMainMenu(nullptr);
			return;
		}

		if (LanGameData == LanGames)
			return;

		// Sort the lan games so the most likely ones are at the top
		TArray<FLanGameSorter> SortedLanGames;

		for (auto LanGame : LanGameData)
		{
			int DisplayOrder = 0;
			if (!LanGame.bIsJoinableLobby)
				DisplayOrder += 100;

			FLanGameSorter Sorter;
			Sorter.LanGame = LanGame;
			Sorter.DisplayOrder = DisplayOrder;
			SortedLanGames.Add(Sorter);
		}

		SortedLanGames.Sort();

		LanGames.Reset();
		LanGameObjects.Reset();
		for (auto LanGame : SortedLanGames)
		{
			LanGameObjects.Add(LanGame.LanGame);
			LanGames.Add(LanGame.LanGame);
		}

		LanGameList.SetListItems(LanGameObjects);
		LanGameList.RequestRefresh();

		auto SelectedLanGame = LanGameList.GetSelectedItem();
		if (SelectedLanGame == nullptr && LanGameObjects.Num() != 0)
		{
			LanGameList.SetSelectedIndex(0);
			LanGameList.ScrollIndexIntoView(0);

			auto SelectedWidget = LanGameList.GetEntryWidgetForItemIndex(0);
			if (SelectedWidget != nullptr)
				Widget::SetAllPlayerUIFocus(SelectedWidget);
		}
		else
		{
			LanGameList.ScrollItemIntoView(SelectedLanGame);
		}
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		auto Widgets = LanGameList.GetDisplayedEntryWidgets();
		auto SelectedWidget = LanGameList.GetSelectedEntryWidget();
		if (SelectedWidget != nullptr && !IsLanGameListLoading())
		{
			bAwaitingFocus = false;
			return FEventReply::Handled().SetUserFocus(SelectedWidget, InFocusEvent.Cause);
		}
		else if (Widgets.Num() != 0 && Widgets[0] != nullptr && !IsLanGameListLoading())
		{
			bAwaitingFocus = false;
			return FEventReply::Handled().SetUserFocus(Widgets[0], InFocusEvent.Cause);
		}
		else
		{
			bAwaitingFocus = true;
			AwaitingFocusCause = InFocusEvent.Cause;
			return FEventReply::Handled();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnFocusLost(FFocusEvent InFocusEvent)
	{
		bAwaitingFocus = false;
	}

	void UpdateFocus()
	{
		if (bAwaitingFocus)
		{
			if (!IsLanGameListLoading())
			{
				auto Widgets = LanGameList.GetDisplayedEntryWidgets();
				if (Widgets.Num() != 0 && Widgets[0] != nullptr)
				{
					Widget::SetAllPlayerUIFocus(Widgets[0], AwaitingFocusCause);
					bAwaitingFocus = false;
				}
			}
		}
	}

	UFUNCTION()
	void FindLanGames(UHazeUserWidget ButtonWidget)
	{
		RefreshLanGames();
		bIsSearching = true;

		bAwaitingFocus = true;
		AwaitingFocusCause = EFocusCause::SetDirectly;
		Widget::SetAllPlayerUIFocus(this);
	}

	UFUNCTION()
	void ReturnToMainMenu(UHazeUserWidget ButtonWidget)
	{
		Online::UpdateRichPresence(EHazeRichPresence::MainMenu);
		MainMenu.ReturnToMainMenu();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		// If the console is up, don't eat the key input
		if (Console::IsConsoleActive() || Console::IsConsoleKey(Event.Key))
			return FEventReply::Unhandled();
		if (Event.IsRepeat())
			return FEventReply::Unhandled();
		if (!bIsActive)
			return FEventReply::Handled();

		if (Event.Key == EKeys::Escape || Event.Key == EKeys::Virtual_Back)
		{
			ReturnToMainMenu(nullptr);
			return FEventReply::Handled();
		}
		else if (Event.Key == EKeys::Gamepad_FaceButton_Top || Event.Key == EKeys::F1)
		{
			FindLanGames(nullptr);
			return FEventReply::Handled();
		}

		return Super::OnKeyDown(Geom, Event);
	}

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	void Tick(FGeometry Geometry, float DeltaTime)
	{
		Super::Tick(Geometry, DeltaTime);
	
		UpdateFocus();

		if (IsLanGameListLoading())
		{
			LanGameListLoadingSpinner.Visibility = ESlateVisibility::HitTestInvisible;
			LanGameList.Visibility = ESlateVisibility::Hidden;
		}
		else
		{
			LanGameListLoadingSpinner.Visibility = ESlateVisibility::Hidden;
			LanGameList.Visibility = ESlateVisibility::Visible;
		}
	}
};

struct FLanGameSorter
{
	UHazeOnlineLanGame LanGame;
	int DisplayOrder = 0;

	int opCmp(const FLanGameSorter& Other) const
	{
		if (DisplayOrder < Other.DisplayOrder)
			return -1;
		else if (DisplayOrder > Other.DisplayOrder)
			return 1;
		else
			return 0;
	}
}

class ULocalWirelessLanGameWidget : UHazeUserWidget
{
	UHazeOnlineLanGame LanGame;

	UPROPERTY(BindWidget)
	UMenuSelectionHighlight SelectionHighlight;
	UPROPERTY(BindWidget)
	UWidget ContentBox;

	UPROPERTY(BindWidget)
	UTextBlock NameWidget;
	UPROPERTY(BindWidget)
	UTextBlock StateWidget;

	UPROPERTY(BindWidget)
	UWidget FirstPartyIdBox;
	UPROPERTY(BindWidget)
	UTextBlock FirstPartyNetworkName;
	UPROPERTY(BindWidget)
	UTextBlock FirstPartyIdWidget;
	
	UPROPERTY(BindWidget)
	UImage PrimaryPlatformIcon;
	UPROPERTY(BindWidget)
	UImage FirstPartyPlatformIcon;

	UPROPERTY()
	UTexture2D EAIcon;
	UPROPERTY()
	UTexture2D SteamIcon;
	UPROPERTY()
	UTexture2D XboxIcon;
	UPROPERTY()
	UTexture2D PlaystationIcon;
	UPROPERTY()
	UTexture2D SageIcon;
	UPROPERTY()
	UTexture2D GenericConsoleIcon;

	UPROPERTY(BlueprintReadOnly)
	bool bFocused = false;

	UPROPERTY(BlueprintReadOnly)
	bool bFocusedByMouse = false;

	UPROPERTY(BlueprintReadOnly)
	bool bHovered = false;

	UPROPERTY(BlueprintReadOnly)
	bool bPressed = false;

	private UHazeOnlineLanGame PendingActionLanGame;

	UFUNCTION()
	void SetEntryData(UObject InLanGame)
	{
		LanGame = Cast<UHazeOnlineLanGame>(InLanGame);
		Update();
	}

	UFUNCTION()
	private void OnShowActions()
	{
		PendingActionLanGame = LanGame;

		FMessageDialog Dialog;
		Dialog.Message = LanGame.HostNickname;
		Dialog.bInstantCloseOnCancel = true;

		if (LanGame.bIsJoinableLobby)
		{
			Dialog.AddOption(
				NSLOCTEXT("LobbyFriend", "JoinLobby", "Join Online Lobby"),
				FOnMessageDialogOptionChosen(this, n"Action_JoinLobby")
			);
		}

		Dialog.AddOption(
			NSLOCTEXT("LobbyFriend", "CloseActions", "Close"),
			FOnMessageDialogOptionChosen(),
			EMessageDialogOptionType::Cancel
		);
		ShowPopupMessage(Dialog, this);
	}

	UFUNCTION()
	private void Action_JoinLobby()
	{
		Online::JoinLanGameLobby(PendingActionLanGame);
	}

	bool ShouldShowButtons() const
	{
		if (bFocused)
			return true;
		EHazePlayerControllerType Type = Lobby::GetMostLikelyControllerType();
		if (Type == EHazePlayerControllerType::Keyboard)
			return true;
		return false;
	}

	void Update()
	{
		NameWidget.SetText(LanGame.HostNickname);

		if (IsHoveredOrActive())
		{
			SelectionHighlight.bIsHighlighted = true;
			NameWidget.SetColorAndOpacity(FLinearColor::Black);
		}
		else
		{
			SelectionHighlight.bIsHighlighted = false;
			NameWidget.SetColorAndOpacity(FLinearColor::White);
		}

		if (LanGame.bIsJoinableLobby)
		{
			StateWidget.SetText(NSLOCTEXT("LobbyFriend", "ThisGameStateLobby", "Split Fiction - Online Lobby"));
			StateWidget.SetColorAndOpacity(FLinearColor(1.00, 0.98, 0.17));
		}

		switch (LanGame.FirstPartyType)
		{
			case EHazeOnlineFirstPartyType::Steam:
				FirstPartyNetworkName.SetText(NSLOCTEXT("LobbyFriend", "SteamNetworkLabel", "Steam:"));
				FirstPartyNetworkName.SetVisibility(ESlateVisibility::HitTestInvisible);
				FirstPartyIdWidget.SetText(LanGame.FirstPartyNickname);
				FirstPartyIdBox.Visibility = ESlateVisibility::Visible;

				PrimaryPlatformIcon.SetBrushFromTexture(EAIcon);
				FirstPartyPlatformIcon.SetBrushFromTexture(SteamIcon);
			break;
			case EHazeOnlineFirstPartyType::Xbox:
				FirstPartyNetworkName.SetText(NSLOCTEXT("LobbyFriend", "XboxNetworkLabel", "Gamertag:"));
				FirstPartyNetworkName.SetVisibility(ESlateVisibility::HitTestInvisible);
				FirstPartyIdWidget.SetText(LanGame.FirstPartyNickname);
				FirstPartyIdBox.Visibility = ESlateVisibility::Visible;
				PrimaryPlatformIcon.SetBrushFromTexture(EAIcon);

				if (Game::PlatformName == "XSX")
					FirstPartyPlatformIcon.SetBrushFromTexture(XboxIcon);
				else
					FirstPartyPlatformIcon.SetBrushFromTexture(GenericConsoleIcon);
			break;
			case EHazeOnlineFirstPartyType::Playstation:
				FirstPartyNetworkName.SetText(FText());
				FirstPartyNetworkName.SetVisibility(ESlateVisibility::Collapsed);
				FirstPartyIdWidget.SetText(LanGame.FirstPartyNickname);
				FirstPartyIdBox.Visibility = ESlateVisibility::Visible;
				PrimaryPlatformIcon.SetBrushFromTexture(EAIcon);

				if (Game::PlatformName == "PS5")
					FirstPartyPlatformIcon.SetBrushFromTexture(PlaystationIcon);
				else
					FirstPartyPlatformIcon.SetBrushFromTexture(GenericConsoleIcon);
			break;
			case EHazeOnlineFirstPartyType::Sage:
				FirstPartyNetworkName.SetText(FText());
				FirstPartyNetworkName.SetVisibility(ESlateVisibility::Collapsed);
				FirstPartyIdWidget.SetText(LanGame.FirstPartyNickname);
				FirstPartyIdBox.Visibility = ESlateVisibility::Visible;
				PrimaryPlatformIcon.SetBrushFromTexture(EAIcon);

				if (Game::PlatformName == "Sage")
					FirstPartyPlatformIcon.SetBrushFromTexture(SageIcon);
				else
					FirstPartyPlatformIcon.SetBrushFromTexture(GenericConsoleIcon);
			break;
			case EHazeOnlineFirstPartyType::None:
			case EHazeOnlineFirstPartyType::Origin:
				PrimaryPlatformIcon.SetBrushFromTexture(EAIcon);
				FirstPartyIdBox.Visibility = ESlateVisibility::Hidden;
			break;
		}

		if (bPressed)
		{
			SelectionHighlight.SetRenderTranslation(FVector2D(3, 3));
			ContentBox.SetRenderTranslation(FVector2D(3, 3));
		}
		else
		{
			SelectionHighlight.SetRenderTranslation(FVector2D(0, 0));
			ContentBox.SetRenderTranslation(FVector2D(0, 0));
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		// Update on tick for now, might want to do something else later
		Update();
	}

	UFUNCTION(BlueprintPure)
	bool IsHoveredOrActive()
	{
		if (Lobby::GetMostLikelyControllerType() == EHazePlayerControllerType::Keyboard)
		{
			if (bHovered || (bFocused && !bFocusedByMouse))
				return true;
		}
		else
		{
			if (bFocused)
				return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		bFocused = true;
		bFocusedByMouse = (InFocusEvent.Cause == EFocusCause::Mouse);

		auto LobbyWidget = Cast<ULocalWirelessFindLanGamesWidget>(GetParentWidgetOfClass(ULocalWirelessFindLanGamesWidget));
		LobbyWidget.LanGameList.SetSelectedItem(LanGame);
		if (!bFocusedByMouse)
			LobbyWidget.LanGameList.ScrollItemIntoView(this);

		return FEventReply::Handled();
	}

	UFUNCTION(BlueprintOverride)
	void OnFocusLost(FFocusEvent InFocusEvent)
	{
		bFocused = false;
		bPressed = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseEnter(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseLeave(FPointerEvent MouseEvent)
	{
		bHovered = false;
		bPressed = false;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.GetEffectingButton() == EKeys::LeftMouseButton)
		{
			bPressed = true;
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonUp(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.GetEffectingButton() == EKeys::LeftMouseButton)
		{
			if (bPressed)
				OnShowActions();
			bPressed = false;
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseMove(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.CursorDelta.IsNearlyZero())
			return FEventReply::Unhandled();

		bHovered = true;

		return FEventReply::Unhandled().SetUserFocus(this, EFocusCause::Mouse);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (InKeyEvent.GetKey() == EKeys::Virtual_Accept || InKeyEvent.GetKey() == EKeys::Enter)
		{
			bPressed = true;
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (InKeyEvent.GetKey() == EKeys::Virtual_Accept || InKeyEvent.GetKey() == EKeys::Enter)
		{
			if (bPressed)
				OnShowActions();
			bPressed = false;
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnTouchEnded(FGeometry MyGeometry, const FPointerEvent& InTouchEvent)
	{
		if (Game::PlatformName == "Sage")
		{
			OnShowActions();
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}
}