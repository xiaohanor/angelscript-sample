class ASkylinePhoneGameLoadingScreen : ASkylinePhoneGame
{
	UPROPERTY(DefaultComponent)
	USceneComponent LoadingRoot;

	UPROPERTY(DefaultComponent)
	UTextRenderComponent LoadingPercentageTextRenderComp;

	UPROPERTY(DefaultComponent)
	USceneComponent CompletedRoot;

	UPROPERTY()
	FHazeTimeLike CompletedScreenTimeLike;
	default CompletedScreenTimeLike.UseSmoothCurveZeroToOne();
	default CompletedScreenTimeLike.Duration = 0.5;

	UPROPERTY()
	UCurveFloat LoadingCurve;

	UPROPERTY()
	float RemainingSplineLengthWhenCompleted = 10000.0;

	ASkylinePhoneProgressSpline SplineActor;
	float SplineLength;
	float RemainingSplineLengthWhenActivated;

	UPROPERTY(NotEditable)
	float LoadingPercentage;
	
	bool bFullyLoaded = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CompletedScreenTimeLike.BindUpdate(this, n"CompletedScreenTimeLikeUpdate");
		SplineActor = TListedActors<ASkylinePhoneProgressSpline>().GetSingle();
		SplineLength = SplineActor.Spline.SplineLength;

		RemainingSplineLengthWhenActivated = (SplineLength - SplineActor.Spline.GetClosestSplineDistanceToWorldLocation(Game::Mio.ActorLocation));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		
		LoadingRoot.AddRelativeRotation(FRotator(0.0, 0.0, 200.0 * DeltaSeconds));
		CalculateLoadingPercentage();
	}

	private void CalculateLoadingPercentage()
	{
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
			FullyLoaded();

		else
			LoadingPercentage = Math::Lerp(0.0, 99.0, LoadingCurve.GetFloatValue(Alpha));

		PrintToScreen("Alpha = " + Alpha);
		PrintToScreen("ModifiedAlpha = " + LoadingCurve.GetFloatValue(Alpha));
	}

	private void FullyLoaded()
	{
		if (bFullyLoaded)
			return;

		LoadingPercentage = 100.0;

		bFullyLoaded = true;

		CompletedScreenTimeLike.Play();

		Timer::SetTimer(this, n"DeactivatePhone", 1.0);
	}

	UFUNCTION()
	private void DeactivatePhone()
	{
		auto PhoneComp = USkylinePhoneUserComponent::Get(Game::Zoe);
			if (PhoneComp != nullptr)
				PhoneComp.PhoneCompleted();
	}

	UFUNCTION()
	private void CompletedScreenTimeLikeUpdate(float CurrentValue)
	{
		CompletedRoot.SetRelativeLocation(FVector::RightVector * Math::Lerp(550.0, 0.0, CurrentValue));
	}
};