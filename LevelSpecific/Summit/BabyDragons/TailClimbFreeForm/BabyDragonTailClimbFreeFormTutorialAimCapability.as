class UBabyDragonTailClimbFreeFormTutorialAimCapability : UTutorialCapability
{
	FTutorialPrompt AimPrompt;
	default AimPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRight;
	default AimPrompt.Text = NSLOCTEXT("Baby Dragon Climb Tutorial", "Aim Prompt", "Leap Direction");
	default AimPrompt.Mode = ETutorialPromptMode::Default;

	FTutorialPrompt LeapPrompt;
	default LeapPrompt.Action = ActionNames::PrimaryLevelAbility;
	default LeapPrompt.DisplayType = ETutorialPromptDisplay::ActionRelease;
	default LeapPrompt.Text = NSLOCTEXT("Baby Dragon Climb Tutorial", "Leap Prompt", "Leap");
	default LeapPrompt.Mode = ETutorialPromptMode::Default;

	UPlayerTailBabyDragonComponent DragonComp;

	bool bShowingLeapPrompt = false;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FTutorialPromptChain TutorialChain;
		TutorialChain.Prompts.Add(AimPrompt);
		TutorialChain.Prompts.Add(LeapPrompt);
		Player.ShowTutorialPromptChain(TutorialChain, this, 0);

		bShowingLeapPrompt = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
		bShowingLeapPrompt = false;
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
		FVector2D CameraStick = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);

		if(!CameraStick.IsNearlyZero())
		{
			if(bShowingLeapPrompt)
			{
				Player.SetTutorialPromptChainPosition(this, 1);
				bShowingLeapPrompt = false;
			}
		}
		else
		{
			if(!bShowingLeapPrompt)
			{
				// Player.RemoveTutorialPromptByInstigator(this);
				// Player.ShowTutorialPrompt(AttachPrompt, this);
				Player.SetTutorialPromptChainPosition(this, 0);
				bShowingLeapPrompt = true;
			}
		}
	}
}