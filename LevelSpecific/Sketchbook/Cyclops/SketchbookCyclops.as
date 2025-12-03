class ASketchbookCyclops : AHazeSkeletalMeshActor
{
	bool bIsDead = false;
	bool bHelmetOpen = false;

	UPROPERTY(DefaultComponent)
	UBoxComponent HandCollision;

	UPROPERTY(EditAnywhere, Category = "Animations")
	UAnimSequence AnimEnterFall;

	UPROPERTY(EditAnywhere, Category = "Animations")
	UAnimSequence AnimEnterLanding;

	UPROPERTY(EditAnywhere, Category = "Animations")
	UAnimSequence AnimEnterLandingMh;

	UPROPERTY(EditAnywhere, Category = "Animations")
	UAnimSequence AnimIntroduction;

	UPROPERTY(EditAnywhere, Category = "Animations")
	UAnimSequence AnimCorrectAnswer;

	UPROPERTY(EditAnywhere, Category = "Animations")
	UAnimSequence AnimWrongAnswer;

	UPROPERTY(EditAnywhere, Category = "Animations")
	UAnimSequence AnimThinking;

	UPROPERTY(EditAnywhere, Category = "Animations")
	UAnimSequence AnimTellRiddle;

	UPROPERTY(EditAnywhere, Category = "Animations")
	UAnimSequence AnimGuard;

	UPROPERTY(EditAnywhere, Category = "Animations")
	UAnimSequence AnimDie;

	UPROPERTY(EditAnywhere, Category = "Animations")
	UAnimSequence AnimDead;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect LandForceFeedback;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> LandCameraShake;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HandCollision.AttachTo(Mesh, n"RightHand", EAttachLocation::SnapToTarget);
		HandCollision.SetRelativeLocation(FVector::UpVector * 39);
		HandCollision.AddComponentCollisionBlocker(this);
		bIsDead = false;

		ASketchbookCyclopsRiddleManager RiddleManager = Sketchbook::GetRiddleManager();
		RiddleManager.Riddles[0].Answers.Last().Text.OnFinishedBeingDrawn.AddUFunction(this, n"RemoveHelmet");

		RiddleManager.SetCyclops(this);

		// Hook up animations to all of these riddle events
		if (RiddleManager.Introduction.Num() > 0)
		{
			RiddleManager.Introduction[0].OnStartBeingDrawn.AddUFunction(this, n"PlayIntroduction");
			RiddleManager.Introduction[0].OnStartBeingErased.AddUFunction(this, n"PlayThink");
		}

		for (FSketchbookCyclopsRiddle Riddle : RiddleManager.Riddles)
		{
			for (auto RiddleSentance : Riddle.RiddleSentences)
				RiddleSentance.OnStartBeingDrawn.AddUFunction(this, n"PlayTellRiddle");

			for (auto Answer : Riddle.Answers)
				Answer.OnAnswerSelected.AddUFunction(this, n"OnAnswerSelected");
		}

		for(int i = 0; i < RiddleManager.Riddles.Num(); i++)
		{
			if (RiddleManager.Riddles[i].RiddleWrong.Num() > 0)
			{
				RiddleManager.Riddles[i].RiddleWrong[0].OnStartBeingDrawn.AddUFunction(this, n"PlayWrongAnswer");
				RiddleManager.Riddles[i].RiddleWrong[0].OnFinishedBeingDrawn.AddUFunction(this, n"PlayGuard");
			}

			if (RiddleManager.Riddles[i].RiddlePassed.Num() > 0)
			{
				RiddleManager.Riddles[i].RiddlePassed[0].OnStartBeingDrawn.AddUFunction(this, n"PlayCorrectAnswer");

				if (RiddleManager.Riddles[i].RiddlePassed.Num() > 1 && i != RiddleManager.Riddles.Num() - 1)
				{
					RiddleManager.Riddles[i].RiddlePassed[1].OnStartBeingDrawn.AddUFunction(this, n"PlayGuard");
				}
			}
		}
	}

	UFUNCTION()
	private void RemoveHelmet()
	{
		bHelmetOpen = true;
	}

	private void PlayAnimation(UAnimSequence Animation, FHazeAnimationDelegate OnBlendOut = FHazeAnimationDelegate())
	{
		if (bIsDead && (Animation != AnimDie && Animation != AnimDead))
			return;

		FHazePlaySlotAnimationParams Params;
		Params.Animation = Animation;
		Params.bLoop = !OnBlendOut.IsBound();
		Params.BlendTime = 0;

		FHazeAnimationDelegate OnBlendIn;

		PlaySlotAnimation(OnBlendIn, OnBlendOut, Params);
	}

	// --------------------------------------
	// 			Animation Events
	// --------------------------------------

	UFUNCTION()
	void StartEnterAnimation(AKineticMovingActor MovingActor)
	{
		MovingActor.OnReachedForward.AddUFunction(this, n"PlayLanding");
		PlayAnimation(AnimEnterFall);
	}

	UFUNCTION()
	void PlayLanding()
	{
		for(auto Player : Game::GetPlayers())
		{
			Player.PlayForceFeedback(LandForceFeedback, false, false, this);
			Player.PlayCameraShake(LandCameraShake, this);
		}
		
		FHazeAnimationDelegate OnBlendOut;
		OnBlendOut.BindUFunction(this, n"PlayLandingMh");

		PlayAnimation(AnimEnterLanding, OnBlendOut);
	}

	UFUNCTION()
	void PlayLandingMh()
	{
		PlayAnimation(AnimEnterLandingMh);
	}

	UFUNCTION()
	void PlayIntroduction()
	{
		HandCollision.RemoveComponentCollisionBlocker(this);
		PlayAnimation(AnimIntroduction);
	}

	UFUNCTION()
	void PlayThink()
	{
		PlayAnimation(AnimThinking);
	}

	UFUNCTION()
	void PlayTellRiddle()
	{
		HandCollision.AddComponentCollisionBlocker(this);
		PlayAnimation(AnimTellRiddle);
	}

	UFUNCTION()
	void OnAnswerSelected(USketchbookCyclopsRiddleSelectableComponent Answer)
	{
		PlayThink();
	}

	UFUNCTION()
	void PlayCorrectAnswer()
	{
		PlayAnimation(AnimCorrectAnswer);
	}

	UFUNCTION()
	void PlayWrongAnswer()
	{
		PlayAnimation(AnimWrongAnswer);
	}

	UFUNCTION()
	void PlayGuard()
	{
		PlayAnimation(AnimGuard);
	}

	void Fall()
	{
		bIsDead = true;

		FHazeAnimationDelegate OnBlendOut;
		OnBlendOut.BindUFunction(this, n"OnFallComplete");

		PlayAnimation(AnimDie, OnBlendOut);
	}

	UFUNCTION()
	void OnFallComplete()
	{
		USketchbookDrawableObjectComponent DrawableComp = USketchbookDrawableObjectComponent::Get(this);
		DrawableComp.RequestErase();

		PlayAnimation(AnimDead);

		// TArray<AActor> AttachedActors;
		// GetAttachedActors(AttachedActors);

		// for (auto AttachedActor : AttachedActors)
		// 	AttachedActor.DestroyActor();
		// DestroyActor();
	}
};
