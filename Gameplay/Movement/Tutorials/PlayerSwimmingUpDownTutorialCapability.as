class UPlayerSwimmingUpDownTutorialCapability : UTutorialCapability
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Player.IsAnyCapabilityActive(PlayerMovementTags::Swimming))
			return false;

		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FTutorialPrompt UpPrompt;
		UpPrompt.Action = ActionNames::MovementVerticalUp;
		UpPrompt.Text = NSLOCTEXT("MovementTutorial", "SwimUpPrompt", "Up");
		Player.ShowTutorialPrompt(UpPrompt, this);

		FTutorialPrompt DownPrompt;
		DownPrompt.Action = ActionNames::MovementVerticalDown;
		DownPrompt.Text = NSLOCTEXT("MovementTutorial", "SwimDownPrompt", "Down");
		Player.ShowTutorialPrompt(DownPrompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}
}