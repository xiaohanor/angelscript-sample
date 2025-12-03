class UGlobalMenuOverlayWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UVerticalBox GameInviteList;
	UPROPERTY()
	TSubclassOf<UHazeUserWidget> DebugInfoWidget;
	UPROPERTY(BindWidget)
	UTextBlock TimerText;

	UPROPERTY()
	TSubclassOf<UGameInviteWidget> InviteWidgetClass;
	UPROPERTY()
	TArray<UGameInviteWidget> InviteWidgets;

	UFUNCTION(BlueprintOverride)
	void OnAdded()
	{
		SetWidgetZOrderInLayer(9001);

#if TEST
		if(DebugInfoWidget.IsValid())
		{
			auto InfoWidget = Widget::AddFullscreenWidget(DebugInfoWidget, EHazeWidgetLayer::Dev);	
			InfoWidget.SetWidgetPersistent(true);
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float Timer)
	{
		/** Update widgets for game invites */
		UpdateInviteWidgets(Timer);
		UpdateTimer();
	}

	bool bHaveTriggeredInvite = false;
	FString TriggeredInviteId;

	void UpdateInviteWidgets(float DeltaTime)
	{
		/** Update widgets for game invites */
		TArray<FHazeOnlineGameInvite> ActiveInvites;
		if (Online::GetPrimaryIdentity() != nullptr)
			Online::GetReceivedGameInvites(ActiveInvites);

		// Remove widgets for invites that have expired
		for (int i = ActiveInvites.Num(), Count = InviteWidgets.Num(); i < Count; ++i)
			InviteWidgets[i].RemoveFromParent();
		InviteWidgets.SetNum(ActiveInvites.Num());

		// Update invites that have been received
		for (int i= 0, Count = ActiveInvites.Num(); i < Count; ++i)
		{
			if (InviteWidgets[i] == nullptr)
			{
				InviteWidgets[i] = Cast<UGameInviteWidget>(
					Widget::CreateWidget(this, InviteWidgetClass.Get())
				);
				GameInviteList.AddChild(InviteWidgets[i]);
			}

			InviteWidgets[i].Invite = ActiveInvites[i];
			InviteWidgets[i].Update();

			if (bHaveTriggeredInvite)
				InviteWidgets[i].Visibility = ESlateVisibility::Hidden;
			else
				InviteWidgets[i].Visibility = ESlateVisibility::SelfHitTestInvisible;

			// If the invite was triggered, show a popup message to answer it
			if (ActiveInvites[i].bIsTriggered && !bHaveTriggeredInvite)
			{
				TriggeredInviteId = ActiveInvites[i].InviteId;
				bHaveTriggeredInvite = true;

				FMessageDialog Dialog;
				Dialog.Message = NSLOCTEXT("GameInvite", "AnswerPrompt", "Accept game invitation to join Split Fiction online lobby?");
				Dialog.AddOption(
					NSLOCTEXT("GameInvite", "AcceptOption", "Accept Invitation"),
					FOnMessageDialogOptionChosen(this, n"OnAnswerInviteAccept")
				);
				Dialog.AddOption(
					NSLOCTEXT("GameInvite", "DeclineOption", "Decline Invitation"),
					FOnMessageDialogOptionChosen(this, n"OnAnswerInviteDecline"),
					EMessageDialogOptionType::Cancel
				);
				ShowPopupMessage(Dialog, this);
			}
		}
	}

	UFUNCTION()
	private void OnAnswerInviteDecline()
	{
		Online::RespondToGameInvite(TriggeredInviteId, false);
		bHaveTriggeredInvite = false;
	}

	UFUNCTION()
	private void OnAnswerInviteAccept()
	{
		Online::RespondToGameInvite(TriggeredInviteId, true);
		bHaveTriggeredInvite = false;
	}

	void UpdateTimer()
	{
		UGlobalMenuSingleton MenuSingleton = Game::GetSingleton(UGlobalMenuSingleton);
		if (!Lobby::HasGameStarted())
		{
			MenuSingleton.GameSessionTimer = 0.0;
			MenuSingleton.CurrentChapterTimer = 0.0;
			MenuSingleton.PreviousChapterTimer = 0.0;
			MenuSingleton.CurrentChapterRef = FHazeProgressPointRef();
			MenuSingleton.CurrentChapter.Empty();
			MenuSingleton.PreviousChapter.Empty();
			MenuSingleton.bGameIsLoading = false;
		}
		else if (!Game::IsInLoadingScreen())
		{
			MenuSingleton.bGameIsLoading = false;

			FHazeProgressPointRef CurrentChapterRef;
			FHazeProgressPointRef CurrentSaveRef;
			Save::GetSaveToRestart(CurrentChapterRef, CurrentSaveRef);

			if (CurrentChapterRef.Name != MenuSingleton.CurrentChapterRef.Name
				|| CurrentChapterRef.InLevel != MenuSingleton.CurrentChapterRef.InLevel)
			{
				if (!MenuSingleton.CurrentChapterRef.Name.IsEmpty())
				{
					MenuSingleton.PreviousChapter = MenuSingleton.CurrentChapter;
					MenuSingleton.PreviousChapterTimer = MenuSingleton.CurrentChapterTimer;

				}

				MenuSingleton.CurrentChapterRef = CurrentChapterRef;
				MenuSingleton.CurrentChapter = UHazeChapterDatabase::GetChapterDatabase().GetChapterByProgressPoint(CurrentChapterRef).Name.ToString();
				MenuSingleton.CurrentChapterTimer = 0.0;
			}

			MenuSingleton.GameSessionTimer += Time::GetRealDeltaSeconds();
			MenuSingleton.CurrentChapterTimer += Time::GetRealDeltaSeconds();
		}
		else
		{
			MenuSingleton.bGameIsLoading = true;
		}

		if (MenuSingleton.bDisplayTimer)
		{
			TimerText.Visibility = ESlateVisibility::HitTestInvisible;

			FString TimerString = FormatTimer(MenuSingleton.GameSessionTimer);
			if (!MenuSingleton.CurrentChapter.IsEmpty())
				TimerString += f"\n{MenuSingleton.CurrentChapter}\t{FormatTimer(MenuSingleton.CurrentChapterTimer)}";
			if (!MenuSingleton.PreviousChapter.IsEmpty())
				TimerString += f"\n{MenuSingleton.PreviousChapter}\t{FormatTimer(MenuSingleton.PreviousChapterTimer)}";

			FText TimeStringText = FText::FromString(TimerString);
			TimerText.SetText(TimeStringText);
		}
		else
		{
			TimerText.Visibility = ESlateVisibility::Collapsed;
		}
	}

	FString FormatTimer(float Seconds) const
	{
		FTimespan Span = FTimespan::FromSeconds(Seconds);
		FString SpanString;
		if (Span.Hours > 0)
			SpanString = Span.ToString("%h:%m:%s.%f");
		else
			SpanString = Span.ToString("%m:%s.%f");
		SpanString = SpanString.Mid(1, SpanString.Len()-2);
		return SpanString;
	}
}

class UGlobalMenuSingleton : UHazeSingleton
{
	uint64 Padding = 0xff998701107899ff;
	bool bDisplayTimer = false;
	float GameSessionTimer = 0.0;
	float CurrentChapterTimer = 0.0;
	float PreviousChapterTimer = 0.0;
	bool bGameIsLoading = false;

	FString CurrentChapter;
	FString PreviousChapter;
	FHazeProgressPointRef CurrentChapterRef;

	UFUNCTION(BlueprintOverride)
	void Initialize()
	{
		uint64 Mask = 0x0010100000010100;
		Padding ^= Mask;
	}

	UFUNCTION(NetFunction)
	void NetResetTimers()
	{
		GameSessionTimer = 0.0;
		PreviousChapterTimer = 0.0;
		CurrentChapterRef = FHazeProgressPointRef();
		CurrentChapter.Empty();
		PreviousChapter.Empty();
	}
}

class UGameInviteWidget : UHazeUserWidget
{
	FHazeOnlineGameInvite Invite;

	UPROPERTY(BindWidget)
	UTextBlock InviteText;

	UPROPERTY(BindWidget)
	UImage FriendPlatformIcon;
	UPROPERTY(BindWidget)
	UTextBlock FriendNameText;

	UPROPERTY(BindWidget)
	UWidget KeyPromptRow;
	UPROPERTY(BindWidget)
	UWidget MouseButtonRow;
	UPROPERTY(BindWidget)
	UMenuPromptOrButton DeclineButton;
	UPROPERTY(BindWidget)
	UMenuPromptOrButton AcceptButton;
	UPROPERTY(BindWidget)
	UProgressBar ProgressTimer;

	UPROPERTY()
	UTexture2D EAIcon;
	UPROPERTY()
	UTexture2D PlaystationIcon;
	UPROPERTY()
	UTexture2D XboxIcon;
	UPROPERTY()
	UTexture2D SageIcon;

	UPROPERTY(Category="Sounds")
	FSoundDefReference SoundDefReference;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		// AcceptButton.bTriggerOnMouseDown = true;
		// DeclineButton.bTriggerOnMouseDown = true;

		DeclineButton.OnPressed.AddUFunction(this, n"OnDeclinePressed");
		AcceptButton.OnPressed.AddUFunction(this, n"OnAcceptPressed");

		Menu::AttachSoundDef(SoundDefReference, this);
	}

	UFUNCTION(BlueprintOverride)
	void Destruct()
	{
		Menu::RemoveSoundDef(SoundDefReference, this);
	}

	UFUNCTION()
	void OnDeclinePressed(UHazeUserWidget Widget = nullptr)
	{
		Online::RespondToGameInvite(Invite.InviteId, false);
	}

	UFUNCTION()
	void OnAcceptPressed(UHazeUserWidget Widget = nullptr)
	{
		Online::RespondToGameInvite(Invite.InviteId, true);
	}

	void Update()
	{
		FriendNameText.Text = Invite.FriendName;

		if (Game::IsConsoleBuild())
		{
			if (Invite.bFriendNameIsEAId)
			{
				FriendPlatformIcon.Visibility = ESlateVisibility::Visible;
				FriendPlatformIcon.SetBrushFromTexture(EAIcon);
			}
			else
			{
				FriendPlatformIcon.Visibility = ESlateVisibility::Visible;
				if (Game::PlatformName == "PS5")
					FriendPlatformIcon.SetBrushFromTexture(PlaystationIcon);
				else if (Game::PlatformName == "XSX")
					FriendPlatformIcon.SetBrushFromTexture(XboxIcon);
				else if (Game::PlatformName == "Sage")
					FriendPlatformIcon.SetBrushFromTexture(SageIcon);
				else
					FriendPlatformIcon.SetBrushFromTexture(EAIcon);
			}
		}
		else
		{
			if (Online::OnlinePlatformName == "Steam" && Invite.bFriendNameIsEAId)
			{
				FriendPlatformIcon.Visibility = ESlateVisibility::Visible;
				FriendPlatformIcon.SetBrushFromTexture(EAIcon);
			}
			else
			{
				FriendPlatformIcon.Visibility = ESlateVisibility::Collapsed;
			}
		}

		auto Lobby = Lobby::GetLobby();
		EHazePlayerControllerType ControllerType = Lobby::GetMostLikelyControllerType();

		bool bInPauseMenu = Game::HazeGameInstance.bIsInPauseMenu;
		if ((Lobby == nullptr || !Lobby.HasGameStarted() || bInPauseMenu) && ControllerType == EHazePlayerControllerType::Keyboard)
		{
			MouseButtonRow.Visibility = ESlateVisibility::SelfHitTestInvisible;
			KeyPromptRow.Visibility = ESlateVisibility::Collapsed;
		}
		else
		{
			KeyPromptRow.Visibility = ESlateVisibility::SelfHitTestInvisible;
			MouseButtonRow.Visibility = ESlateVisibility::Collapsed;
		}

		ProgressTimer.SetPercent(Invite.TimeRemaining);
	}
};