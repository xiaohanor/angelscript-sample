class UPlayerDragonFinaleFireCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ADragonFinaleController Dragon;

	bool bFired;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{

	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (bFired)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TArray<ADragonFinaleController> DragonsArray = TListedActors<ADragonFinaleController>().GetArray();

		for (ADragonFinaleController CurrentDragon : DragonsArray)
		{
			if (Player == Game::Mio && CurrentDragon.PlayerTarget == EHazeSelectPlayer::Mio)
				Dragon = CurrentDragon;
			else if (Player == Game::Zoe && CurrentDragon.PlayerTarget == EHazeSelectPlayer::Zoe)
				Dragon = CurrentDragon;
		}

		if (Dragon == nullptr)
		{
			Print("WHY!");
		}

		if (Player == Game::Zoe)
		{
			UCameraSettings::GetSettings(Player).FOV.Apply(45.0, this, 1);
			FTutorialPrompt TutorialPromptTail;
			TutorialPromptTail.Action = ActionNames::PrimaryLevelAbility;
			TutorialPromptTail.Text = NSLOCTEXT("SummitFinale", "FinaleFinishingBlowSpike", "Fire Spike");
			Game::Zoe.ShowTutorialPrompt(TutorialPromptTail, this);
		}
		else
		{
			UCameraSettings::GetSettings(Player).FOV.Apply(45.0, this, 1);
			FTutorialPrompt TutorialPromptAcid;
			TutorialPromptAcid.Action = ActionNames::PrimaryLevelAbility;
			TutorialPromptAcid.Text = NSLOCTEXT("SummitFinale", "FinaleFinishingBlowAcid", "Fire Acid");
			Game::Zoe.ShowTutorialPrompt(TutorialPromptAcid, this);
		}

		Player.BlockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Game::Zoe.RemoveTutorialPromptByInstigator(this);
		Dragon.FireProjectile();
		bFired = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};