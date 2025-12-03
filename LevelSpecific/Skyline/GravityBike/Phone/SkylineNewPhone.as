event void FOnSkylinePhoneGameChangedSignature(int NewGameIndex);
event void FOnSkylinePhoneInputResponseSignature();
event void FOnSkylinePhoneNewEvent(ESkylinePhoneGameEvent NewStage);


enum ESkylinePhoneGameEvent
{
	LockScreen,
	FaceRecognition,
	Captcha1,
	Captcha2,
	Captcha3,
	CaptchaFailed,
	CaptchaSuccess,
	TermsConditions,
	PhoneCall,
	PhoneAnswered,
	Typing,
	Autocorrect,
	Loading
}

UCLASS(Abstract)
class ASkylineNewPhone : ASkylinePhoneBase
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PhoneAttach;

	UPROPERTY(DefaultComponent, Attach = PhoneAttach)
	UWidgetComponent ScreenWidgetComp;

	UPROPERTY(DefaultComponent, Attach = PhoneAttach)
	UWidgetComponent GameWidgetComp;

	UPROPERTY(DefaultComponent, Attach = PhoneAttach)
	UWidgetComponent NextGameWidgetComp;

	UPROPERTY(DefaultComponent, Attach = PhoneAttach)
	USceneComponent FaceRecognitionSceneComp;

	UPROPERTY(DefaultComponent, Attach = PhoneAttach)
	USceneCaptureComponent2D SceneCapture;
	default SceneCapture.ProjectionType = ECameraProjectionMode::Perspective;
	default SceneCapture.OrthoWidth = 180.0;
	default SceneCapture.bCaptureEveryFrame = false;
	default SceneCapture.PrimitiveRenderMode = ESceneCapturePrimitiveRenderMode::PRM_UseShowOnlyList;
	default SceneCapture.bCaptureOnMovement = false;
	default SceneCapture.MaxViewDistanceOverride = 1000.0;

	USkylinePhoneScreenWidget ScreenWidget;
	USkylinePhoneTimerWidget TimerWidget;

	UPROPERTY(EditDefaultsOnly)
	UTextureRenderTarget2D RenderTarget;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylinePhoneCursor> CursorClass;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect TapForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect FailForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect SuccessFeedback;

	UPROPERTY(EditInstanceOnly)
	ASkylinePhoneProgressSpline SplineActor;
	float SplineLength;

	UPROPERTY(NotEditable)
	float TimeLeft = -1;

	float TargetTimeLeft = MAX_flt;

	USkylinePhoneGameWidget CurrentGame;
	USkylinePhoneGameWidget NextGame;

	UPROPERTY(EditDefaultsOnly)
	TArray<TSubclassOf<USkylinePhoneGameWidget>> PhoneGames;

	UPROPERTY()
	FOnSkylinePhoneGameChangedSignature OnGameChanged;

	UPROPERTY()
	FOnSkylinePhoneNewEvent OnNewPhoneEvent;

	bool bPhoneCalled = false;

	UPROPERTY(BlueprintReadOnly)
	bool bIsPressing = false;

	float DistanceAlongSpline = -1;
	const float TimeLeftAtEndOfSpline = 3.0;
	const float TimeMaxSpeed = 4500;
	const float SplineDistanceMaxSpeed = 5500;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineActor = TListedActors<ASkylinePhoneProgressSpline>().GetSingle();

		SetActorTickEnabled(false);

		PhoneGameIndex = Save::GetPersistentProfileCounter(n"PhoneGameProgress", -1);
		if(PhoneGameIndex >= 0)
			PhoneGameIndex--;

		ScreenWidget = Cast<USkylinePhoneScreenWidget>(ScreenWidgetComp.Widget);
		TimerWidget = ScreenWidget.Timer;

		if(HasControl())
		{
			CrumbSetStartingPhoneGame(PhoneGameIndex);
			CrumbNextPhoneGame(PhoneGameIndex);
		}

		bProgressMadeSinceLastLoad = false;
		
		SplineLength = SplineActor.Spline.SplineLength;
	}

	void BroadcastGameEvent(ESkylinePhoneGameEvent Event)
	{
		Print("New event: " + Event);
		OnNewPhoneEvent.Broadcast(Event);
	}

	void OnRelease(FVector2D CursorPos) override
	{
		bIsPressing = false;
		if(CurrentGame != nullptr)
		{
			CurrentGame.OnClickReleased();
		}
	}

	void OnClick(FVector2D CursorPos) override
	{
		bIsPressing = true;
		if(CurrentGame != nullptr)
		{
			CurrentGame.OnClick(CursorPos);
		}

		ScreenWidget.BP_OnClick();
		Game::Zoe.PlayForceFeedback(TapForceFeedback, false, true, this);
	}

	void PlaySuccessForceFeedback()
	{
		Game::Zoe.PlayForceFeedback(SuccessFeedback, false, true, this);
	}

	void PlayFailForceFeedback()
	{
		Game::Zoe.PlayForceFeedback(FailForceFeedback, false, true, this);
	}

	UFUNCTION()
	void UnloadBottomLayerWidget()
	{
		NextGame = nullptr;
		NextGameWidgetComp.SetWidget(nullptr);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (CurrentGame != nullptr)
		{
			ScreenWidget.SetCursorPosition(CursorPosition.Value);
			CurrentGame.SetCursorPosition(CursorPosition.Value);
		}

		if (SplineActor != nullptr && TimerWidget != nullptr)
		{
			auto GravityBike = GravityBikeSpline::GetGravityBike();
			FVector SampleLocation = GravityBike.ActorCenterLocation;
			auto BladeComp = UGravityBikeBladePlayerComponent::Get(GravityBikeBlade::GetPlayer());
			if(BladeComp.State == EGravityBikeBladeState::Barrel)
			{
				// While on the barrel, use the barrel actor location instead
				SampleLocation = BladeComp.Barrel.ActorLocation;
			}

			const float TargetDistanceAlongSpline = SplineActor.Spline.GetClosestSplineDistanceToWorldLocation(SampleLocation);

			if(DistanceAlongSpline < 0)
				DistanceAlongSpline = TargetDistanceAlongSpline;

			// Move forward on the spline at a constant rate, not too fast since that gives the illusion away
			DistanceAlongSpline = Math::FInterpConstantTo(DistanceAlongSpline, TargetDistanceAlongSpline, DeltaSeconds, SplineDistanceMaxSpeed);

			const float DistanceLeft = SplineLength - DistanceAlongSpline;
			const float NewTimeLeft = DistanceLeft / TimeMaxSpeed;

			// Never decrease the target time
			TargetTimeLeft = Math::Min(TargetTimeLeft, NewTimeLeft) + TimeLeftAtEndOfSpline;

			// Initialize TimeLeft
			if(TimeLeft < 0)
				TimeLeft = NewTimeLeft;

			// Smooth out the time left a little bit
			TimeLeft = Math::FInterpTo(TimeLeft, TargetTimeLeft, DeltaSeconds, 10);
			
			if(TimeLeft <= 10)
			{
				if(Math::FloorToInt(TimeLeft) != Math::FloorToInt(TimeLeft))
				{
					TimerWidget.BP_BigWarning();
				}
			}
			else
			{
				if(Math::FloorToInt(TimeLeft / 10) != Math::FloorToInt(TimeLeft / 10))
				{
					TimerWidget.BP_SmallWarning();
				}
			}

			TimerWidget.SetTimeLeft(TimeLeft);
		}

#if !RELEASE
		TEMPORAL_LOG(this)
			.Value("CurrentGame", CurrentGame)
		;
#endif
	}

	void NextPhoneGame()
	{
		if(HasControl())
			CrumbNextPhoneGame(PhoneGameIndex);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSetStartingPhoneGame(int CurrentPhoneGameIndex)
	{
		PhoneGameIndex = CurrentPhoneGameIndex;

		if(PhoneGameIndex >= 3)
			bPhoneCalled = true;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbNextPhoneGame(int CurrentPhoneGameIndex)
	{
		PhoneGameIndex = CurrentPhoneGameIndex;

		if(CurrentGame != nullptr)
		{
			ScreenWidget.RemoveWidget(CurrentGame);
		}

		PhoneGameIndex++;

		if (PhoneGameIndex >= PhoneGames.Num())
		{
			bPhoneCompleted = true;
			return;
		}

		if(NextGame == nullptr)
		{
			auto PhoneGame = Cast<USkylinePhoneGameWidget>(Widget::CreateWidget(ScreenWidget, PhoneGames[PhoneGameIndex]));
			CurrentGame = PhoneGame;
		}
		else
		{
			CurrentGame = NextGame;
			Timer::SetTimer(this, n"UnloadBottomLayerWidget", 0.1);
		}

		CurrentGame.Phone = this;
		CurrentGame.bGameActive = true;
		CurrentGame.OnGameStarted();
		GameWidgetComp.SetWidget(CurrentGame);

		if(PhoneGameIndex == PhoneGames.Num() -1)
		{
			bPhoneCompleted = true;
		}

		if(PhoneGameIndex == 0)
		{
			NextGame = Cast<USkylinePhoneGameWidget>(Widget::CreateWidget(ScreenWidget, PhoneGames[PhoneGameIndex+1]));
			NextGameWidgetComp.SetWidget(NextGame);
		}

		OnGameChanged.Broadcast(PhoneGameIndex);
		bProgressMadeSinceLastLoad = true;
	}

	private void CallPhone()
	{
		if (bPhoneCalled)
			return;

		bPhoneCalled = true;
	}
};