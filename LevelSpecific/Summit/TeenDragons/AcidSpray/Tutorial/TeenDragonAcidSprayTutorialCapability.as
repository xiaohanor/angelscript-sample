class UTeenDragonAcidSprayTutorialCapability : UTutorialCapability
{
	ATeenDragonAcidSprayTutorialVolume TutorialVolume;

	bool bTutorialComplete;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		// TutorialVolume = Cast<ATeenDragonAcidSprayTutorialVolume>(TutorialVolume);
		// TutorialVolume.NightQueenMetal.OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
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
		if (bTutorialComplete)
			return;

		TArray<AActor> Overlaps;
		Player.GetOverlappingActors(Overlaps, ATutorialVolume);

		TutorialVolume = nullptr;
		for (auto Volume : Overlaps)
		{
			auto CurrentTutorialVolume = Cast<ATeenDragonAcidSprayTutorialVolume>(Volume);
			if (!IsValid(CurrentTutorialVolume.NightQueenMetal))
				continue;
			if (CurrentTutorialVolume.NightQueenMetal.MeltedAlpha >= 1.0)
				continue;

			TutorialVolume = CurrentTutorialVolume;
			TutorialVolume.NightQueenMetal.OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
		}

		if (TutorialVolume == nullptr)
			return;

		FTutorialPrompt AcidSprayPrompt;
		AcidSprayPrompt.Action = ActionNames::PrimaryLevelAbility;
		AcidSprayPrompt.Text = NSLOCTEXT("AcidSprayTutorial", "AcidSprayPrompt", "Melt");
		AcidSprayPrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
		
		Player.ShowTutorialPrompt(AcidSprayPrompt, this);
		// Player.ShowTutorialPromptWorldSpace(AcidSprayPrompt, this, TutorialVolume.NightQueenMetal.Root, FVector(0,0,0), 0.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}
};