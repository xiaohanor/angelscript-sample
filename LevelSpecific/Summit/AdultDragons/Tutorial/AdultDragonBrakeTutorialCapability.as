class UAdultDragonBrakeTutorialCapability : UTutorialCapability
{
	bool bDeactivate;

	float BreakTime = 1.5;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (bDeactivate)
			return false;

		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bDeactivate)
			return true;

		return Super::ShouldDeactivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FTutorialPrompt DriftPrompt;
		DriftPrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
		DriftPrompt.Action = ActionNames::SecondaryLevelAbility;
		DriftPrompt.Text = NSLOCTEXT("AdultDragonTutorial", "DragonBreak", "Hover");

		Player.ShowTutorialPrompt(DriftPrompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (IsActioning(ActionNames::Cancel))
		{
			BreakTime -= DeltaTime;

			if (BreakTime <= 0.0)
			{
				bDeactivate = true;
			}
		}
	}
}