UCLASS(Abstract)
class USkylinePhoneWritingWidget : USkylinePhoneGameWidget
{
	UPROPERTY(BindWidget)
	UUniformGridPanel Row1;

	UPROPERTY(BindWidget)
	UUniformGridPanel Row2;

	UPROPERTY(BindWidget)
	UUniformGridPanel Row3;

	//BUTTONS -------------------------------

	UPROPERTY(BindWidget)
	UOverlay Enter;

	UPROPERTY(BindWidget)
	UOverlay Space;

	UPROPERTY(BindWidget)
	UOverlay Erase;

	UPROPERTY(BindWidget)
	UOverlay ActualTextButton;

	UPROPERTY(BindWidget)
	UOverlay SuggestedTextButton;

	UPROPERTY(BindWidget)
	UOverlay SuggestedTextButton2;
	
	UPROPERTY(BindWidget)
	USkylinePhoneKeyboardKey Period;

	//TEXT -------------------------------

	UPROPERTY(BindWidget)
	UTextBlock TypedText;

	UPROPERTY(BindWidget)
	UTextBlock ActualText;

	UPROPERTY(BindWidget)
	UTextBlock SuggestedText;

	UPROPERTY(BindWidget)
	UTextBlock SuggestedText2;

	UPROPERTY(BindWidget)
	UTextBlock TryAgainText;

	// -----------------------------------

	UPROPERTY(BindWidget)
	UImage SuggestionHighlight;

	UPROPERTY()
	TSubclassOf<USkylinePhoneKeyboardKey> KeyWidget;

	UPROPERTY()
	TArray<FString> Rows;

	TArray<UHazeUserWidget> Keys;
	TArray<FString> KeyChars;

	FString LastCorrectedWord;

	FString CurrentTypedText;
	FString CurrentSuggestion;
	FString CurrentSuggestion2;

	const float CursorFlashSpeed = 6;
	bool bCursorVisible = false;

	FOnSkylinePhoneInputResponseSignature OnInputAccepted;
	FOnSkylinePhoneInputResponseSignature OnInputRejected;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		Period.Text.SetText(FText::FromString("."));

		for(int Row = 0; Row < Rows.Num(); Row++)
		{
			UUniformGridPanel Keyboard;

			if(Row == 0)
				Keyboard = Row1;
			else if(Row == 1)
				Keyboard = Row2;
			else
				Keyboard = Row3;

			for(int Col = 0; Col < Rows[Row].Len(); Col++)
			{
				auto Key = Cast<USkylinePhoneKeyboardKey>(Keyboard.GetChildAt(Col));

				FString KeyChar = Rows[Row].Mid(Col, 1);
				Key.Text.SetText(FText::FromString(KeyChar));
				Keys.Add(Key);
				KeyChars.Add(KeyChar);
			}
		}
	}

	void OnGameStarted() override
	{
		Super::OnGameStarted();
		Phone.BroadcastGameEvent(ESkylinePhoneGameEvent::Typing);
	}

	void OnClick(FVector2D CursorPos) override
	{
		Super::OnClick(CursorPos);

		if(IsWidgetHovered(GetWidgetLocation(Erase), Erase.CachedGeometry.AbsoluteSize))
		{
			if(!CurrentTypedText.IsEmpty())
			{
				CurrentTypedText = CurrentTypedText.LeftChop(1);
				TypedText.SetText(FText::FromString(CurrentTypedText));
				
				if(LastCorrectedWord.IsEmpty())
				{
					UpdateSuggestion();
				}
			}
		}
		else if(IsWidgetHovered(GetWidgetLocation(Space), Space.CachedGeometry.AbsoluteSize))
		{
			AutoCorrect(true);
			CurrentTypedText.Append(" ");
			TypedText.SetText(FText::FromString(CurrentTypedText));

			if(LastCorrectedWord.IsEmpty())
			{
				UpdateSuggestion();
			}
		}
		else if(IsWidgetHovered(GetWidgetLocation(Period), Period.CachedGeometry.AbsoluteSize))
		{
			CurrentTypedText.Append(".");
			TypedText.SetText(FText::FromString(CurrentTypedText));
		}
		else if(IsWidgetHovered(GetWidgetLocation(ActualTextButton), ActualTextButton.CachedGeometry.AbsoluteSize))
		{
			CurrentTypedText.Append(" ");
			TypedText.SetText(FText::FromString(CurrentTypedText));
			LastCorrectedWord = "";
			UpdateSuggestion();
		}
		else if(IsWidgetHovered(GetWidgetLocation(SuggestedTextButton), SuggestedTextButton.CachedGeometry.AbsoluteSize))
		{
			AutoCorrect();
			CurrentTypedText.Append(" ");
			TypedText.SetText(FText::FromString(CurrentTypedText));
			LastCorrectedWord = "";
			UpdateSuggestion();
		}
		else if(IsWidgetHovered(GetWidgetLocation(SuggestedTextButton2), SuggestedTextButton2.CachedGeometry.AbsoluteSize))
		{
			AutoCorrect2();
			CurrentTypedText.Append(" ");
			TypedText.SetText(FText::FromString(CurrentTypedText));
			LastCorrectedWord = "";
			UpdateSuggestion();
		}
		else if(IsWidgetHovered(GetWidgetLocation(Enter), Enter.CachedGeometry.AbsoluteSize))
		{
			AutoCorrect(true);
			TypedText.SetText(FText::FromString(CurrentTypedText));
			EnterAnswer();
		}
		else
		{
			for(int i = 0; i < Keys.Num(); i++)
			{
				if(IsWidgetHovered(GetWidgetLocation(Keys[i]), Keys[i].CachedGeometry.AbsoluteSize))
				{
					CurrentTypedText.Append(KeyChars[i]);
					TypedText.SetText(FText::FromString(CurrentTypedText));

					if(LastCorrectedWord.IsEmpty())
						UpdateSuggestion();
				}
			}
		}
	}

	void UpdateSuggestion()
	{
		int LastSpaceIndex = -1;
		CurrentTypedText.FindLastChar(' ', LastSpaceIndex);
		FString WordToCorrect = CurrentTypedText;
		FString CurrentTextMinusCorrectedWord = CurrentTypedText;

		if(LastSpaceIndex != -1)
			WordToCorrect = CurrentTypedText.Right(CurrentTypedText.Len() - LastSpaceIndex -1);

		CurrentTextMinusCorrectedWord.RemoveFromEnd(WordToCorrect);
		
		CurrentSuggestion = "";
		CurrentSuggestion2 = "";

		SuggestionHighlight.SetVisibility(ESlateVisibility::Hidden);

		if(WordToCorrect.Find("bk") != -1)
		{
			CurrentSuggestion = "bake";
			CurrentSuggestion2 = "bike";
			SuggestionHighlight.SetVisibility(ESlateVisibility::Visible);
		}
		else if(WordToCorrect.Find("xq") != -1)
		{
			CurrentSuggestion = "can";
			CurrentSuggestion2 = "xD";
			SuggestionHighlight.SetVisibility(ESlateVisibility::Visible);
		}

		if(!WordToCorrect.IsEmpty())
			ActualText.SetText(FText::FromString("\"" + WordToCorrect + "\""));
		else
			ActualText.SetText(FText());

		SuggestedText.SetText(FText::FromString(CurrentSuggestion));
		SuggestedText2.SetText(FText::FromString(CurrentSuggestion2));
	}

	FString GetTypedTextMinusLastWord()
	{
		int LastSpaceIndex = -1;
		CurrentTypedText.FindLastChar(' ', LastSpaceIndex);
		FString WordToCorrect = CurrentTypedText;
		FString CurrentTextMinusCorrectedWord = CurrentTypedText;

		if(LastSpaceIndex != -1)
			WordToCorrect = CurrentTypedText.Right(CurrentTypedText.Len() - LastSpaceIndex -1);

		CurrentTextMinusCorrectedWord.RemoveFromEnd(WordToCorrect);
		return CurrentTextMinusCorrectedWord;
	}

	void AutoCorrect(bool bAuto = false)
	{
		SuggestionHighlight.SetVisibility(ESlateVisibility::Hidden);
		SuggestedText.SetText(FText());
		SuggestedText2.SetText(FText());
		ActualText.SetText(FText());
		LastCorrectedWord = CurrentSuggestion;
		
		if(!CurrentSuggestion.IsEmpty())
		{
			if(bAuto)
				Phone.BroadcastGameEvent(ESkylinePhoneGameEvent::Autocorrect);

			CurrentTypedText = GetTypedTextMinusLastWord() + CurrentSuggestion;
			CurrentSuggestion.Empty();
		}
	}

	void AutoCorrect2()
	{
		if(!CurrentSuggestion2.IsEmpty())
		{
			CurrentTypedText = GetTypedTextMinusLastWord() + CurrentSuggestion2;
			CurrentSuggestion2.Empty();
		}
	}

	void EnterAnswer()
	{
		if(CurrentTypedText.TrimEnd() == "bke xqj")
		{
			OnInputAccepted.Broadcast();
			Phone.PlaySuccessForceFeedback();
			GameComplete();
		}
		else
		{
			TryAgainText.SetVisibility(ESlateVisibility::Visible);
			Phone.PlayFailForceFeedback();
			OnInputRejected.Broadcast();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if(!bCursorVisible && Math::Sin(Time::GameTimeSeconds * CursorFlashSpeed) < 0)
		{
			bCursorVisible = true;
			TypedText.SetText(FText::FromString(CurrentTypedText + "|"));
		}
		else if(bCursorVisible && Math::Sin(Time::GameTimeSeconds * CursorFlashSpeed) >= 0)
		{
			bCursorVisible = false;
			TypedText.SetText(FText::FromString(CurrentTypedText));
		}


		HoverScaleWidget(Enter, InDeltaTime);
		HoverScaleWidget(Space, InDeltaTime);
		HoverScaleWidget(Erase, InDeltaTime);
		HoverScaleWidget(Period, InDeltaTime);

		for(auto Child : Keys)
		{
			HoverScaleWidget(Child, InDeltaTime);
		}
	}
}