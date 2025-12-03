class UAccessibilityTextToSpeechSubsystem : UScriptGameInstanceSubsystem
{
	UAccessibilityChatWidget SpeechToTextChatWidget;

	bool IsTTSActive() const
	{
		auto Lobby = Lobby::GetLobby();
		if (Lobby == nullptr)
			return false;
		if (Lobby.Network == EHazeLobbyNetwork::Local)
			return false;
		if (Lobby.NumIdentitiesInLobby() < 2)
			return false;

		switch (Online::GetAccessibilityState(EHazeAccessibilityFeature::TextToSpeech))
		{
			case EHazeAccessibilityState::OSTurnedOn:
			case EHazeAccessibilityState::GameTurnedOn:
				return true;
			default:
				return false;
		}
	}

	void ShowTTSPrompt()
	{
		// Note: Not localized because we only support TTS in english
		FMessageDialog Dialog;
		Dialog.Message = FText::FromString("Say a phrase in VOIP to the other player using text-to-speech:");
		Dialog.AddOption(
			FText::FromString("\"Yes\""),
			FOnMessageDialogOptionChosen(this, n"SayYes"),
		);
		Dialog.AddOption(
			FText::FromString("\"No\""),
			FOnMessageDialogOptionChosen(this, n"SayNo"),
		);
		Dialog.AddOption(
			FText::FromString("Enter custom message"),
			FOnMessageDialogOptionChosen(this, n"SayCustom"),
		);
		Dialog.AddCancelOption();
		ShowPopupMessage(Dialog, this);
	}

	UFUNCTION()
	private void SayYes()
	{
		Print("TTS: Yes");
		Online::SendVoipTextToSpeech(FText::FromString("Yes"));
	}

	UFUNCTION()
	private void SayNo()
	{
		Print("TTS: No");
		Online::SendVoipTextToSpeech(FText::FromString("No"));
	}

	UFUNCTION()
	private void SayCustom()
	{
		Print("Opening TTS UI");
		Online::ShowTextToSpeechInput();
	}
}