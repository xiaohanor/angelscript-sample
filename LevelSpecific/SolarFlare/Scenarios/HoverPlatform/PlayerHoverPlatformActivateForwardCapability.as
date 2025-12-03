class UPlayerHoverPlatformActivateForwardCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"PlayerHoverPlatformActivateForwardCapability");
	
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	USolarFlareHoverPlatformComponent UserComp;
	ASolarFlareHoverPlatform Platform;

	float ForwardSpeed = 500.0;

	bool bPressedActivated;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USolarFlareHoverPlatformComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (UserComp.bActivated)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Platform = UserComp.Platform;

		FTutorialPrompt ActivatePrompt;
		ActivatePrompt.Action = ActionNames::MovementJump;
		ActivatePrompt.DisplayType = ETutorialPromptDisplay::Action;
		ActivatePrompt.Text = NSLOCTEXT("HoverPlatformTutorial", "ActivatePrompt", "Activate");

		Player.ShowTutorialPrompt(ActivatePrompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Platform.ReduceActivateCount(Player);
		bPressedActivated = false;
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!HasControl())
			return;
		
		if (WasActionStarted(ActionNames::MovementJump) && !bPressedActivated)
		{
			bPressedActivated = true;
			Platform.ActivatePlatform(Player);
			Player.RemoveTutorialPromptByInstigator(this);
		}
	}
}