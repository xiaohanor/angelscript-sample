class ULobbyCrossplayWidget : UMainMenuStateWidget
{
	default bShowMenuBackground = true;
	default bShowButtonBarBackground = true;

	UPROPERTY(BindWidget)
	UListView FriendList;

	UPROPERTY(BindWidget)
	UTextBlock EAAccountNameText;

	UPROPERTY(BindWidget)
	UMenuPromptOrButton BackButton;

	UPROPERTY(BindWidget)
	UMenuPromptOrButton SearchButton;

	UPROPERTY(BindWidget)
	UEditableTextBox SearchInputBox;

	UPROPERTY(BindWidget)
	UWidget SearchOverlayContainer;

	UPROPERTY(BindWidget)
	UWidget FriendListLoadingSpinner;

	UPROPERTY(BindWidget)
	UListView SearchList;

	UPROPERTY(BindWidget)
	UMenuPromptOrButton CloseSearchButton;

	UPROPERTY(BindWidget)
	UMenuPromptOrButton BlockListButton;

	UPROPERTY(BindWidget)
	UMenuPromptOrButton ReportingButton;

	UPROPERTY(BindWidget)
	UWidget BlockListOverlayContainer;

	UPROPERTY(BindWidget)
	UListView BlockList;

	UPROPERTY(BindWidget)
	UMenuPromptOrButton CloseBlockListButton;

	UHazeLobby Lobby;

	TArray<UObject> FriendObjects;
	TArray<UHazeOnlineFriend> Friends;

	bool bAwaitingFocus = false;
	EFocusCause AwaitingFocusCause;
	float RefreshTimer = 0.4;

	TArray<UObject> SearchObjects;
	TArray<UHazeOnlineFriend> SearchFriends;

	TArray<UObject> BlockListObjects;
	TArray<UHazeOnlineFriend> BlockListFriends;

	bool bIsSearching = false;
	bool bIsShowingBlockList = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		BackButton.OnPressed.AddUFunction(this, n"ReturnToLobbyPlayers");
		SearchButton.OnPressed.AddUFunction(this, n"OpenSearch");
		CloseSearchButton.OnPressed.AddUFunction(this, n"CloseSearch");
		SearchInputBox.OnTextChanged.AddUFunction(this, n"OnSearchTextChanged");
		BlockListButton.OnPressed.AddUFunction(this, n"OpenBlockList");
		CloseBlockListButton.OnPressed.AddUFunction(this, n"CloseBlockList");
		ReportingButton.OnPressed.AddUFunction(this, n"OnReportAbuse");

		if (Online::OnlinePlatformName == "PS5")
			ReportingButton.Visibility = ESlateVisibility::Visible;
		else
			ReportingButton.Visibility = ESlateVisibility::Collapsed;
	}

	UFUNCTION()
	private void OnReportAbuse(UHazeUserWidget Widget = nullptr)
	{
		FMessageDialog Message;
		Message.Message = NSLOCTEXT("EAOnline", "ReportingAbusePopupMessage", "To report a player using an EA account, please visit the EA website at https://help.ea.com/en/report-a-player/");
		Message.AddOKOption();

		ShowPopupMessage(Message, this);
	}

	UFUNCTION(BlueprintOverride)
	void Destruct()
	{
		if (bIsSearching)
		{
			Online::StopFriendSearch();
			bIsSearching = false;
		}
	}

	bool ShouldShowSearchInputBox()
	{
		return !Online::RequiresTextInputPrompt();
	}

	bool IsFriendsListLoading()
	{
		return Online::IsFriendsListLoading();
	}

	void OnTransitionEnter(EMainMenuState PreviousState, bool bSnap) override
	{
		Super::OnTransitionEnter(PreviousState, bSnap);
		Lobby = Lobby::GetLobby();

		UpdateWidgetState();
		RefreshFriends();
	}

	void UpdateWidgetState()
	{
	}

	void RefreshFriends()
	{
		EAAccountNameText.SetText(FText::FromString(Online::GetEAUsername()));

		TArray<UHazeOnlineFriend> FriendData;
		Online::GetFriends(FriendData);

		if (FriendData == Friends)
			return;

		// Sort the friends so the most likely ones are at the top
		TArray<FFriendSorter> SortedFriends;

		for (auto Friend : FriendData)
		{
			if (!Friend.bIsFriend && !Friend.bHasReceivedFriendRequest && !Friend.bHasSentFriendRequest)
				continue;
			if (Friend.bIsBlocked)
				continue;

			int DisplayOrder = 0;
			if (!Friend.bIsInJoinableLobby)
				DisplayOrder += 100;
			if (Friend.bHasReceivedFriendRequest || Friend.bHasSentFriendRequest)
				DisplayOrder -= 50;
			if (!Friend.bPlayingThisGame)
				DisplayOrder += 2;
			if (!Friend.bOnline)
				DisplayOrder += 10;
			if (!Friend.bIsFriend)
				DisplayOrder += 2;

			FFriendSorter Sorter;
			Sorter.Friend = Friend;
			Sorter.DisplayOrder = DisplayOrder;
			SortedFriends.Add(Sorter);
		}

		SortedFriends.Sort();

		Friends.Reset();
		FriendObjects.Reset();
		for (auto Friend : SortedFriends)
		{
			FriendObjects.Add(Friend.Friend);
			Friends.Add(Friend.Friend);
		}

		FriendList.SetListItems(FriendObjects);
		FriendList.RequestRefresh();

		auto SelectedFriend = FriendList.GetSelectedItem();
		if (SelectedFriend == nullptr && FriendObjects.Num() != 0)
		{
			FriendList.SetSelectedIndex(0);
			FriendList.ScrollIndexIntoView(0);

			auto SelectedWidget = FriendList.GetEntryWidgetForItemIndex(0);
			if (SelectedWidget != nullptr && !bIsSearching && !bIsShowingBlockList)
				Widget::SetAllPlayerUIFocus(SelectedWidget);
		}
		else
		{
			FriendList.ScrollItemIntoView(SelectedFriend);
		}
	}

	void RefreshSearch()
	{
		TArray<UHazeOnlineFriend> SearchData;
		Online::GetSearchedFriends(SearchData);

		if (ShouldShowSearchInputBox())
			SearchInputBox.Visibility = ESlateVisibility::Visible;
		else
			SearchInputBox.Visibility = ESlateVisibility::Collapsed;

		if (SearchData == SearchFriends)
			return;

		SearchFriends.Reset();
		SearchObjects.Reset();
		for (auto Friend : SearchData)
		{
			SearchFriends.Add(Friend);
			SearchObjects.Add(Friend);
		}

		SearchList.SetListItems(SearchObjects);
		SearchList.RequestRefresh();

		auto SelectedFriend = SearchList.GetSelectedItem();
		if (SelectedFriend == nullptr && SearchObjects.Num() != 0)
		{
			SearchList.SetSelectedIndex(0);
			SearchList.ScrollIndexIntoView(0);

			auto SelectedWidget = SearchList.GetEntryWidgetForItemIndex(0);
			if (SelectedWidget != nullptr)
				Widget::SetAllPlayerUIFocus(SelectedWidget);
		}
		else
		{
			SearchList.ScrollItemIntoView(SelectedFriend);
		}
	}

	void RefreshBlockList()
	{
		TArray<UHazeOnlineFriend> BlockListData;
		Online::GetBlockList(BlockListData);

		if (BlockListData == BlockListFriends)
			return;

		BlockListFriends.Reset();
		BlockListObjects.Reset();
		for (auto Friend : BlockListData)
		{
			BlockListFriends.Add(Friend);
			BlockListObjects.Add(Friend);
		}

		BlockList.SetListItems(BlockListObjects);
		BlockList.RequestRefresh();

		auto SelectedFriend = BlockList.GetSelectedItem();
		if (SelectedFriend == nullptr && BlockListObjects.Num() != 0)
		{
			BlockList.SetSelectedIndex(0);
			BlockList.ScrollIndexIntoView(0);

			auto SelectedWidget = BlockList.GetEntryWidgetForItemIndex(0);
			if (SelectedWidget != nullptr)
				Widget::SetAllPlayerUIFocus(SelectedWidget);
		}
		else
		{
			BlockList.ScrollItemIntoView(SelectedFriend);
		}
	}

	UFUNCTION()
	private void OnSearchTextChanged(const FText&in Text)
	{
		if (bIsSearching)
		{
			Online::StartFriendSearch(Text.ToString());
			RefreshSearch();
			RefreshTimer = 0.4;
		}
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		if (bIsSearching)
		{
			if (ShouldShowSearchInputBox())
			{
				bAwaitingFocus = false;
				return FEventReply::Handled().SetUserFocus(SearchInputBox, InFocusEvent.Cause);
			}

			auto SearchWidgets = SearchList.GetDisplayedEntryWidgets();
			auto SelectedSearchWidget = SearchList.GetSelectedEntryWidget();
			if (SelectedSearchWidget != nullptr)
			{
				bAwaitingFocus = false;
				return FEventReply::Handled().SetUserFocus(SelectedSearchWidget, InFocusEvent.Cause);
			}
			else if (SearchWidgets.Num() != 0 && SearchWidgets[0] != nullptr)
			{
				bAwaitingFocus = false;
				return FEventReply::Handled().SetUserFocus(SearchWidgets[0], InFocusEvent.Cause);
			}
			else
			{
				bAwaitingFocus = true;
				AwaitingFocusCause = InFocusEvent.Cause;
				return FEventReply::Handled();
			}
		}
		else if (bIsShowingBlockList)
		{
			auto BlockListWidgets = BlockList.GetDisplayedEntryWidgets();
			auto SelectedBlockListWidget = BlockList.GetSelectedEntryWidget();
			if (SelectedBlockListWidget != nullptr)
			{
				bAwaitingFocus = false;
				return FEventReply::Handled().SetUserFocus(SelectedBlockListWidget, InFocusEvent.Cause);
			}
			else if (BlockListWidgets.Num() != 0 && BlockListWidgets[0] != nullptr)
			{
				bAwaitingFocus = false;
				return FEventReply::Handled().SetUserFocus(BlockListWidgets[0], InFocusEvent.Cause);
			}
			else
			{
				bAwaitingFocus = true;
				AwaitingFocusCause = InFocusEvent.Cause;
				return FEventReply::Handled();
			}

		}
		else
		{
			auto Widgets = FriendList.GetDisplayedEntryWidgets();
			auto SelectedWidget = FriendList.GetSelectedEntryWidget();
			if (SelectedWidget != nullptr && !IsFriendsListLoading())
			{
				bAwaitingFocus = false;
				return FEventReply::Handled().SetUserFocus(SelectedWidget, InFocusEvent.Cause);
			}
			else if (Widgets.Num() != 0 && Widgets[0] != nullptr && !IsFriendsListLoading())
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
			if (bIsSearching)
			{
				if (ShouldShowSearchInputBox())
				{
					Widget::SetAllPlayerUIFocus(SearchInputBox, AwaitingFocusCause);
					bAwaitingFocus = false;
				}
				else
				{
					auto Widgets = SearchList.GetDisplayedEntryWidgets();
					if (Widgets.Num() != 0 && Widgets[0] != nullptr)
					{
						Widget::SetAllPlayerUIFocus(Widgets[0], AwaitingFocusCause);
						bAwaitingFocus = false;
					}
				}
			}
			else if (bIsShowingBlockList)
			{
				auto Widgets = BlockList.GetDisplayedEntryWidgets();
				if (Widgets.Num() != 0 && Widgets[0] != nullptr)
				{
					Widget::SetAllPlayerUIFocus(Widgets[0], AwaitingFocusCause);
					bAwaitingFocus = false;
				}
			}
			else if (!IsFriendsListLoading())
			{
				auto Widgets = FriendList.GetDisplayedEntryWidgets();
				if (Widgets.Num() != 0 && Widgets[0] != nullptr)
				{
					Widget::SetAllPlayerUIFocus(Widgets[0], AwaitingFocusCause);
					bAwaitingFocus = false;
				}
			}
		}

		if (bIsSearching && SearchList.HasAnyUserFocus())
		{
			auto Widgets = SearchList.GetDisplayedEntryWidgets();
			if (Widgets.Num() != 0 && Widgets[0] != nullptr)
			{
				Widget::SetAllPlayerUIFocus(Widgets[0], AwaitingFocusCause);
				bAwaitingFocus = false;
			}
		}
	}

	UFUNCTION()
	void ReturnToLobbyPlayers(UHazeUserWidget Widget = nullptr)
	{
		Lobby::Menu_LobbySetState(EHazeLobbyState::LobbyPlayers);
		MainMenu.GotoLobbyPlayers();
	}

	UFUNCTION()
	void OpenSearch(UHazeUserWidget Widget = nullptr)
	{
		if (Online::RequiresTextInputPrompt())
		{
			FText PromptTitle;
			FText PromptDescription;
			if (Online::OnlinePlatformName == "Sage")
			{
				// Nintendo needs different localizations for these terms
				PromptTitle = NSLOCTEXT("EAOnline", "SearchFriendPromptTitle_Sage", "Search for Friends");
				PromptDescription = NSLOCTEXT("EAOnline", "SearchFriendPromptDescription_Sage", "Enter the EA account name of a friend");
			}
			else
			{
				PromptTitle = NSLOCTEXT("EAOnline", "SearchFriendPromptTitle", "Search for Friends");
				PromptDescription = NSLOCTEXT("EAOnline", "SearchFriendPromptDescription", "Enter the EA account name of a friend");
			}
			Online::PromptTextInput(
				PromptTitle,
				PromptDescription,
				FHazeOnOnlineSystemTextInput(this, n"OnSearchPromptInput")
			);
		}
		else
		{
			ShowSearchDialog(SearchInputBox.GetText().ToString());
		}
	}

	UFUNCTION()
	void OnSearchPromptInput(FString SearchText)
	{
		if (!SearchText.IsEmpty())
			ShowSearchDialog(SearchText);
	}

	UFUNCTION()
	void ShowSearchDialog(FString SearchText)
	{
		Online::StartFriendSearch(SearchText);
		SearchInputBox.SetText(FText::FromString(SearchText));
		bIsSearching = true;

		RefreshSearch();
		RefreshTimer = 0.4;

		SearchOverlayContainer.Visibility = ESlateVisibility::Visible;
		bAwaitingFocus = true;
		AwaitingFocusCause = EFocusCause::SetDirectly;
		Widget::SetAllPlayerUIFocus(this);
	}

	UFUNCTION()
	void CloseSearch(UHazeUserWidget Widget = nullptr)
	{
		Online::StopFriendSearch();
		bIsSearching = false;

		SearchOverlayContainer.Visibility = ESlateVisibility::Hidden;
		bAwaitingFocus = true;
		AwaitingFocusCause = EFocusCause::SetDirectly;
		Widget::SetAllPlayerUIFocus(this);
	}

	UFUNCTION()
	void OpenBlockList(UHazeUserWidget Widget = nullptr)
	{
		bIsShowingBlockList = true;

		RefreshBlockList();
		RefreshTimer = 0.4;

		BlockListOverlayContainer.Visibility = ESlateVisibility::Visible;
		bAwaitingFocus = true;
		AwaitingFocusCause = EFocusCause::SetDirectly;
		Widget::SetAllPlayerUIFocus(this);
	}

	UFUNCTION()
	void CloseBlockList(UHazeUserWidget Widget = nullptr)
	{
		bIsShowingBlockList = false;

		BlockListOverlayContainer.Visibility = ESlateVisibility::Hidden;
		bAwaitingFocus = true;
		AwaitingFocusCause = EFocusCause::SetDirectly;
		Widget::SetAllPlayerUIFocus(this);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		// If the console is up, don't eat the key input
		if (Console::IsConsoleActive() || Console::IsConsoleKey(Event.Key))
			return FEventReply::Unhandled();
		if (Lobby == nullptr || Lobby.HasGameStarted())
			return FEventReply::Unhandled();
		if (Event.IsRepeat())
			return FEventReply::Unhandled();
		if (!bIsActive)
			return FEventReply::Handled();

		UHazePlayerIdentity KeyIdentity = Online::GetLocalIdentityAssociatedWithInputDevice(Event.InputDeviceId);
		UHazePlayerIdentity KeyIdentityInLobby = Lobby.GetIdentityForInput(Event.InputDeviceId);

		if (MainMenu.OwnerIdentity.TakesInputFromController(Event.InputDeviceId))
		{
			if (bIsSearching)
			{
				if (Event.Key == EKeys::Escape || Event.Key == EKeys::Virtual_Back)
				{
					CloseSearch();
					return FEventReply::Handled();
				}
			}
			else if (bIsShowingBlockList)
			{
				if (Event.Key == EKeys::Escape || Event.Key == EKeys::Virtual_Back)
				{
					CloseBlockList();
					return FEventReply::Handled();
				}
			}
			else
			{
				if (Event.Key == EKeys::Escape || Event.Key == EKeys::Virtual_Back)
				{
					ReturnToLobbyPlayers();
					return FEventReply::Handled();
				}
				else if (Event.Key == EKeys::Gamepad_FaceButton_Top || Event.Key == EKeys::F1)
				{
					OpenSearch();
					return FEventReply::Handled();
				}
				else if (Event.Key == EKeys::Gamepad_LeftShoulder || Event.Key == EKeys::F2)
				{
					OpenBlockList();
					return FEventReply::Handled();
				}
				else if (Event.Key == EKeys::Gamepad_RightShoulder && ReportingButton.IsVisible())
				{
					OnReportAbuse();
					return FEventReply::Handled();
				}
			}
		}

		return Super::OnKeyDown(Geom, Event);
	}

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	void Tick(FGeometry Geometry, float DeltaTime)
	{
		Super::Tick(Geometry, DeltaTime);

		if (Lobby == nullptr)
			return;

		UpdateWidgetState();
		UpdateFocus();
		
		RefreshTimer -= DeltaTime;
		if (RefreshTimer < 0.0)
		{
			RefreshFriends();

			if (bIsSearching)
				RefreshSearch();
			if (bIsShowingBlockList)
				RefreshBlockList();

			RefreshTimer = 1.0;
		}

		if (IsFriendsListLoading())
		{
			FriendListLoadingSpinner.Visibility = ESlateVisibility::HitTestInvisible;
			FriendList.Visibility = ESlateVisibility::Hidden;
		}
		else
		{
			FriendListLoadingSpinner.Visibility = ESlateVisibility::Hidden;
			FriendList.Visibility = ESlateVisibility::Visible;
		}

		// We only leave this screen once we are at character select,
		// this can happen if a guest is looking at crossplay while already connected to
		// someone else, and the host goes into character select.
		switch (Lobby.LobbyState)
		{
			case EHazeLobbyState::CharacterSelect:
				MainMenu.GotoCharacterSelect();
			break;
			default:
			break;
		}
	}
};

struct FFriendSorter
{
	UHazeOnlineFriend Friend;
	int DisplayOrder = 0;

	int opCmp(const FFriendSorter& Other) const
	{
		if (DisplayOrder < Other.DisplayOrder)
			return -1;
		else if (DisplayOrder > Other.DisplayOrder)
			return 1;
		else
			return 0;
	}
}

class ULobbyFriendWidget : UHazeUserWidget
{
	UHazeOnlineFriend Friend;

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

	private UHazeOnlineFriend PendingActionFriend;

	UFUNCTION()
	void SetEntryData(UObject InFriend)
	{
		Friend = Cast<UHazeOnlineFriend>(InFriend);
		Update();
	}

	UFUNCTION()
	private void OnShowActions()
	{
		PendingActionFriend = Friend;

		FMessageDialog Dialog;
		Dialog.Message = Friend.Nickname;
		Dialog.bInstantCloseOnCancel = true;

		FText AcceptLabel;
		FText DeclineLabel;
		FText CancelLabel;
		FText RemoveLabel;
		FText SendLabel;
		
		if (Online::OnlinePlatformName == "Sage")
		{
			// Nintendo needs different localizations for these terms
			AcceptLabel = NSLOCTEXT("LobbyFriend", "AcceptFriendRequest_Sage", "Accept Friend Request");
			DeclineLabel = NSLOCTEXT("LobbyFriend", "DeclineFriendRequest_Sage", "Decline Friend Request");
			CancelLabel = NSLOCTEXT("LobbyFriend", "CancelSentFriendRequest_Sage", "Cancel Friend Request");
			RemoveLabel = NSLOCTEXT("LobbyFriend", "RemoveFriend_Sage", "Unfriend");
			SendLabel = NSLOCTEXT("LobbyFriend", "SendFriendRequest_Sage", "Send Friend Request");
		}
		else
		{
			AcceptLabel = NSLOCTEXT("LobbyFriend", "AcceptFriendRequest", "Accept Friend Request");
			DeclineLabel = NSLOCTEXT("LobbyFriend", "DeclineFriendRequest", "Decline Friend Request");
			CancelLabel = NSLOCTEXT("LobbyFriend", "CancelSentFriendRequest", "Cancel Friend Request");
			RemoveLabel = NSLOCTEXT("LobbyFriend", "RemoveFriend", "Unfriend");
			SendLabel = NSLOCTEXT("LobbyFriend", "SendFriendRequest", "Send Friend Request");
		}

		if (Friend.bIsInJoinableLobby && Friend.bIsFriend)
		{
			Dialog.AddOption(
				NSLOCTEXT("LobbyFriend", "JoinLobby", "Join Online Lobby"),
				FOnMessageDialogOptionChosen(this, n"Action_JoinLobby")
			);
		}

		if (Friend.bIsFriend)
		{
			if (Friend.FirstPartyType == EHazeOnlineFirstPartyType::Steam && !Friend.bIsFirstPartyOnlyFriend)
			{
				Dialog.AddOption(
					NSLOCTEXT("LobbyFriend", "InviteFriend_Steam", "Send Game Invite (Steam)"),
					FOnMessageDialogOptionChosen(this, n"Action_InviteFriend")
				);

				Dialog.AddOption(
					NSLOCTEXT("LobbyFriend", "InviteFriend_EA", "Send Game Invite (EA)"),
					FOnMessageDialogOptionChosen(this, n"Action_InviteFriend_EA")
				);
			}
			else
			{
				Dialog.AddOption(
					NSLOCTEXT("LobbyFriend", "InviteFriend", "Send Game Invite"),
					FOnMessageDialogOptionChosen(this, n"Action_InviteFriend")
				);
			}
		}

		if (Friend.bHasReceivedFriendRequest)
		{
			Dialog.AddOption(
				AcceptLabel,
				FOnMessageDialogOptionChosen(this, n"Action_AcceptFriendRequest")
			);
			Dialog.AddOption(
				DeclineLabel,
				FOnMessageDialogOptionChosen(this, n"Action_DeclineFriendRequest")
			);
		}

		if (Friend.bHasSentFriendRequest)
		{
			Dialog.AddOption(
				CancelLabel,
				FOnMessageDialogOptionChosen(this, n"Action_CancelSentFriendRequest")
			);
		}

		if (Online::CanShowFriendFirstPartyProfile(Friend))
		{
			if (Friend.FirstPartyType == EHazeOnlineFirstPartyType::Xbox)
			{
				Dialog.AddOption(
					NSLOCTEXT("LobbyFriend", "ShowXboxProfile", "Show Gamercard"),
					FOnMessageDialogOptionChosen(this, n"Action_ShowProfile")
				);
			}
		}

		if (Friend.bIsBlocked)
		{
			Dialog.AddOption(
				NSLOCTEXT("LobbyFriend", "UnblockFriend", "Unblock"),
				FOnMessageDialogOptionChosen(this, n"Action_Unblock")
			);
		}
		else if (Friend.bIsFriend)
		{
			Dialog.AddOption(
				NSLOCTEXT("LobbyFriend", "BlockFriend", "Block"),
				FOnMessageDialogOptionChosen(this, n"Action_Block")
			);
		}

		if (Friend.bIsFriend)
		{
			Dialog.AddOption(
				RemoveLabel,
				FOnMessageDialogOptionChosen(this, n"Action_Unfriend")
			);
		}

		if (!Friend.bIsFriend && !Friend.bHasReceivedFriendRequest && !Friend.bHasSentFriendRequest)
		{
			Dialog.AddOption(
				SendLabel,
				FOnMessageDialogOptionChosen(this, n"Action_SendFriendRequest")
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
	private void Action_ShowProfile()
	{
		Online::ShowFriendFirstPartyProfile(PendingActionFriend);
	}

	UFUNCTION()
	private void Action_InviteFriend()
	{
		Online::SendGameInviteToFriend(PendingActionFriend, true);
	}

	UFUNCTION()
	private void Action_InviteFriend_EA()
	{
		Online::SendGameInviteToFriend(PendingActionFriend, false);
	}

	UFUNCTION()
	private void Action_Unfriend()
	{
		FMessageDialog Dialog;
		FText RemoveLabel;
		if (Online::OnlinePlatformName == "Sage")
		{
			// Nintendo needs different localizations for these terms
			Dialog.Message = NSLOCTEXT("LobbyFriend", "UnfriendQuestion_Sage", "Remove {0} from friends list?");
			RemoveLabel = NSLOCTEXT("LobbyFriend", "RemoveFriend_Sage", "Unfriend");
		}
		else
		{
			Dialog.Message = NSLOCTEXT("LobbyFriend", "UnfriendQuestion", "Remove {0} from friends list?");
			RemoveLabel = NSLOCTEXT("LobbyFriend", "RemoveFriend", "Unfriend");
		}
		
		Dialog.Message = FText::FromString(Dialog.Message.ToString().Replace("{0}", PendingActionFriend.Nickname.ToString()));
		Dialog.AddOption(RemoveLabel, FOnMessageDialogOptionChosen(this, n"Confirm_Unfriend"));
		Dialog.AddCancelOption();

		ShowPopupMessage(Dialog, this);
	}

	UFUNCTION()
	private void Confirm_Unfriend()
	{
		Online::RemoveFriend(PendingActionFriend);
	}

	UFUNCTION()
	private void Action_SendFriendRequest()
	{
		Online::SendFriendRequest(PendingActionFriend);

		// If we sent a friend request from a search popup, close the search popup
		auto LobbyWidget = Cast<ULobbyCrossplayWidget>(GetParentWidgetOfClass(ULobbyCrossplayWidget));
		if (LobbyWidget.bIsSearching)
			LobbyWidget.CloseSearch();
	}

	UFUNCTION()
	private void Action_Block()
	{
		FMessageDialog Dialog;
		if (Online::OnlinePlatformName == "Origin")
			Dialog.Message = NSLOCTEXT("LobbyFriend", "BlockQuestion", "Block {0}?");
		else
			Dialog.Message = NSLOCTEXT("LobbyFriend", "BlockQuestion_Platform", "Block {0}? You might also need to block at the platform level.");
		Dialog.Message = FText::FromString(Dialog.Message.ToString().Replace("{0}", PendingActionFriend.Nickname.ToString()));
		Dialog.AddOption(NSLOCTEXT("LobbyFriend", "BlockFriend", "Block"), FOnMessageDialogOptionChosen(this, n"Confirm_Block"));
		Dialog.AddCancelOption();

		ShowPopupMessage(Dialog, this);
	}

	UFUNCTION()
	private void Confirm_Block()
	{
		Online::SetFriendBlocked(PendingActionFriend, true);
	}

	UFUNCTION()
	private void Action_Unblock()
	{
		Online::SetFriendBlocked(PendingActionFriend, false);
	}

	UFUNCTION()
	private void Action_CancelSentFriendRequest()
	{
		Online::CancelFriendRequest(PendingActionFriend);
	}

	UFUNCTION()
	private void Action_DeclineFriendRequest()
	{
		Online::RespondToFriendRequest(PendingActionFriend, false);
	}

	UFUNCTION()
	private void Action_AcceptFriendRequest()
	{
		Online::RespondToFriendRequest(PendingActionFriend, true);
	}

	UFUNCTION()
	private void Action_JoinLobby()
	{
		Online::JoinFriendLobby(PendingActionFriend);
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
		NameWidget.SetText(Friend.Nickname);

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

		if (Friend.bIsBlocked)
		{
			StateWidget.SetText(NSLOCTEXT("LobbyFriend", "BlockedState", "Blocked"));
			StateWidget.SetColorAndOpacity(FLinearColor::White);
		}
		else if (Friend.bHasSentFriendRequest)
		{
			if (Online::OnlinePlatformName == "Sage")
			{
				StateWidget.SetText(NSLOCTEXT("LobbyFriend", "FriendRequestSent_Sage", "Sent Friend Request"));
			}
			else
			{
				StateWidget.SetText(NSLOCTEXT("LobbyFriend", "FriendRequestSent", "Sent Friend Request"));
			}
			StateWidget.SetColorAndOpacity(FLinearColor::White);
		}
		else if (Friend.bHasReceivedFriendRequest)
		{
			if (Online::OnlinePlatformName == "Sage")
			{
				StateWidget.SetText(NSLOCTEXT("LobbyFriend", "FriendRequestReceived_Sage", "Received Friend Request"));
			}
			else
			{
				StateWidget.SetText(NSLOCTEXT("LobbyFriend", "FriendRequestReceived", "Received Friend Request"));
			}
			StateWidget.SetColorAndOpacity(FLinearColor::White);
		}
		else if (!Friend.bIsFriend)
		{
			if (Online::OnlinePlatformName == "Sage")
			{
				StateWidget.SetText(NSLOCTEXT("LobbyFriend", "NotFriendState_Sage", "Not Friends"));
			}
			else
			{
				StateWidget.SetText(NSLOCTEXT("LobbyFriend", "NotFriendState", "Not Friends"));
			}
			StateWidget.SetColorAndOpacity(FLinearColor::White);
		}
		else if (Friend.bIsInJoinableLobby)
		{
			StateWidget.SetText(NSLOCTEXT("LobbyFriend", "ThisGameStateLobby", "Split Fiction - Online Lobby"));
			StateWidget.SetColorAndOpacity(FLinearColor(1.00, 0.98, 0.17));
		}
		else if (Friend.bPlayingOtherGame)
		{
			StateWidget.SetText(NSLOCTEXT("LobbyFriend", "OtherGameState", "Playing Other Game"));
			StateWidget.SetColorAndOpacity(FLinearColor::White);
		}
		else if (Friend.bPlayingThisGame)
		{
			StateWidget.SetText(NSLOCTEXT("LobbyFriend", "ThisGameState", "Playing Split Fiction"));
			StateWidget.SetColorAndOpacity(FLinearColor(1.00, 0.98, 0.17));
		}
		else if (Friend.bOnline)
		{
			StateWidget.SetText(NSLOCTEXT("LobbyFriend", "OnlineState", "Online"));
			StateWidget.SetColorAndOpacity(FLinearColor(0.56, 0.55, 0.11));
		}
		else
		{
			if (Friend.FirstPartyType != EHazeOnlineFirstPartyType::Steam)
			{
				// An EA-only friend doesn't show the Offline text, because EA presence doesn't work that way
				StateWidget.SetText(FText());
			}
			else
			{
				StateWidget.SetText(NSLOCTEXT("LobbyFriend", "OfflineState", "Offline"));
				StateWidget.SetColorAndOpacity(FLinearColor(0.7, 0.7, 0.7));
			}
		}

		switch (Friend.FirstPartyType)
		{
			case EHazeOnlineFirstPartyType::Steam:
				if (Friend.bIsFirstPartyOnlyFriend)
				{
					FirstPartyIdBox.Visibility = ESlateVisibility::Hidden;
					PrimaryPlatformIcon.SetBrushFromTexture(SteamIcon);
				}
				else
				{
					FirstPartyNetworkName.SetText(NSLOCTEXT("LobbyFriend", "SteamNetworkLabel", "Steam:"));
					FirstPartyNetworkName.SetVisibility(ESlateVisibility::HitTestInvisible);
					FirstPartyIdWidget.SetText(Friend.FirstPartyNickname);
					FirstPartyIdBox.Visibility = ESlateVisibility::Visible;

					PrimaryPlatformIcon.SetBrushFromTexture(EAIcon);
					FirstPartyPlatformIcon.SetBrushFromTexture(SteamIcon);
				}
			break;
			case EHazeOnlineFirstPartyType::Xbox:
				FirstPartyNetworkName.SetText(NSLOCTEXT("LobbyFriend", "XboxNetworkLabel", "Gamertag:"));
				FirstPartyNetworkName.SetVisibility(ESlateVisibility::HitTestInvisible);
				FirstPartyIdWidget.SetText(Friend.FirstPartyNickname);
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
				FirstPartyIdWidget.SetText(Friend.FirstPartyNickname);
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
				FirstPartyIdWidget.SetText(Friend.FirstPartyNickname);
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

		auto LobbyWidget = Cast<ULobbyCrossplayWidget>(GetParentWidgetOfClass(ULobbyCrossplayWidget));
		if (LobbyWidget.bIsSearching)
		{
			LobbyWidget.SearchList.SetSelectedItem(Friend);
			if (!bFocusedByMouse)
				LobbyWidget.SearchList.ScrollItemIntoView(this);
		}
		else if (LobbyWidget.bIsShowingBlockList)
		{
			LobbyWidget.BlockList.SetSelectedItem(Friend);
			if (!bFocusedByMouse)
				LobbyWidget.BlockList.ScrollItemIntoView(this);
		}
		else
		{
			LobbyWidget.FriendList.SetSelectedItem(Friend);
			if (!bFocusedByMouse)
				LobbyWidget.FriendList.ScrollItemIntoView(this);
		}

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

		auto LobbyWidget = Cast<ULobbyCrossplayWidget>(GetParentWidgetOfClass(ULobbyCrossplayWidget));
		if (LobbyWidget.SearchInputBox.HasAnyUserFocus())
			return FEventReply::Unhandled();
		else
			return FEventReply::Unhandled().SetUserFocus(this, EFocusCause::Mouse);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (InKeyEvent.IsRepeat())
			return FEventReply::Unhandled();

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
		if (InKeyEvent.IsRepeat())
			return FEventReply::Unhandled();

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