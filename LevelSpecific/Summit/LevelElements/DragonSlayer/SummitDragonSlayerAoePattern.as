event void FASummitDragonSlayerAoePatternSignature();

class ASummitDragonSlayerAoePattern : AHazeActor
{
	UPROPERTY()
	FASummitDragonSlayerAoePatternSignature OnFinished;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<ASummitDragonSlayerAoeZone> Children;

	int ChildCount;

	UPROPERTY(EditAnywhere)
	float TelegraphDuration = 4.5;
	float ActiveDuration = 0.00001;
	float AnimationDuration;

	bool bActive;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	AAISummitKnight Boss;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (auto Child : Children)
		{
			AnimationDuration = Child.MoveAnimation.Duration;
			return;
		}
	}

	UFUNCTION()
	void StartAoePattern()
	{
		if (bActive)
			return;

		Boss = TListedActors<AAISummitKnight>().GetSingle();
		bActive = true;

		for (auto Child : Children)
		{
			Child.ActivateAoeZone();
			ChildCount++;
		}

		Timer::SetTimer(this, n"AttackFinished", ActiveDuration + TelegraphDuration + AnimationDuration);
		Timer::SetTimer(this, n"TelegraphFinished", TelegraphDuration  - AnimationDuration);	
		
	}

	UFUNCTION()
	void AttackFinished()
	{
		bActive = false;
		OnFinished.Broadcast();
	}

	UFUNCTION()
	void TelegraphFinished()
	{
		for (auto Child : Children)
		{
			Child.ActivateAttack();
		}

		USummitKnightEventHandler::Trigger_OnLargeAreaStrikePatternImpact(Boss, FSummitKnightLargeAreaStrikeParams(this));	

		if (ForceFeedback != nullptr)
		{
			Game::GetMio().PlayForceFeedback(ForceFeedback, false, false, this);
			Game::GetZoe().PlayForceFeedback(ForceFeedback, false, false, this);
		}
		Game::Mio.PlayWorldCameraShake(CameraShake, this, Game::Mio.ActorLocation, 1000, 4000);
		Game::Zoe.PlayWorldCameraShake(CameraShake, this, Game::Zoe.ActorLocation, 1000, 4000);
	}

};