event void FASummitDragonSlayerAoeManagerSignature();

class ASummitDragonSlayerAoeManager : AHazeActor
{
	UPROPERTY()
	FASummitDragonSlayerAoeManagerSignature OnFinished;

	UPROPERTY()
	FASummitDragonSlayerAoeManagerSignature OnStarted;

	UPROPERTY()
	FASummitDragonSlayerAoeManagerSignature OnSequenceFinished;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	AAISummitKnight Boss;

	UPROPERTY(EditAnywhere)
	int LastPatternInFirstSeq;

	UPROPERTY(EditAnywhere)
	int LastPatternInSecondSeq;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<ASummitDragonSlayerAoePattern> Patterns;

	int ChildCount;

	UPROPERTY()
	int CurrentPattern;
	float TelegraphDuration;
	float ActiveDuration;

	bool bActive;
	bool bIsDisabled;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ChildCount = Patterns.Num();
		Boss = TListedActors<AAISummitKnight>().GetSingle();
	}

	UFUNCTION()
	void StartAoePattern(int ForcePattern = 0)
	{
		if (bIsDisabled)
			return;

		// if (bActive)
		// 	return;

		bActive = true;

		if (ForcePattern != 0)
			CurrentPattern = ForcePattern;
		
		if(Patterns[CurrentPattern] == nullptr)
			return;

		Patterns[CurrentPattern].StartAoePattern();
		TelegraphDuration = Patterns[CurrentPattern].TelegraphDuration;
		ActiveDuration = Patterns[CurrentPattern].ActiveDuration;

		OnStarted.Broadcast();
		USummitKnightEventHandler::Trigger_OnLargeAreaStrikePatternStart(Boss, FSummitKnightLargeAreaStrikeParams(Patterns[CurrentPattern]));

		if(CurrentPattern <= ChildCount)
			CurrentPattern++;

		Timer::SetTimer(this, n"AttackFinished", ActiveDuration + TelegraphDuration  + 0.34);
		Timer::SetTimer(this, n"TelegraphFinished", TelegraphDuration);
		
	}

	UFUNCTION()
	void AttackFinished()
	{
		bActive = false;
		OnFinished.Broadcast();

		if (CurrentPattern == LastPatternInFirstSeq || CurrentPattern == LastPatternInSecondSeq)
			OnSequenceFinished.Broadcast();

		// PrintToScreen(""+CurrentPattern+"", 10);
	}

	UFUNCTION()
	void TelegraphFinished()
	{
		if (bIsDisabled)
			return;

		if (ForceFeedback != nullptr)
		{
			Game::GetMio().PlayForceFeedback(ForceFeedback, false, false, this);
			Game::GetZoe().PlayForceFeedback(ForceFeedback, false, false, this);
		}
		Game::Mio.PlayWorldCameraShake(CameraShake, this, Game::Mio.ActorLocation, 1000, 4000);
		Game::Zoe.PlayWorldCameraShake(CameraShake, this, Game::Zoe.ActorLocation, 1000, 4000);
	}

	UFUNCTION()
	void DisableAOEAttacks()
	{
		if (bIsDisabled)
			return;

		bIsDisabled = true;

		for (auto PatternChild : Patterns)
		{
			for (auto Child : PatternChild.Children)
			{
				Child.DisableZone();
			}
		}
		
	}


};