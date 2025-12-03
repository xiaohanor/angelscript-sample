class USummitTeenDragonHomingAttackTutorialCapability : UTutorialCapability
{
	FTutorialPrompt JumpPrompt;
	default JumpPrompt.Action = ActionNames::MovementJump;
	default JumpPrompt.DisplayType = ETutorialPromptDisplay::Action;
	default JumpPrompt.Text = NSLOCTEXT("TeenDragonTutorial", "JumpText", "Jump");
	default JumpPrompt.Mode = ETutorialPromptMode::RemoveWhenPressed;

	FTutorialPrompt HomingAttackPrompt;
	default HomingAttackPrompt.Action = ActionNames::PrimaryLevelAbility;
	default HomingAttackPrompt.DisplayType = ETutorialPromptDisplay::Action;
	default HomingAttackPrompt.Text = FText::FromString("Crystal Homing Roll"); // NSLOCTEXT("TeenDragonTutorial", "HomingAttackText", "Crystal Homing Roll");
	default HomingAttackPrompt.Mode = ETutorialPromptMode::RemoveWhenPressed;

	FTutorialPromptChain TutorialPromptChain;
	default TutorialPromptChain.Type = ETutorialPromptChainType::Plus;
	default TutorialPromptChain.Prompts.Add(JumpPrompt);
	default TutorialPromptChain.Prompts.Add(HomingAttackPrompt);

	UTeenDragonRollComponent RollComp;
	UPlayerTeenDragonComponent DragonComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(DragonComp == nullptr)
			DragonComp = UPlayerTeenDragonComponent::Get(Player);
		if(RollComp == nullptr)
			RollComp = UTeenDragonRollComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ShowTutorialPromptChain(TutorialPromptChain, this, 0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(DragonComp.bIsInAirFromJumping)
			Player.SetTutorialPromptChainPosition(this, 1);
		else
			Player.SetTutorialPromptChainPosition(this, 0);

	}
}