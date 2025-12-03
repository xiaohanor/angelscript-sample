class UPlayerPoleDashTutorialCapability : UTutorialCapability
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Player.IsAnyCapabilityActive(PlayerMovementTags::PoleClimb))
			return false;

		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FTutorialPrompt DashPrompt;
		DashPrompt.Action = ActionNames::MovementDash;
		DashPrompt.Text = NSLOCTEXT("MovementTutorial", "PoleDashPrompt", "Dash");

		Player.ShowTutorialPrompt(DashPrompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}
}