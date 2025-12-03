class UIslandRedBlueSidescrollerAimingTutorialCapability : UTutorialCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	bool bHasAimed = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(bHasAimed)
			return false;

		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bHasAimed)
			return true;

		return Super::ShouldDeactivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FTutorialPrompt AimTutorialPrompt;
		AimTutorialPrompt.DisplayType = ETutorialPromptDisplay::RightStick_Rotate_CW;
		AimTutorialPrompt.Action = ActionNames::WeaponAim;
		AimTutorialPrompt.Text = NSLOCTEXT("IslandSidescrollerTutorial", "AimWithRightStick", "Aim");
		if(Player.IsMio())
			AimTutorialPrompt.OverrideControlsPlayer = EHazeSelectPlayer::Mio;
		else
			AimTutorialPrompt.OverrideControlsPlayer = EHazeSelectPlayer::Zoe;

		Game::Mio.ShowTutorialPrompt(AimTutorialPrompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Game::Mio.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!GetAttributeVector2D(AttributeVectorNames::RightStickRaw).IsNearlyZero())
			bHasAimed = true;
	}
};