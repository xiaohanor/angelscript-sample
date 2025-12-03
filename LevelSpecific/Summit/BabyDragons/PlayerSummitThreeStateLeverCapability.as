class UPlayerSummitThreeStateLeverCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;

	ASummitThreeStateLever CurrentLever;

	FVector PreviousMoveInput;

	// Settings
	const float MoveSpeed = 400.0;
	// If stick is moved more than this amount, will count as triggered
	const float MinInputTriggerSize = 0.9;
	// How long it will take for the lever to move between states
	const float LeverMoveDuration = 0.5;
	// How fast the player rotates correctly
	const float RotationInterpSpeed = 11.0;

	const float EnterDuration = 0.7;

	bool bPossibleToMove = true;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		CurrentLever = Cast<ASummitThreeStateLever>(Params.Interaction.Owner);

		// If it does not start disabled it sets its initial state itself
		if(CurrentLever.bStartDisabled)
			CurrentLever.CrumbChangeState(CurrentLever.InitialState);

		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRight;
		TutorialPrompt.Text = NSLOCTEXT("Three State Lever", "Move Lever", "Move Lever to Control Waterfall");
		Player.ShowTutorialPrompt(TutorialPrompt, this);

		Player.ApplyOtherPlayerIndicatorMode(EOtherPlayerIndicatorMode::AlwaysVisible, this, EInstigatePriority::High);
		Player.AddLocomotionFeature(CurrentLever.LeverFeature, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.RemoveLocomotionFeature(CurrentLever.LeverFeature, this);

		Player.RemoveTutorialPromptByInstigator(this);

		Player.ClearOtherPlayerIndicatorMode(this);

		if(CurrentLever.bResetToInitialWhenExiting)
			CurrentLever.CrumbChangeState(CurrentLever.InitialState, LeverMoveDuration);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.RequestLocomotion(n"ThreeStateLever", this);
		Player.SetAnimFloatParam(n"ThreeStateLeverBlendSpaceAlpha", CurrentLever.GetBlendAlpha());

		if(ActiveDuration < EnterDuration)
			return;

		FVector2D MovementRaw = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		
		if(!bPossibleToMove && MovementRaw.Size() < MinInputTriggerSize)
			bPossibleToMove = true;

		if(bPossibleToMove && MovementRaw.Size() > MinInputTriggerSize)
		{
			Player.RemoveTutorialPromptByInstigator(this);
			if(MovementRaw.Y > 0.0)
			{
				// Right
				if(CurrentLever.TargetState < ESummitThreeStateLeverState::Right)
				{
					CurrentLever.CrumbChangeState(ESummitThreeStateLeverState(int(CurrentLever.TargetState) + 1), LeverMoveDuration);
					bPossibleToMove = false;
				}
			}
			else
			{
				// Left
				if(CurrentLever.TargetState > ESummitThreeStateLeverState::Left)
				{
					CurrentLever.CrumbChangeState(ESummitThreeStateLeverState(int(CurrentLever.TargetState) - 1), LeverMoveDuration);
					bPossibleToMove = false;
				}
			}
		}
		
	}
}