class UTeenDragonRollJumpTutorialCapability : UTutorialCapability
{
	FTutorialPromptChain TutorialChain;

	bool bReadRollJump;

	float SwitchBackTime;
	float SwitchBackDuration = 2.0;

	bool bIsJumping;
	bool bIsRolling;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FTutorialPrompt Roll;
		Roll.Action = ActionNames::PrimaryLevelAbility;
		Roll.Text = NSLOCTEXT("RollMovementTutorial", "RollPrompt", "Roll");
		TutorialChain.Prompts.Add(Roll);

		FTutorialPrompt JumpPrompt;
		JumpPrompt.Action = ActionNames::MovementJump;
		JumpPrompt.Text = NSLOCTEXT("RollMovementTutorial", "JumpPrompt", "Jump");
		TutorialChain.Prompts.Add(JumpPrompt);		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return Super::ShouldDeactivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ShowTutorialPromptChain(TutorialChain, this, 0);
		if (Player.IsAnyCapabilityActive(TeenDragonCapabilityTags::TeenDragonRoll))
			Player.SetTutorialPromptChainPosition(this, 1);

		bReadRollJump = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.IsAnyCapabilityActive(TeenDragonCapabilityTags::TeenDragonRoll) && !bIsRolling)
		{
			Player.SetTutorialPromptChainPosition(this, 1);
			bIsRolling = true;
			bIsJumping = false;
		}
		else if (!Player.IsAnyCapabilityActive(TeenDragonCapabilityTags::TeenDragonRoll) && bIsRolling && !bIsJumping)
		{
			Player.SetTutorialPromptChainPosition(this, 0);
			bIsRolling = false;
		}

		if (Player.IsAnyCapabilityActive(TeenDragonCapabilityTags::TeenDragonJump) && !bIsJumping)
		{
			Player.SetTutorialPromptChainPosition(this, 2);
			bIsRolling = false;
			bIsJumping = true;
		}

	}
};