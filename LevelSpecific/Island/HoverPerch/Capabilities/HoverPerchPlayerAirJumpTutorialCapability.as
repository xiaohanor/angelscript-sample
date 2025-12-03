class UHoverPerchPlayerAirJumpTutorialCapability : UTutorialCapability
{
	UPlayerMovementComponent MoveComp;
	UPlayerPerchComponent PerchComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		PerchComp = UPlayerPerchComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!PerchComp.IsCurrentlyPerching())
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
		if (PerchComp.IsCurrentlyPerching())
			Player.SetTutorialPromptChainPosition(this, 0);
		else
			Player.SetTutorialPromptChainPosition(this, 1);
	}
};