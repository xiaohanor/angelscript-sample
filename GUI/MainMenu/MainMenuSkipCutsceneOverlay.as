class UMainMenuSkipCutsceneOverlay : UHazeUserWidget
{
	default bIsFocusable = true;

	AMenuCameraUser CameraUser;
	FKey KeyboardCancelKey;
	FKey MioCancelKey;
	FKey ZoeCancelKey;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		FString Value;

		GameSettings::GetKeybindValue(n"Cancel", EHazeKeybindType::Keyboard, KeyboardCancelKey);
		GameSettings::GetKeybindValue(n"Cancel", EHazeKeybindType::MioController, MioCancelKey);
		GameSettings::GetKeybindValue(n"Cancel", EHazeKeybindType::ZoeController, ZoeCancelKey);
	}

	EHazePlayer GetPlayerForInput(FKeyEvent Event)
	{
		auto Lobby = Lobby::GetLobby();
		if (Lobby != nullptr)
		{
			auto Identity = Lobby.GetIdentityForInput(Event.InputDeviceId);
			if (Identity != nullptr && Identity.IsLocal())
			{
				// We haven't chosen players yet, so pretend player 1 is may
				if (Identity == Lobby.LobbyMembers[0].Identity)
					return EHazePlayer::Mio;
				else
					return EHazePlayer::Zoe;
			}
		}
		return EHazePlayer::MAX;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (InKeyEvent.IsRepeat())
			return FEventReply::Unhandled();

		EHazePlayer SkipPlayer = GetPlayerForInput(InKeyEvent);
		if (SkipPlayer == EHazePlayer::MAX)
			return FEventReply::Unhandled();

		FKey ControllerKey;
		if (SkipPlayer == EHazePlayer::Mio)
			ControllerKey = MioCancelKey;
		else
			ControllerKey = ZoeCancelKey;

		if (InKeyEvent.Key == KeyboardCancelKey || InKeyEvent.Key == ControllerKey)
		{
			if (SkipPlayer != EHazePlayer::MAX && CameraUser.ActiveLevelSequenceActor != nullptr)
				CameraUser.ActiveLevelSequenceActor.NetSetPlayerWantsToSkipSequence(SkipPlayer, true);
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		EHazePlayer SkipPlayer = GetPlayerForInput(InKeyEvent);
		if (SkipPlayer == EHazePlayer::MAX)
			return FEventReply::Unhandled();

		FKey ControllerKey;
		if (SkipPlayer == EHazePlayer::Mio)
			ControllerKey = MioCancelKey;
		else
			ControllerKey = ZoeCancelKey;

		if (InKeyEvent.Key == KeyboardCancelKey || InKeyEvent.Key == ControllerKey)
		{
			if (SkipPlayer != EHazePlayer::MAX && CameraUser.ActiveLevelSequenceActor != nullptr)
				CameraUser.ActiveLevelSequenceActor.NetSetPlayerWantsToSkipSequence(SkipPlayer, false);
		}
		return FEventReply::Unhandled();
	}
};