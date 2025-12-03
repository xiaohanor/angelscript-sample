class UPlayerDashTutorialCapability : UTutorialCapability
{
	UPlayerMovementComponent MoveComp;

	float StepDashActivationTime = 0;
	bool bIsInStepDash = false;
	UPlayerRollDashSettings RollDashSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RollDashSettings = UPlayerRollDashSettings::GetSettings(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!MoveComp.IsOnAnyGround())
			return false;
		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FTutorialPromptChain TutorialChain;

		FTutorialPrompt DashPrompt;
		DashPrompt.Action = ActionNames::MovementDash;
		DashPrompt.Text = NSLOCTEXT("MovementTutorial", "DashPrompt", "Dash");
		TutorialChain.Prompts.Add(DashPrompt);

		FTutorialPrompt RollPrompt;
		RollPrompt.Action = ActionNames::MovementDash;
		RollPrompt.Text = NSLOCTEXT("MovementTutorial", "DodgePrompt", "Dodge Roll");
		TutorialChain.Prompts.Add(RollPrompt);

		Player.ShowTutorialPromptChain(TutorialChain, this, 0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.IsAnyCapabilityActive(n"StepDash"))
		{
			if (!bIsInStepDash)
			{
				StepDashActivationTime = Time::GameTimeSeconds;
				bIsInStepDash = true;
			}
		}
		else
		{
			bIsInStepDash = false;
		}

		if (Time::GetGameTimeSince(StepDashActivationTime) <= RollDashSettings.MaxAvailableTimeAfterStep)
			Player.SetTutorialPromptChainPosition(this, 1);
		else
			Player.SetTutorialPromptChainPosition(this, 0);
	}
};