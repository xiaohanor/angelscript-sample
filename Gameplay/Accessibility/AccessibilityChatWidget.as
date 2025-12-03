const FConsoleVariable CVar_STTFontSize("Haze.SpeechToTextFontSize", 0);
const FConsoleVariable CVar_STTDebugChat("Haze.STTDebugChat", 0);

class UAccessibilityChatWidgetRowInfo
{
	UAccessibilityChatWidgetRowInfo(FText Text, int InFontSize)
	{
		ChatText = Text;
		FontSize = InFontSize;
	}

	UPROPERTY()
	FText ChatText;
	UPROPERTY()
	int FontSize = 0;
}

struct FChatLineData
{
	FText DisplayText;
	float Lifetime = 0.0;
	bool bVisible = true;
}

UCLASS(Abstract)
class UAccessibilityChatWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UListView ChatListView;

	const int MAX_ROWS = 10;
	const float ROW_TIME = 10.0;

	bool bBrowseMode = false;

	private TArray<FChatLineData> ChatLines;
	private bool bViewDirty = true;
	private int CurrentFontSize = 0;
	private float NextDebugChatMessage = 0.0;
	private float LastBrowseInput = 0.0;
	private int DebugChatNumber = 0;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		UAccessibilityTextToSpeechSubsystem::Get().SpeechToTextChatWidget = this;
	}

	UFUNCTION(BlueprintOverride)
	void Destruct()
	{
		UAccessibilityTextToSpeechSubsystem::Get().SpeechToTextChatWidget = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float Timer)
	{
		for (FChatLineData& Line : ChatLines)
		{
			Line.Lifetime += Timer;
			if (Line.bVisible && Line.Lifetime >= ROW_TIME)
			{
				Line.bVisible = false;
				bViewDirty = true;
			}
		}

		UpdateRows();

		if (CurrentFontSize != CVar_STTFontSize.GetInt())
		{
			CurrentFontSize = CVar_STTFontSize.GetInt();
			bViewDirty = true;
		}

		if (Lobby::GetLobby() == nullptr && ChatLines.Num() != 0)
		{
			ChatLines.Empty();
			bViewDirty = true;
		}

		if (bViewDirty)
			UpdateView();

		if (bBrowseMode)
		{
			if (ChatListView.DistanceFromBottom <= 0.001f)
			{
				if (LastBrowseInput < Time::PlatformTimeSeconds - 5.0)
					StopBrowseMode();
			}
			else
			{
				if (LastBrowseInput < Time::PlatformTimeSeconds - 30.0)
					StopBrowseMode();
			}
		}
	}

	bool BrowseInput(FAnalogInputEvent Event)
	{
		if (Event.Key == EKeys::Gamepad_RightY)
		{
			if (Math::Abs(Event.AnalogValue) > 0.1f)
			{
				if (!bBrowseMode)
					SwitchToBrowseMode();

				ChatListView.ScrollOffset = ChatListView.ScrollOffset + (Event.AnalogValue * -10.f * Time::UndilatedWorldDeltaSeconds);
				LastBrowseInput = Time::PlatformTimeSeconds;
			}
		}
		return false;
	}

	void SwitchToBrowseMode()
	{
		bBrowseMode = true;
		UpdateView();
	}

	void StopBrowseMode()
	{
		bBrowseMode = false;
		UpdateView();
	}

	void CanNoLongerBrowse()
	{
		StopBrowseMode();
	}

	void UpdateRows()
	{
		TArray<FString> NewLines;
		Online::GetNewTranscribedTexts(NewLines);

		if (CVar_STTDebugChat.GetInt() != 0)
		{
			// Send chat messages periodically in debug mode
			if (Time::PlatformTimeSeconds >= NextDebugChatMessage)
			{
				NextDebugChatMessage = Time::PlatformTimeSeconds + Math::RandRange(1.0, 3.0);

				switch (Math::RandRange(0, 3))
				{
					case 0: NewLines.Add("Hello World!"); break;
					case 1: NewLines.Add("Affirmative"); break;
					case 2: NewLines.Add("Did you see that ludicrous display last night?"); break;
					case 3: NewLines.Add("Test Message Test Message Test Message Test Message Test Message Test Message Test Message"); break;
				}

				NewLines[NewLines.Num()-1] = "" + (DebugChatNumber) + " - " + NewLines[NewLines.Num()-1];
				DebugChatNumber++;
			}
		}

		for (FString Line : NewLines)
		{
			FChatLineData NewLine;
			NewLine.DisplayText = FText::FromString(Line);
			NewLine.Lifetime = 0;
			ChatLines.Add(NewLine);
		}

		// Only keep the latest 200 chat lines
		while (ChatLines.Num() > 200)
			ChatLines.RemoveAt(0);

		if (NewLines.Num() > 0)
			bViewDirty = true;
	}

	void UpdateView()
	{
		TArray<UObject> ViewRows;
		ViewRows.Reserve(MAX_ROWS);

		int LineIndex = 0;
		if (!bBrowseMode)
			LineIndex = Math::Max(ChatLines.Num() - 5, 0);

		for (int Count = ChatLines.Num(); LineIndex < Count; ++LineIndex)
		{
			if (ChatLines[LineIndex].bVisible || bBrowseMode)
				ViewRows.Add(UAccessibilityChatWidgetRowInfo(ChatLines[LineIndex].DisplayText, CurrentFontSize));
			else
				continue;
		}

		bool bWasAtBottom = ChatListView.DistanceFromBottom <= 0.001f;
		ChatListView.SetVisibility(
			(ViewRows.Num() == 0) ? ESlateVisibility::Collapsed : ESlateVisibility::HitTestInvisible
		);
		ChatListView.SetListItems(ViewRows);

		if (!bBrowseMode)
		{
			ChatListView.SetScrollbarVisibility(ESlateVisibility::Hidden);
			ChatListView.ScrollToBottom();
		}
		else
		{
			ChatListView.SetScrollbarVisibility(ESlateVisibility::Visible);
			if (bWasAtBottom)
				ChatListView.ScrollToBottom();
		}
		
		bViewDirty = false;
	}

}