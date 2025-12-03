UCLASS(Abstract)
class USkylinePhoneLockScreenWidget : USkylinePhoneGameWidget
{
	UPROPERTY(BindWidget)
	UCanvasPanel Canvas;

	FVector2D InitialClickLocation;

	const float ScaleIncrease = 0.5;
	const float RequiredSwipeLength = 300;

	FHazeAcceleratedFloat Translation;

	float Progress = 0;

	bool bIsTransitioning = false;

	bool bTutorialActive = true;

	void OnGameStarted() override
	{
		Super::OnGameStarted();
		Phone.BroadcastGameEvent(ESkylinePhoneGameEvent::LockScreen);
		Phone.XInputSensitivityOverride.Set(2);
		
		FTutorialPrompt Prompt;
		Prompt.Mode = ETutorialPromptMode::Default;
		Prompt.DisplayType = ETutorialPromptDisplay::Action;
		Prompt.Action = ActionNames::PrimaryLevelAbility;
		Prompt.Text = NSLOCTEXT("Phone", "TapPhone", "Tap");
		Game::Zoe.ShowTutorialPrompt(Prompt, this);
		bTutorialActive = true;

		Phone.SceneCapture.bCaptureEveryFrame = true;
		Phone.SceneCapture.ShowOnlyActorComponents(Game::Zoe);

		for(auto ActorToRender : TListedActors<ASkylinePhoneProgressSpline>().GetSingle().ActorsToRenderFaceRecognition)
		{
			Phone.SceneCapture.ShowOnlyActorComponents(ActorToRender);
		}
	}

	void GameComplete() override
	{
		Phone.XInputSensitivityOverride.Reset();
		Phone.PlaySuccessForceFeedback();
		Super::GameComplete();
	}

	void OnClick(FVector2D CursorPos) override
	{
		Super::OnClick(CursorPos);
		InitialClickLocation = CursorPosition;

		if(bTutorialActive)
		{
			Game::Zoe.RemoveTutorialPromptByInstigator(this);
			bTutorialActive = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if(bIsTransitioning)
		{
			float Sign = Math::Sign(Translation.Value);
			Translation.SpringTo(900 * Sign, 200, 1, InDeltaTime);

			if(Math::Abs(Translation.Value) >= 800)
			{
				GameComplete();
			}
		}
		else
		{
			if(bIsClickHeld)
			{
				float SwipedLength = CursorPosition.X - InitialClickLocation.X;
				Translation.SpringTo(SwipedLength, 200, 1, InDeltaTime);
				Progress = Math::Saturate(Math::Abs(SwipedLength) / RequiredSwipeLength);
				
				if(Progress == 1)
				{
					bIsTransitioning = true;
				}
			}
			else
			{
				Translation.SpringTo(0, 200, 1, InDeltaTime);
			}
		}

		Canvas.SetRenderTranslation(FVector2D(Translation.Value, 0));
	}
}