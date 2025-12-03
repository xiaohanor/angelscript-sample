class UDarkPortalPushTutorialCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortal);
	default CapabilityTags.Add(n"DarkPortalTutorial");
	default CapabilityTags.Add(n"Tutorial");

	UDarkPortalUserComponent DarkPortalUserComponent;
	UDarkPortalTutorialComponent DarkPortalTutorialComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DarkPortalUserComponent = UDarkPortalUserComponent::Get(Player);
		DarkPortalTutorialComponent = UDarkPortalTutorialComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!DarkPortalUserComponent.Portal.HasActiveGrab())
			return false;

		if (!HasResponseComponent())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!DarkPortalUserComponent.Portal.HasActiveGrab())
			return true;

		if (!HasResponseComponent())
			return true;

		return false;
	}	

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ShowTutorialPrompt(DarkPortalTutorialComponent.PromptPush, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	bool HasResponseComponent() const
	{
		if (DarkPortalUserComponent.Portal.AttachResponse != nullptr)
			return true;

		for (auto Grab : DarkPortalUserComponent.Portal.Grabs)
		{
			if (Grab.ResponseComponent != nullptr)
				return true;
		}

		return false;
	}
}