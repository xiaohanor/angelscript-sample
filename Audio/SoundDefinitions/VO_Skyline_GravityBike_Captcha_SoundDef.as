
UCLASS(Abstract)
class UVO_Skyline_GravityBike_Captcha_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	ASkylineNewPhone Phone;

	FVector2D PreviousCursorLocation;

	UPROPERTY(BlueprintReadOnly)
	float HandMovementDelta;

	UPROPERTY(BlueprintReadOnly)
	float LockScreenProgress = 0.0;

	UPROPERTY(BlueprintReadOnly)
	float FaceRecognitionProgress = 0.0;

	UPROPERTY(BlueprintReadOnly)
	float InfiniteLoadingScreenProgress = 0.0;

	UPROPERTY()
	int PreviousCountdownStep = -1;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Phone = Cast<ASkylineNewPhone>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		auto Mio = Game::GetMio();
		if(Mio == nullptr)
			return false;

		if(Mio.IsPlayerDead())
			return false;

		if(Mio.bIsParticipatingInCutscene)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		auto Mio = Game::GetMio();
		if(Mio == nullptr)
			return true;

		if(Mio.IsPlayerDead())
			return true;

		if(Mio.bIsParticipatingInCutscene)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintEvent)
	void StopCurrentGame() {};

	UFUNCTION(BlueprintEvent)
	void StartLockScreen() {};

	UFUNCTION(BlueprintEvent)
	void StartFaceRecognition() {};

	UFUNCTION(BlueprintEvent)
	void StartPhoneCall() {};

	UFUNCTION(BlueprintEvent)
	void OnPhoneCallAccepted() {};

	UFUNCTION(BlueprintEvent)
	void OnPhoneCallDeclined() {};

	UFUNCTION(BlueprintEvent)
	void StartInfiniteLoadingScreen() {};

	UFUNCTION(BlueprintEvent)
	void OnCorrectInput() {};

	UFUNCTION(BlueprintEvent)
	void OnIncorrectInput() {};

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (Phone != nullptr && Phone.TimeLeft >= 60)
		{
			// So the 60 mark line is triggered.
			PreviousCountdownStep = -2;
		}
		// Otherwise ignore the first in between point and wait for the next 10 second mark.
		else
		{
			PreviousCountdownStep = -1;
		}

		Phone.OnGameChanged.AddUFunction(this, n"OnGameChanged");
		OnGameChanged(Phone.PhoneGameIndex);		
	}

	UFUNCTION()
	void OnGameChanged(int NewGameIndex)
	{
		StopCurrentGame();
		if(Phone.CurrentGame == nullptr)
			return;

		switch(NewGameIndex)
		{
			case(0): StartLockScreen(); break;
			case(1): StartFaceRecognition(); break;
			case(2): 
					Cast<USkylinePhoneCaptchaGameWidget>(Phone.CurrentGame).OnAnswerCorrect.AddUFunction(this, n"OnCorrectInput");
			 		Cast<USkylinePhoneCaptchaGameWidget>(Phone.CurrentGame).OnAnswerIncorrect .AddUFunction(this, n"OnIncorrectInput");
			break;
			case(3): 
					Cast<USkylinePhoneRulesWidget>(Phone.CurrentGame).OnInputAccepted.AddUFunction(this, n"OnCorrectInput");
			 		Cast<USkylinePhoneRulesWidget>(Phone.CurrentGame).OnInputRejected.AddUFunction(this, n"OnIncorrectInput");
			break;
			case(4): StartPhoneCall();
					Cast<USkylinePhoneCallWidget>(Phone.CurrentGame).OnCallAccepted.AddUFunction(this, n"OnPhoneCallAccepted");
			 		Cast<USkylinePhoneCallWidget>(Phone.CurrentGame).OnCallDeclined .AddUFunction(this, n"OnPhoneCallDeclined");
			break;
			case(5): 
					Cast<USkylinePhoneRulesWidget>(Phone.CurrentGame).OnInputAccepted.AddUFunction(this, n"OnCorrectInput");
			 		Cast<USkylinePhoneRulesWidget>(Phone.CurrentGame).OnInputRejected.AddUFunction(this, n"OnIncorrectInput");
			break;
			case(6): 
					Cast<USkylinePhoneWritingWidget>(Phone.CurrentGame).OnInputAccepted.AddUFunction(this, n"OnCorrectInput");
			 		Cast<USkylinePhoneWritingWidget>(Phone.CurrentGame).OnInputRejected.AddUFunction(this, n"OnIncorrectInput");
			break;
			case(7): StartInfiniteLoadingScreen(); break;

			default: break;			
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(Phone.CurrentGame == nullptr)
			return;

		// Hand Movement
		const FVector2D CursorLocation = Phone.CursorPosition.GetValue();
		HandMovementDelta = Math::Saturate(((CursorLocation - PreviousCursorLocation).Size() / DeltaSeconds) / 1000);
		PreviousCursorLocation = CursorLocation;	

		// Update data from games
		switch(Phone.PhoneGameIndex)
		{
			case(0):
			{
				LockScreenProgress = Cast<USkylinePhoneLockScreenWidget>(Phone.CurrentGame).Progress; 
				break;
			}
			case(1):
			{
				FaceRecognitionProgress = Cast<USkylinePhoneGameFaceRecognitionWidget>(Phone.CurrentGame).ScanProgress; 
				break;
			}
			case(7):
			{
				InfiniteLoadingScreenProgress = Cast<USkylinePhoneLoadingScreenWidget>(Phone.CurrentGame).LoadingPercentage; 
				break;
			}
				
			default: break;
		}
		
		// For the last stretch of time, trigger countdown line just before each 10 second mark.
		const float TimeOffset = 1.5;
		if (Phone != nullptr && Phone.TimeLeft <= 60 + TimeOffset)
		{
			auto NextStep = Math::Clamp(6. - ((Phone.TimeLeft-TimeOffset) / 10), 0, 6);
			auto IntStep = int(NextStep);

			if (IntStep != PreviousCountdownStep)
			{
				if ((PreviousCountdownStep != -1 && IntStep < 5))
					OnTimeleftCountdown(IntStep);
				PreviousCountdownStep = IntStep;
			}
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnTimeleftCountdown(int OutStep) {}
}