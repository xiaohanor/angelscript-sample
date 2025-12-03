class ASummitTopDownLift : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USummitMovablePlatformFloatinessComponent FloatinessComp;
	default FloatinessComp.FloatComponentName = n"FloatinessRoot";

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	bool bButtonOneIsPressed = false;
	bool bButtonTwoIsPressed = false;

	TPerPlayer<bool> IsOnLeftButton;
	TPerPlayer<bool> IsOnRightButton;

	UPROPERTY()
	bool bIsDisabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto LeftButtonTrigger = UHazeMovablePlayerTriggerComponent::Get(this, n"LeftButtonTrigger");

		LeftButtonTrigger.OnPlayerEnter.AddUFunction(this, n"OnLeftButtonEntered");
		LeftButtonTrigger.OnPlayerLeave.AddUFunction(this, n"OnLeftButtonPlayerLeft");

		auto RightButtonTrigger = UHazeMovablePlayerTriggerComponent::Get(this, n"RightButtonTrigger");

		RightButtonTrigger.OnPlayerEnter.AddUFunction(this, n"OnRightButtonEntered");
		RightButtonTrigger.OnPlayerLeave.AddUFunction(this, n"OnRightButtonPlayerLeft");
	}

	UFUNCTION()
	private void OnLeftButtonEntered(AHazePlayerCharacter Player)
	{
		if(bIsDisabled)
			return;

		IsOnLeftButton[Player] = true;
		if(!bButtonOneIsPressed)
			ToggleButtonOne(true);
	}

	UFUNCTION()
	private void OnLeftButtonPlayerLeft(AHazePlayerCharacter Player)
	{
		if(bIsDisabled)
			return;

		IsOnLeftButton[Player] = false;
		if(!IsOnLeftButton[Player.OtherPlayer])
			ToggleButtonOne(false);
	}

	UFUNCTION()
	private void OnRightButtonEntered(AHazePlayerCharacter Player)
	{
		if(bIsDisabled)
			return;

		IsOnRightButton[Player] = true;
		if(!bButtonTwoIsPressed)
			ToggleButtonTwo(true);
	}

	UFUNCTION()
	private void OnRightButtonPlayerLeft(AHazePlayerCharacter Player)
	{
		if(bIsDisabled)
			return;

		IsOnRightButton[Player] = false;
		if(!IsOnRightButton[Player.OtherPlayer])
			ToggleButtonTwo(false);
	}

	void ToggleButtonOne(bool bToggleOn)
	{
		bButtonOneIsPressed = bToggleOn;
		if(bToggleOn)
			BP_OnLeftButtonPressed();
		else
			BP_OnLeftButtonUnPressed();
		if(HasControl())
		{
			if(bToggleOn
			&& bButtonTwoIsPressed)
				CrumbActivateElevator();
		}
	}

	void ToggleButtonTwo(bool bToggleOn)
	{
		bButtonTwoIsPressed = bToggleOn;
		if(bToggleOn)
			BP_OnRightButtonPressed();
		else
			BP_OnRightButtonUnPressed();
		if(HasControl())
		{
			if(bToggleOn
			&& bButtonOneIsPressed)
				CrumbActivateElevator();
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbActivateElevator()
	{
		BP_OnElevatorActivated();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnElevatorActivated() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnLeftButtonPressed() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnLeftButtonUnPressed() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnRightButtonPressed() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnRightButtonUnPressed() {}

	UFUNCTION(BlueprintCallable)
	void OnStartedMoving()
	{
		USummitTopDownLiftEventHandler::Trigger_OnStartedMoving(this);
	}

	UFUNCTION(BlueprintCallable)
	void OnStoppedMoving()
	{
		USummitTopDownLiftEventHandler::Trigger_OnStoppedMoving(this);
	}

	UFUNCTION(BlueprintCallable)
	void OnButtonStartMoving()
	{
		USummitTopDownLiftEventHandler::Trigger_OnButtonStartedMoving(this);
	}

	UFUNCTION(BlueprintCallable)
	void OnButtonStopMoving()
	{
		USummitTopDownLiftEventHandler::Trigger_OnButtonStopMoving(this);
	}

	UFUNCTION(BlueprintCallable)
	void ToggleDisabled(bool bDisable)
	{
		bIsDisabled = bDisable;
	}
};