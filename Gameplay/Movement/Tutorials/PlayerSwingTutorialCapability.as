class UPlayerSwingTutorialCapability : UTutorialCapability
{
	UPlayerMovementComponent MoveComp;

	float Delay = 3.0;
	bool bTutorialActive = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Player.IsAnyCapabilityActive(PlayerSwingTags::SwingMovement))
			return false;

		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Player.IsAnyCapabilityActive(PlayerSwingTags::SwingMovement))
			return true;

		return Super::ShouldDeactivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bTutorialActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bTutorialActive && ActiveDuration >= Delay)
		{
			bTutorialActive = true;

			FTutorialPrompt TutorialPrompt;
			TutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_UpDown;
			TutorialPrompt.Text = NSLOCTEXT("MovementTutorial", "SwingPrompt", "Swing");
			Player.ShowTutorialPrompt(TutorialPrompt, this);
		}
	}
}