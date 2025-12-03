class UPushShieldTutorialPromptsCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"PushShieldTutorialPromptsCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UPushableShieldUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UPushableShieldUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
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
		FTutorialPrompt ActivatePrompt;
		ActivatePrompt.Action = ActionNames::PrimaryLevelAbility;
		ActivatePrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
		ActivatePrompt.Text = NSLOCTEXT("ActivateShield", "ActivateShieldPrompt", "Activate Shield");

		FTutorialPrompt PushPrompt;
		PushPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_Up;
		PushPrompt.Text = NSLOCTEXT("PushShield", "PushShieldPrompt", "Push");

		Player.ShowTutorialPrompt(PushPrompt, FInstigator(UserComp.Shield, n"PushPrompt"));
		Player.ShowTutorialPrompt(ActivatePrompt, FInstigator(UserComp.Shield, n"ActivatePrompt"));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(FInstigator(UserComp.Shield, n"ActivatePrompt"));
		Player.RemoveTutorialPromptByInstigator(FInstigator(UserComp.Shield, n"PushPrompt"));
	}
}