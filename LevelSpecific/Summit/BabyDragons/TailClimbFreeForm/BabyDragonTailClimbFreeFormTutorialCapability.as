class UBabyDragonTailClimbFreeFormTutorialCapability : UTutorialCapability
{
	FTutorialPrompt AttachPrompt;
	default AttachPrompt.Action = ActionNames::PrimaryLevelAbility;
	default AttachPrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
	default AttachPrompt.Text = NSLOCTEXT("Baby Dragon Climb Tutorial", "Attach Prompt", "Attach Tail");
	default AttachPrompt.Mode = ETutorialPromptMode::Default;

	FTutorialPrompt LeapPrompt;
	default LeapPrompt.Action = ActionNames::PrimaryLevelAbility;
	default LeapPrompt.DisplayType = ETutorialPromptDisplay::ActionRelease;
	default LeapPrompt.Text = NSLOCTEXT("Baby Dragon Climb Tutorial", "Leap Prompt", "Leap");
	default LeapPrompt.Mode = ETutorialPromptMode::Default;

	UPlayerTailBabyDragonComponent DragonComp;

	bool bShowingAttachPrompt = false;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FTutorialPromptChain TutorialChain;
		TutorialChain.Prompts.Add(AttachPrompt);
		TutorialChain.Prompts.Add(LeapPrompt);
		Player.ShowTutorialPromptChain(TutorialChain, this, 0);

		bShowingAttachPrompt = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
		bShowingAttachPrompt = false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(DragonComp == nullptr)
			DragonComp = UPlayerTailBabyDragonComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(DragonComp.bClimbReachedPoint)
		{
			if(bShowingAttachPrompt)
			{
				// Player.RemoveTutorialPromptByInstigator(this);
				// Player.ShowTutorialPrompt(LeapPrompt, this);
				Player.SetTutorialPromptChainPosition(this, 1);
				bShowingAttachPrompt = false;
			}
		}
		else
		{
			if(!bShowingAttachPrompt)
			{
				// Player.RemoveTutorialPromptByInstigator(this);
				// Player.ShowTutorialPrompt(AttachPrompt, this);
				Player.SetTutorialPromptChainPosition(this, 0);
				bShowingAttachPrompt = true;
			}
		}
	}
}