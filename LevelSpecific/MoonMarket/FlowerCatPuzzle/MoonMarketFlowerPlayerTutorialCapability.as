class UMoonMarketFlowerPlayerTutorialCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	UMoonMarketPlayerFlowerSpawningComponent FlowerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FlowerComp = UMoonMarketPlayerFlowerSpawningComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(FlowerComp.Hat == nullptr)
			return false;

		if(!FlowerComp.bShowPaintingTutorial)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(FlowerComp.Hat == nullptr)
			return true;

		if(!FlowerComp.bShowPaintingTutorial)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(FlowerComp.bShowEraseTutorial)
			ShowEraseTutorial();

		ShowDrawingTutorial();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}
	
	void ShowEraseTutorial()
	{
		FTutorialPrompt Prompt;
		Prompt.Mode = ETutorialPromptMode::Default;
		Prompt.DisplayType = ETutorialPromptDisplay::ActionHold;
		Prompt.Action = ActionNames::SecondaryLevelAbility;
		Prompt.Text = NSLOCTEXT("FlowerPuzzle", "EraseFlower", "Erase Flowers");
		Player.ShowTutorialPrompt(Prompt, this);
	}

	void ShowDrawingTutorial()
	{
		FTutorialPrompt Prompt;
		Prompt.Mode = ETutorialPromptMode::Default;
		Prompt.DisplayType = ETutorialPromptDisplay::ActionHold;
		Prompt.Action = ActionNames::PrimaryLevelAbility;
		Prompt.Text = NSLOCTEXT("FlowerPuzzle", "GrowFlower", "Grow Flowers");
		Player.ShowTutorialPrompt(Prompt, this);
	}
};