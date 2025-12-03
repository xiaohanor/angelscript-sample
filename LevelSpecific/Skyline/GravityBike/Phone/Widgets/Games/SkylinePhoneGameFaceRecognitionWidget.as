UCLASS(Abstract)
class USkylinePhoneGameFaceRecognitionWidget : USkylinePhoneGameWidget
{
	UPROPERTY(BindWidget)
	UImage FaceTex;

	UPROPERTY(BindWidget)
	UProgressBar ProgressBar;

	int ScanDotsAmount = 3;
	float ScanProgress = 0;
	float ScanSpeed = 0.5;

	bool bInRange = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		ProgressBar.SetPercent(ScanProgress);
	}

	void OnGameStarted() override
	{
		Super::OnGameStarted();
		Phone.BroadcastGameEvent(ESkylinePhoneGameEvent::FaceRecognition);
		Phone.ScreenWidget.CursorOverlay.SetRenderOpacity(0);
		Phone.XInputSensitivityOverride.Set(1);
		Phone.YInputSensitivityOverride.Set(3);
		Phone.FaceRecognitionSceneComp.SetVisibility(true, true);

		Phone.SceneCapture.bCaptureEveryFrame = true;

		if(Phone.SceneCapture.ShowOnlyActors.IsEmpty())
		{
			Phone.SceneCapture.ShowOnlyActorComponents(Game::Zoe);

			if(TListedActors<ASkylinePhoneProgressSpline>().GetSingle() != nullptr)
			{

				for(AActor ActorToRender : TListedActors<ASkylinePhoneProgressSpline>().GetSingle().ActorsToRenderFaceRecognition)
				{
					if(ActorToRender == nullptr)
					{
						PrintWarning("Face rec actor to render was nullptr, skipping");
						continue;
					}

					Phone.SceneCapture.ShowOnlyActorComponents(ActorToRender);
				}
			}
		}
	}

	void GameComplete() override
	{
		Super::GameComplete();
		Phone.PlaySuccessForceFeedback();
		Phone.ScreenWidget.CursorOverlay.SetRenderOpacity(1);
		Phone.XInputSensitivityOverride.Reset();
		Phone.YInputSensitivityOverride.Reset();
		Phone.FaceRecognitionSceneComp.SetVisibility(false, true);
		Phone.SceneCapture.bCaptureEveryFrame = false;
	}

	UFUNCTION(BlueprintPure)
	FText GetScanText()
	{
		FText Text = NSLOCTEXT("PhoneGame", "FaceScan", "Scanning face");
		FString String = Text.ToString();

		for(int i = 0; i < ScanDotsAmount; i++)
		{
			String.Append(".");
		}
		
		Text = FText::FromString(String);
		
		ScanDotsAmount++;
		if(ScanDotsAmount >= 4)
			ScanDotsAmount = 1;

		return Text;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if(!bGameActive)
			return;

		ProgressBar.SetPercent(ScanProgress);

		const float AcceptedRange = 0.15;
		bInRange = true;

		if(Math::Abs((((Phone.CursorPosition.Value.X / Phone.CursorBounds.X) + 1) / 2) - 0.3) > AcceptedRange)
			bInRange = false;
		else if(Math::Abs((((Phone.CursorPosition.Value.Y / Phone.CursorBounds.Y) + 1) / 2) - 0.45) > AcceptedRange)
			bInRange = false;

		if(bInRange)
			ScanProgress = Math::FInterpConstantTo(ScanProgress, 1, InDeltaTime, ScanSpeed);
		else
			ScanProgress = Math::FInterpConstantTo(ScanProgress, 0, InDeltaTime, ScanSpeed);


		if(ScanProgress == 1)
			GameComplete();
	}
}