class ASkylinePhoneGameCheckBoxes : ASkylinePhoneGame
{
	UPROPERTY(DefaultComponent)
	USkylinePhoneGameToggleButtonComponent CheckBoxButton1;

	UPROPERTY(DefaultComponent)
	USkylinePhoneGameToggleButtonComponent CheckBoxButton2;

	UPROPERTY(DefaultComponent)
	USkylinePhoneGameToggleButtonComponent CheckBoxButton3;

	UPROPERTY(DefaultComponent)
	USkylinePhoneGameButtonComponent TermsAndConditionsButton;

	UPROPERTY(DefaultComponent)
	USkylinePhoneGameButtonComponent VerifyButton;

	UPROPERTY(DefaultComponent, Attach = TermsAndConditionsRoot)
	USkylinePhoneGameButtonComponent TermsAndConditionsNextButton;

	UPROPERTY(DefaultComponent, Attach = TermsAndConditionsRoot)
	USkylinePhoneGameButtonComponent TermsAndConditionsAcceptButton;

	UPROPERTY(DefaultComponent, Attach = TermsAndConditionsRoot)
	UTextRenderComponent TermsTextRenderComp;

	UPROPERTY(DefaultComponent)
	UTextRenderComponent NoAgeCheckTextRenderComp;

	UPROPERTY(DefaultComponent)
	UTextRenderComponent NoTermsCheckTextRenderComp;

	UPROPERTY(DefaultComponent)
	UTextRenderComponent TermsNotReadTextRenderComp;

	UPROPERTY(Meta = (MultiLine = true))
	TArray<FText> TermsTexts;
	int CurrentText = 0;

	UPROPERTY(DefaultComponent)
	USceneComponent TermsAndConditionsRoot;

	UPROPERTY()
	FHazeTimeLike TermsSlideTimeLike;
	default TermsSlideTimeLike.UseSmoothCurveZeroToOne();
	default TermsSlideTimeLike.Duration = 0.5;

	bool bTermsAndConditionsOpen = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TermsAndConditionsButton.OnButtonPressed.AddUFunction(this, n"TermsAndConditionsButtonPressed");
		TermsAndConditionsNextButton.OnButtonPressed.AddUFunction(this, n"TermsAndConditionsNextButtonPressed");
		TermsAndConditionsAcceptButton.OnButtonPressed.AddUFunction(this, n"TermsAndConditionsAcceptButtonPressed");
		VerifyButton.OnButtonPressed.AddUFunction(this, n"VerifyButtonPressed");

		TermsSlideTimeLike.BindUpdate(this, n"TermsSlideTimeLikeUpdate");

		NoAgeCheckTextRenderComp.SetHiddenInGame(true, true);
		NoTermsCheckTextRenderComp.SetHiddenInGame(true, true);
		TermsNotReadTextRenderComp.SetHiddenInGame(true, true);
		
		TermsAndConditionsAcceptButton.SetHiddenInGame(true, true);
		TermsAndConditionsAcceptButton.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		Timer::SetTimer(this, n"CallPhone", 3.0);

		//FText TextToFormat = FText::FromString("We are on page {PageNumber}")

		for(int i = 0; i < TermsTexts.Num(); i++)
		{
			TMap<FString, FFormatArgumentValue> FormatValues;
			FormatValues.Add("PageNumber", FFormatArgumentValue(i));

			FText FormattedText = FText::Format(TermsTexts[i], FormatValues);
			TermsTexts[i] = FormattedText;
		}


		//TermsTextRenderComp.Text = TermsTexts[CurrentText];
	}

	UFUNCTION()
	private void VerifyButtonPressed()
	{
		if (bTermsAndConditionsOpen &&
			CheckBoxButton1.bCorrect &&
			CheckBoxButton2.bCorrect)
		{
			EndPhoneGame();
		}

		NoAgeCheckTextRenderComp.SetHiddenInGame(CheckBoxButton1.bCorrect, true);
		NoTermsCheckTextRenderComp.SetHiddenInGame(CheckBoxButton2.bCorrect, true);
		TermsNotReadTextRenderComp.SetHiddenInGame(!CheckBoxButton2.bCorrect || bTermsAndConditionsOpen, true);

	}

	UFUNCTION()
	private void CallPhone()
	{
		OnPhoneCall.Broadcast();
	}

	UFUNCTION()
	private void TermsSlideTimeLikeUpdate(float CurrentValue)
	{
		FVector TermsAndConditionsLocation = TermsAndConditionsRoot.GetRelativeLocation();
		TermsAndConditionsLocation.Y = Math::Lerp(200.0, 0.0, CurrentValue);
		TermsAndConditionsRoot.SetRelativeLocation(TermsAndConditionsLocation);
	}

	UFUNCTION()
	private void TermsAndConditionsButtonPressed()
	{
		if (bTermsAndConditionsOpen)
			return;
			
		bTermsAndConditionsOpen = true;
		TermsSlideTimeLike.Play();

		CheckBoxButton1.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		CheckBoxButton2.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		CheckBoxButton3.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		VerifyButton.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	private void TermsAndConditionsNextButtonPressed()
	{
		if (CurrentText < TermsTexts.Num() - 1)
		{
			CurrentText++;

			if (CurrentText >= TermsTexts.Num() -1)
				ShowTermsAndConditionsAccept();
		}

		TermsTextRenderComp.Text = TermsTexts[CurrentText];
	}

	UFUNCTION()
	private void ShowTermsAndConditionsAccept()
	{
		TermsAndConditionsAcceptButton.SetHiddenInGame(false, true);
		TermsAndConditionsAcceptButton.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
		TermsAndConditionsNextButton.SetHiddenInGame(true, true);
		TermsAndConditionsNextButton.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	private void TermsAndConditionsAcceptButtonPressed()
	{
		TermsSlideTimeLike.Reverse();
		CheckBoxButton1.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
		CheckBoxButton2.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
		CheckBoxButton3.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
		VerifyButton.SetCollisionEnabled(ECollisionEnabled::QueryOnly);

		TermsNotReadTextRenderComp.SetHiddenInGame(true, true);
	}
};