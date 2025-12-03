class UIslandJetpackSidescrollerActivateTutorialCapability : UTutorialCapability
{
	UPlayerMovementComponent MoveComp;
	UIslandJetpackComponent JetpackComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JetpackComp = UIslandJetpackComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(JetpackComp == nullptr)
			return false;

		if(JetpackComp.bThrusterIsOn)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(JetpackComp.bThrusterIsOn)
			return true;

		return false;
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
		AirJumpPrompt.Text = NSLOCTEXT("MovementTutorial", "ActivateJetpack", "Activate Jetpack");
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