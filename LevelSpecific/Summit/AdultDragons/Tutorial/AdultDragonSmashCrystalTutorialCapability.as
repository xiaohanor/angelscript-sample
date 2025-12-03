class UAdultDragonSmashCrystalTutorialCapability : UTutorialCapability
{
	bool bDeactivate = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TListedActors<AAdultDragonSmashTutorialVolume> TutorialVolumes;
		TutorialVolumes[0].Gem.OnBreakVineGemSpike.AddUFunction(this, n"OnBreakVineGemSpike");
	}

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
		DriftPrompt.DisplayType = ETutorialPromptDisplay::Action;
		DriftPrompt.Action = ActionNames::PrimaryLevelAbility;
		DriftPrompt.Text = NSLOCTEXT("AdultDragonTutorial", "Smash", "Smash");

		Player.ShowTutorialPrompt(DriftPrompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//TODO Grey out prompt until player is within locked range
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION()
	private void OnBreakVineGemSpike()
	{
		bDeactivate = true;
	}

	// UFUNCTION()
	// private void OnSummitGemDestroyed(ASummitSiegeGem CrystalDestroyed)
	// {
	// 	bDeactivate = true;
	// }
}