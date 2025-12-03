struct FSkylinePhoneCaptchaGameSlide
{
	UPROPERTY()
	UTexture2D Image;

	UPROPERTY()
	TArray<int> CorrectSquareIndices;

	UPROPERTY()
	FText ObjectToFind;
}

UCLASS(Abstract)
class USkylinePhoneCaptchaGameWidget : USkylinePhoneGameWidget
{
	UPROPERTY()
	TArray<FSkylinePhoneCaptchaGameSlide> Slides;

	UPROPERTY(BindWidget)
	UUniformGridPanel Grid;

	UPROPERTY(BindWidget)
	UOverlay ButtonOverlay;

	UPROPERTY(BindWidget)
	UTextBlock ObjectName;

	UPROPERTY(BindWidget)
	UTextBlock ButtonText;

	TArray<USkylinePhoneCaptchaSquareWidget> Squares;
	TArray<FVector2D> GridSquareLocations;

	int CurrentSlideIndex = -1;
	int CurrentSelectedSquares = 0;

	FOnSkylinePhoneInputResponseSignature OnAnswerCorrect;
	FOnSkylinePhoneInputResponseSignature OnAnswerIncorrect;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		auto GridCanvasPanelSlot = Cast<UCanvasPanelSlot>(Grid.Slot);
		float SquareWidth = GridCanvasPanelSlot.Size.X  / 3 - Grid.SlotPadding.Left * 2;

		for(int i = 0; i < Grid.ChildrenCount; i++)
		{
			auto Square = Cast<USkylinePhoneCaptchaSquareWidget>(Grid.GetChildAt(i));
			Squares.Add(Square);

			int Row = Math::FloorToInt(i / 3.0);
			int Column = i - Row * 3;
			Square.Image.DynamicMaterial.SetScalarParameterValue(n"Column", Column);
			Square.Image.DynamicMaterial.SetScalarParameterValue(n"Row", Row);

			float XPos = (-GridCanvasPanelSlot.Size.X / 2 + Grid.SlotPadding.Left + Column * SquareWidth) + SquareWidth / 2;
			float YPos = (GridCanvasPanelSlot.Position.Y + Grid.SlotPadding.Top + Row * SquareWidth) + SquareWidth / 2;

			GridSquareLocations.Add(FVector2D(XPos, YPos));
		}

		Next();
	}
	
	void OnGameStarted() override
	{
		Super::OnGameStarted();
		Phone.BroadcastGameEvent(ESkylinePhoneGameEvent::Captcha1);
	}

	void OnClick(FVector2D CursorPos) override
	{
		Super::OnClick(CursorPos);
		
		auto GridCanvasPanelSlot = Cast<UCanvasPanelSlot>(Grid.Slot);
		float SquareWidth = GridCanvasPanelSlot.Size.X  / 3 - Grid.SlotPadding.Left * 2;

		for(int i = 0; i < Squares.Num(); i++)
		{
			if(IsWidgetHovered(GridSquareLocations[i], FVector2D::UnitVector * SquareWidth))
			{
				Squares[i].Click();

				if(Squares[i].IsSelected())
					CurrentSelectedSquares++;
				else
					CurrentSelectedSquares--;

				if(CurrentSelectedSquares == 0)
				{
					ButtonText.SetText(NSLOCTEXT("PhoneGame", "SkipButton", "SKIP"));
				}
				else
				{
					ButtonText.SetText(NSLOCTEXT("PhoneGame", "VerifyButton", "VERIFY"));
				}

				return;
			}
		}

		if(IsWidgetHovered(ButtonOverlay))
		{
			CheckResult();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if(IsWidgetHovered(ButtonOverlay))
		{
			ButtonOverlay.SetRenderScale(FVector2D::UnitVector * Math::FInterpConstantTo(ButtonOverlay.GetRenderTransform().Scale.X, 1.08, InDeltaTime, 1));
		}
		else
		{
			ButtonOverlay.SetRenderScale(FVector2D::UnitVector * Math::FInterpConstantTo(ButtonOverlay.GetRenderTransform().Scale.X, 1, InDeltaTime, 1));
		}
	}

	void CheckResult()
	{
		if(CurrentSlideIndex >= Slides.Num())
			return;

		bool bFail = false;

		for(int i = 0; i < Squares.Num(); i++)
		{
			bool bIsCorrect = false;

			if(Squares[i].IsSelected())
			{
				bIsCorrect = Slides[CurrentSlideIndex].CorrectSquareIndices.Contains(i);
			}
			else
			{
				bIsCorrect = !Slides[CurrentSlideIndex].CorrectSquareIndices.Contains(i);
			}

			if(!bIsCorrect)
			{
				bFail = true;
				break;
			}
		}

		if(bFail)
		{
			Phone.BroadcastGameEvent(ESkylinePhoneGameEvent::CaptchaFailed);
			OnIncorrectAnswer();
			Phone.PlayFailForceFeedback();
			OnAnswerIncorrect.Broadcast();
		}
		else
		{
			Phone.BroadcastGameEvent(ESkylinePhoneGameEvent::CaptchaSuccess);
			OnCorrectAnswer();
			Phone.PlaySuccessForceFeedback();
			OnAnswerCorrect.Broadcast();
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnCorrectAnswer(){}
	
	UFUNCTION(BlueprintEvent)
	void OnIncorrectAnswer(){}

	UFUNCTION(BlueprintCallable)
	void Next()
	{
		CurrentSlideIndex++;

		if(CurrentSlideIndex >= Slides.Num())
		{
			GameComplete();
			return;
		}

		if(CurrentSlideIndex == 1)
			Phone.BroadcastGameEvent(ESkylinePhoneGameEvent::Captcha2);
		else if(CurrentSlideIndex == 2)
			Phone.BroadcastGameEvent(ESkylinePhoneGameEvent::Captcha3);

		ObjectName.SetText(Slides[CurrentSlideIndex].ObjectToFind);

		for(auto Square : Squares)
		{
			Square.NewSlide();
			Square.Image.DynamicMaterial.SetTextureParameterValue(n"Texture", Slides[CurrentSlideIndex].Image);
		}

		CurrentSelectedSquares = 0;
		ButtonText.SetText(NSLOCTEXT("PhoneGame", "SkipButton", "SKIP"));
	}
}