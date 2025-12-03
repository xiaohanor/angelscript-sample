/**
 * 
 */
class UIceBowTutorialCapability : UHazePlayerCapability
{
    default DebugCategory = IceBow::DebugCategory;
    
    default CapabilityTags.Add(CapabilityTags::GameplayAction);

	UIceBowPlayerComponent IceBowPlayerComp;
	UIceArrowPlayerComponent IceArrowPlayerComp;

	default TickGroupOrder = 100;

	default TickGroup = EHazeTickGroup::Movement;

	bool bAiming = false;
	bool bCharging = false;

	FTutorialPromptChain AimPromptChain;
	FTutorialPromptChain ShootPromptChain;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        IceBowPlayerComp = UIceBowPlayerComponent::Get(Player);
		IceArrowPlayerComp = UIceArrowPlayerComponent::Get(Player);

		FTutorialPrompt AimPrompt;
		AimPrompt.Action = IceBow::AimAction;
		AimPrompt.Text = IceBowPlayerComp.BowSettings.AimTutorialText;
		AimPrompt.DisplayType = ETutorialPromptDisplay::ActionHold;

		FTutorialPrompt ChargePrompt;
		ChargePrompt.Action = IceBow::ShotAction;
		ChargePrompt.Text = IceBowPlayerComp.BowSettings.ShootTutorialText;
		// ChargePrompt.DisplayType = ETutorialPromptDisplay::ActionHold;

		AimPromptChain.Prompts.Add(AimPrompt);
		AimPromptChain.Prompts.Add(ChargePrompt);

		FTutorialPrompt ShootPrompt;
		ShootPrompt.Action = IceBow::ShotAction;
		ShootPrompt.Text = IceBowPlayerComp.BowSettings.ShootTutorialText;

		ShootPromptChain.Prompts.Add(AimPrompt);
		ShootPromptChain.Prompts.Add(ShootPrompt);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
		if(IceArrowPlayerComp == nullptr)
			return false;

		if (!IceArrowPlayerComp.bShowTutorial)
			return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
		if(IceArrowPlayerComp == nullptr)
			return true;

		if (!IceArrowPlayerComp.bShowTutorial)
			return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
		Player.ShowTutorialPromptChain(AimPromptChain, this, 0);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    { 
        Player.RemoveTutorialPromptByInstigator(this);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if (IceBowPlayerComp.bIsAimingIceBow)
		{
			/*if (PlayerComp.bIsChargingIceBow)
				ShowShootTutorial();
			else
				ShowChargeTutorial();*/
			ShowShootTutorial();
		}
		else
		{
			ShowAimTutorial();
		}
    }

	/*void ShowAimTutorial()
	{
		if (!bAiming)
			return;

		bAiming = false;
		Player.RemoveTutorialPromptByInstigator(this);
		Player.ShowTutorialPromptChain(AimPromptChain, this, 0);
	}

	void ShowChargeTutorial()
	{
		if (!bCharging)
		{
			if (bAiming)
				return;
		}

		bCharging = false;
		bAiming = true;
		Player.RemoveTutorialPromptByInstigator(this);
		Player.ShowTutorialPromptChain(AimPromptChain, this, 1);
	}

	void ShowShootTutorial()
	{
		if (bCharging)
			return;

		bCharging = true;
		Player.RemoveTutorialPromptByInstigator(this);
		Player.ShowTutorialPromptChain(ShootPromptChain, this, 1);
	}*/

	void ShowAimTutorial()
	{
		Player.SetTutorialPromptChainPosition(this, 0);
	}

	void ShowShootTutorial()
	{
		Player.SetTutorialPromptChainPosition(this, 1);
	}
}