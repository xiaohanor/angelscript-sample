namespace SummitRaft
{
	UFUNCTION()
	AWaveRaft GetWaveRaft()
	{
		return TListedActors<AWaveRaft>().Single;
	}

	UFUNCTION()
	APaddleRaft GetPaddleRaft()
	{
		return TListedActors<APaddleRaft>().Single;
	}

	UFUNCTION()
	void ShowPaddleRaftTutorial()
	{
		USummitRaftPaddleComponent::Get(Game::Mio).bShowTutorial = true;
		USummitRaftPaddleComponent::Get(Game::Zoe).bShowTutorial = true;
	}

	UFUNCTION()
	void FlyMioToActor(AActor TargetActor)
	{
		USummitMioFakeFlyingComponent::Get(Game::Mio).FlyTowardsPoint(TargetActor.ActorLocation);
	}

	UFUNCTION()
	void QueueFakePaddleStrokes(int NumStrokes, float TimeBetweenFakePaddleStrokes)
	{
		UPaddleRaftPlayerComponent::Get(Game::Mio).NumQueuedFakePaddleStrokes = NumStrokes;
		UPaddleRaftPlayerComponent::Get(Game::Mio).TimeBetweenFakePaddleStrokes = TimeBetweenFakePaddleStrokes;
		UPaddleRaftPlayerComponent::Get(Game::Zoe).NumQueuedFakePaddleStrokes = NumStrokes;
		UPaddleRaftPlayerComponent::Get(Game::Zoe).TimeBetweenFakePaddleStrokes = TimeBetweenFakePaddleStrokes;
	}

	UFUNCTION()
	void WaveRaftSetupPaddlesForSequence()
	{
		Game::Mio.BlockCapabilities(SummitRaftTags::Paddle, n"CrashSequence");
		Game::Zoe.BlockCapabilities(SummitRaftTags::Paddle, n"CrashSequence");

		auto MioComp = USummitRaftPaddleComponent::Get(Game::Mio);
		auto ZoeComp = USummitRaftPaddleComponent::Get(Game::Zoe);
		MioComp.ApplyAnimationState(ERaftPaddleAnimationState::LeftSidePaddle, n"CrashSequence", EInstigatePriority::Cutscene);
		ZoeComp.ApplyAnimationState(ERaftPaddleAnimationState::RightSidePaddle, n"CrashSequence", EInstigatePriority::Cutscene);
		MioComp.bLastPaddledLeft = true;
		ZoeComp.bLastPaddledLeft = false;
	}

	/**
	 * Show tutorial until action is held for duration or enough time passes.
	 * @param Player - Player to show the tutorial for.
	 * @param Action - The tutorial action to show.
	 * @param Text - Text to display next to the action.
	 * @param HoldDurationRealTime = The time the action should be held for the complete event to fire.
	 * @param MaxDurationRealTime = The time before the timeout event fires and the prompt is removed. Negative value will never timeout and only by holding the action.
	 */
	UFUNCTION(Meta = (UseExecPins, ExpandToEnum = "Action", ExpandedEnum = "/Script/Angelscript.ActionNames"))
	void ShowTutorialPromptUntilHeldForDuration(AHazePlayerCharacter Player, FName Action, FText Text, float HoldDurationRealTime, float MaxDurationRealTime = -1, FSummitRaftPlayerTutorialCompleteEvent OnCompleted = FSummitRaftPlayerTutorialCompleteEvent(), FSummitRaftPlayerTutorialTimeoutEvent OnTimedout = FSummitRaftPlayerTutorialTimeoutEvent())
	{
		FTutorialPrompt Prompt;
		Prompt.Action = Action;
		Prompt.DisplayType = ETutorialPromptDisplay::ActionHold;
		Prompt.Mode = ETutorialPromptMode::Default;
		Prompt.Text = Text;
		USummitRaftPlayerDragonTutorialComponent::Get(Player).ShowTutorialPromptUntilHeldForDuration(Prompt, HoldDurationRealTime, MaxDurationRealTime, OnCompleted, OnTimedout);
	}

	/**
	 * Show tutorial until action is held for duration or enough time passes.
	 * @param Player - Player to show the tutorial for.
	 * @param Action - The tutorial action to show.
	 * @param Text - Text to display next to the action.
	 * @param HoldDurationRealTime = The time the action should be held for the complete event to fire.
	 * @param MaxDurationRealTime = The time before the timeout event fires and the prompt is removed. Negative value will never timeout and only by holding the action.
	 */
	UFUNCTION(Meta = (UseExecPins, ExpandToEnum = "Action", ExpandedEnum = "/Script/Angelscript.ActionNames"))
	void ShowTutorialPromptWorldSpaceUntilHeldForDuration(AHazePlayerCharacter Player,
		FName Action,
		FText Text,
		float HoldDurationRealTime,
		float MaxDurationRealTime = -1,
		USceneComponent AttachComponent = nullptr,
		FVector AttachOffset = FVector(0.0, 0.0, 176.0),
		float ScreenSpaceOffset = 100.0,
		FName AttachSocket = NAME_None,
		FSummitRaftPlayerTutorialCompleteEvent OnCompleted = FSummitRaftPlayerTutorialCompleteEvent(),
		FSummitRaftPlayerTutorialTimeoutEvent OnTimedout = FSummitRaftPlayerTutorialTimeoutEvent())
	{
		FTutorialPrompt Prompt;
		Prompt.Action = Action;
		Prompt.DisplayType = ETutorialPromptDisplay::ActionHold;
		Prompt.Mode = ETutorialPromptMode::Default;
		Prompt.Text = Text;
		USummitRaftPlayerDragonTutorialComponent::Get(Player).ShowTutorialPromptWorldSpaceUntilHeldForDuration(Prompt, HoldDurationRealTime, MaxDurationRealTime, AttachComponent, AttachOffset, ScreenSpaceOffset, AttachSocket, OnCompleted, OnTimedout);
	}

	const EObjectTypeQuery WaterTraceObjectType = EObjectTypeQuery::WorldStatic;
	const ECollisionChannel WaterTraceChannel = ECollisionChannel::WeaponTracePlayer;
	const ECollisionChannel RaftCollisionChannel = ECollisionChannel::ECC_WorldStatic;
}