event void FIslandGunRangeScoreCountSignature();

class AIslandGunRangeScoreCount : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UWidgetComponent WidgetComp;

	UIslandGunRangeScoreWidget Widget;

	UPROPERTY()
	UNiagaraSystem Effect;

	UPROPERTY()
	UNiagaraSystem OneStarEffect;

	UPROPERTY()
	UNiagaraSystem TwoStarEffect;

	UPROPERTY()
	FIslandGunRangeScoreCountSignature OnGunRangeCompleted;

	float CurrentScore;

	UPROPERTY()
	int CurrentStar = 0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<AIslandGunRangeTarget> GunTargets;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<AIslandGunRangeTarget> GunTargetsPhaseOne;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<AIslandGunRangeTarget> GunTargetsPhaseTwo;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<AIslandGunRangeTarget> GunTargetsPhaseThree;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<AIslandGunRangeTarget> GunTargetsPhaseFour;

	UPROPERTY(EditInstanceOnly)
	AKineticMovingActor MovingShieldRef;

	int OneStarScore = 500;
	int TwoStarScore = 750;
	int ThreeStarScore = 1000;

	// int OneStarScore = 50;
	// int TwoStarScore = 75;
	// int ThreeStarScore = 100;

	bool bIsActivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Widget = Cast<UIslandGunRangeScoreWidget>(WidgetComp.Widget);
	}

	UFUNCTION(DevFunction)
	void DevIncreaseStars()
	{
		float NewScore = OneStarScore;

		if(CurrentStar == 1)
			NewScore = TwoStarScore;
		if(CurrentStar >= 2)
			NewScore = ThreeStarScore;

		UpdateDisplay(NewScore - CurrentScore);
	}

	UFUNCTION(DevFunction)
	void DevDecreaseStars()
	{
		float NewScore = 0;

		if(CurrentStar == 2)
			NewScore = OneStarScore;
		if(CurrentStar == 3)
			NewScore = TwoStarScore;

		UpdateDisplay(NewScore - CurrentScore);
	}

	UFUNCTION()
	void UpdateDisplay(float Score)
	{

		CurrentScore = CurrentScore + Score;

		int ScoreTotal = Math::FloorToInt(CurrentScore);
		Widget.SetScore(ScoreTotal);

		if (CurrentScore < OneStarScore)
		{
			CurrentStar = 0;
			Widget.SetStarCount(CurrentStar);
			return;
		}

		if (CurrentScore >= ThreeStarScore)
		{
			CurrentStar = 3;
			Widget.SetStarCount(CurrentStar);
			UIslandGunRangeScoreEventHandler::Trigger_OnThreeStars(this);
			return;
		}

		if (CurrentScore >= TwoStarScore)
		{
			CurrentStar = 2;
			Widget.SetStarCount(CurrentStar);
			UIslandGunRangeScoreEventHandler::Trigger_OnTwoStars(this);
			return;
		}

		if (CurrentScore >= OneStarScore)
		{
			CurrentStar = 1;
			Widget.SetStarCount(CurrentStar);
			UIslandGunRangeScoreEventHandler::Trigger_OnOneStar(this);
			return;
		}

	}

	UFUNCTION()
	void ResetScore(AHazePlayerCharacter Player)
	{
		DisableAllPhases();

		CurrentScore = 0;
		CurrentStar = 0;
		Widget.Reset();
		// Only start the gun range if a player started the interaction.
		if (Player == nullptr)
			return;

		FIslandGunRangeActivatedParams Params;
		Params.Player = Player;
		UIslandGunRangeScoreEventHandler::Trigger_OnGunFireRangeActivated(this, Params);
		ActivateGunFireRange();
	}

	UFUNCTION()
	void OnCompleted(int Stars)
	{
		FIslandGunRangeScoreOnCompletedParams EventParams;
		EventParams.StarAmount = Stars;

		DisableAllPhases();

		UIslandGunRangeScoreEventHandler::Trigger_OnCompleted(this, EventParams);
		OnGunRangeCompleted.Broadcast();
		Widget.OnCompleted();
		BP_OnCompleted(Stars);
	}

	UFUNCTION()
	void ActivateGunFireRange()
	{
		bIsActivated = true;

		Timer::SetTimer(this, n"ActivatePhaseOne", SMALL_NUMBER);
		Timer::SetTimer(this, n"DeactivatePhaseOne", 16);

		Timer::SetTimer(this, n"ActivatePhaseTwo", 1);
		Timer::SetTimer(this, n"DeactivatePhaseTwo", 10);

		Timer::SetTimer(this, n"ActivatePhaseThree", 5);
		Timer::SetTimer(this, n"DeactivatePhaseThree", 19);

		Timer::SetTimer(this, n"ActivateShields", 10);
		Timer::SetTimer(this, n"DeactivateShields", 19.2);
		
		Timer::SetTimer(this, n"ActivatePhaseFour", 11.2);
		Timer::SetTimer(this, n"DeactivatePhaseFour", 19.2);

	}

	UFUNCTION()
	void StartPhase(int Phase)
	{

		switch (Phase)
		{
			case 0:
			{
				for (auto Child : GunTargetsPhaseOne)
				{
					Child.ActivateTarget();
				}

				break;
			}
			
			case 1:
			{
				for (auto Child : GunTargetsPhaseTwo)
				{
					Child.ActivateTarget();
				}
				break;
			}

			case 2:
			{
				for (auto Child : GunTargetsPhaseThree)
				{
					Child.ActivateTarget();
				}
				break;
			}

			case 3:
			{
				for (auto Child : GunTargetsPhaseFour)
				{
					Child.ActivateTarget();
				}
				break;
			}

			default:
				break;
		}

	}

	UFUNCTION()
	void DisablePhase(int Phase)
	{

		switch (Phase)
		{
			case 0:
			{
				for (auto Child : GunTargetsPhaseOne)
				{
					Child.DeactivateTarget();
				}

				break;
			}
			
			case 1:
			{
				for (auto Child : GunTargetsPhaseTwo)
				{
					Child.DeactivateTarget();
				}
				break;
			}

			case 2:
			{
				for (auto Child : GunTargetsPhaseThree)
				{
					Child.DeactivateTarget();
				}
				break;
			}

			case 3:
			{
				for (auto Child : GunTargetsPhaseFour)
				{
					Child.DeactivateTarget();
				}
				break;
			}

			default:
				break;
		}

	}

	UFUNCTION()
	void DisableAllPhases()
	{
		
		bIsActivated = false;

		Timer::ClearTimer(this, n"ActivatePhaseOne");
		Timer::ClearTimer(this, n"DeactivatePhaseOne");
		Timer::ClearTimer(this, n"ActivatePhaseTwo");
		Timer::ClearTimer(this, n"DeactivatePhaseTwo");
		Timer::ClearTimer(this, n"ActivatePhaseThree");
		Timer::ClearTimer(this, n"DeactivatePhaseThree");
		Timer::ClearTimer(this, n"ActivatePhaseFour");
		Timer::ClearTimer(this, n"DeactivatePhaseFour");
		Timer::ClearTimer(this, n"ActivateShields");
		Timer::ClearTimer(this, n"DeactivateShields");

		DisablePhase(0);
		DisablePhase(1);
		DisablePhase(2);
		DisablePhase(3);
		DeactivateShields();
	}

	UFUNCTION()
	void ActivatePhaseOne()
	{
		StartPhase(0);
		Print("Start Phase One");
	}

	UFUNCTION()
	void ActivatePhaseTwo()
	{
		StartPhase(1);
		Print("Start Phase Two");
	}

	UFUNCTION()
	void ActivatePhaseThree()
	{
		StartPhase(2);
		Print("Start Phase Three");
	}

	UFUNCTION()
	void ActivatePhaseFour()
	{
		StartPhase(3);
		Print("Start Phase Four");
	}

	UFUNCTION()
	void DeactivatePhaseOne()
	{
		DisablePhase(0);
	}

	UFUNCTION()
	void DeactivatePhaseTwo()
	{
		DisablePhase(1);
	}

	UFUNCTION()
	void DeactivatePhaseThree()
	{
		DisablePhase(2);
	}

	UFUNCTION()
	void DeactivatePhaseFour()
	{
		DisablePhase(3);
		OnCompleted(CurrentStar);
	}

	UFUNCTION()
	void ActivateShields()
	{
		MovingShieldRef.ActivateForward();
	}

	UFUNCTION()
	void DeactivateShields()
	{
		MovingShieldRef.ReverseBackwards();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnCompleted(int StarAmount) {}

}