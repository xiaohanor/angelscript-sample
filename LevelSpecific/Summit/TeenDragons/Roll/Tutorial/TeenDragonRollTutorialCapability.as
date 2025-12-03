struct FTeenDragonRollTutorialData
{
	ATeenDragonRollTutorialVolume TutorialVolume;
}

class UTeenDragonRollTutorialCapability : UTutorialCapability
{
	ATeenDragonRollTutorialVolume TutorialVolume;
	ASummitNightQueenGem CurrentGem;
	UCameraUserComponent CamComp;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTeenDragonRollTutorialData& Data) const
	{
		if (Super::ShouldActivate())
		{
			TArray<AActor> Overlaps;
			Player.GetOverlappingActors(Overlaps, ATutorialVolume);
			ATeenDragonRollTutorialVolume RollTutorialVolume;

			for (auto Volume : Overlaps)
			{
				auto CurrentTutorialVolume = Cast<ATeenDragonRollTutorialVolume>(Volume);
				RollTutorialVolume = CurrentTutorialVolume;
			}

			if (RollTutorialVolume == nullptr)
				return false;

			if (!RollTutorialVolume.ShouldUsePrompt())
				return false;

			Data.TutorialVolume = RollTutorialVolume;
			return true; 
		}
		
		return false; 
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!TutorialVolume.ShouldUsePrompt())
			return true;
		
		return Super::ShouldDeactivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTeenDragonRollTutorialData Data)
	{
		TutorialVolume = Data.TutorialVolume;
		FTutorialPrompt TailSmashPrompt;
		TailSmashPrompt.Action = ActionNames::PrimaryLevelAbility;
		TailSmashPrompt.Text = NSLOCTEXT("TailSmashTutorial", "TailSmashPrompt", "Smash");

		Player.ShowTutorialPrompt(TailSmashPrompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}
};