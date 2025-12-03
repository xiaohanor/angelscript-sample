class UPlayerAirJumpTutorialCapability : UTutorialCapability
{
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
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

		FTutorialPrompt JumpPrompt;
		JumpPrompt.Action = ActionNames::MovementJump;
		JumpPrompt.Text = NSLOCTEXT("MovementTutorial", "JumpPrompt", "Jump");
		TutorialChain.Prompts.Add(JumpPrompt);

		FTutorialPrompt AirJumpPrompt;
		AirJumpPrompt.Action = ActionNames::MovementJump;
		AirJumpPrompt.Text = NSLOCTEXT("MovementTutorial", "AirJumpPrompt", "Double Jump");
		TutorialChain.Prompts.Add(AirJumpPrompt);

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
		if (MoveComp.IsOnAnyGround())
			Player.SetTutorialPromptChainPosition(this, 0);
		else
			Player.SetTutorialPromptChainPosition(this, 1);
	}
};