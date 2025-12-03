UCLASS(Abstract)
class USkylinePhoneLoadingScreenWidget : USkylinePhoneGameWidget
{
	UPROPERTY(BindWidget)
	UTextBlock PercentageText;

	UPROPERTY()
	float RemainingSplineLengthWhenCompleted = 10000.0;

	UPROPERTY()
	UCurveFloat LoadingCurve;

	UPROPERTY()
	TArray<FText> CringeSlogans;

	ASkylinePhoneProgressSpline SplineActor;
	float SplineLength;
	float RemainingSplineLengthWhenActivated;
	
	int DotsAmount = 3;
	int CringeSloganIndex = -1;
	float LoadingPercentage = 0.0;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		SplineActor = TListedActors<ASkylinePhoneProgressSpline>().GetSingle();
		SplineLength = SplineActor.Spline.SplineLength;
		RemainingSplineLengthWhenActivated = (SplineLength - SplineActor.Spline.GetClosestSplineDistanceToWorldLocation(Game::Mio.ActorLocation));
	}

	void OnGameStarted() override
	{
		Super::OnGameStarted();
		Phone.BroadcastGameEvent(ESkylinePhoneGameEvent::Loading);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if(!bGameActive)
			return;

		float RemainingSplineLength = (SplineLength - SplineActor.Spline.GetClosestSplineDistanceToWorldLocation(Game::Mio.ActorLocation));

		float Alpha = 0;
		if(RemainingSplineLengthWhenActivated < KINDA_SMALL_NUMBER)
		{
			// If RemainingSplineLengthWhenActivated is 0, we will get Divide By Zero in the else statement
			Alpha = 0;
		}
		else
		{
			Alpha = Math::Lerp(1.0, 0.0, RemainingSplineLength / RemainingSplineLengthWhenActivated);
		}

		if (RemainingSplineLength < RemainingSplineLengthWhenCompleted)
		{
			PercentageText.SetText(FText::FromString(f"{100}%"));
		}

		else
		{
			LoadingPercentage = Math::Lerp(0.0, 99.0, LoadingCurve.GetFloatValue(Alpha));			
			PercentageText.SetText(FText::FromString(f"{Math::FloorToInt(LoadingPercentage)}%"));
		}
	}

	UFUNCTION(BlueprintPure)
	FText GetAuthText()
	{
		FText Text = NSLOCTEXT("PhoneGame", "LoadScreen", "Authenticating");
		FString String = Text.ToString();

		for(int i = 0; i < DotsAmount; i++)
		{
			String.Append(".");
		}
		
		Text = FText::FromString(String);
		
		DotsAmount++;
		if(DotsAmount >= 4)
			DotsAmount = 1;

		return Text;
	}

	UFUNCTION(BlueprintPure)
	FText GetCringeSlogan()
	{
		CringeSloganIndex++;
		if(CringeSloganIndex >= CringeSlogans.Num())
			CringeSloganIndex = 0;
		
		return CringeSlogans[CringeSloganIndex];
	}
}