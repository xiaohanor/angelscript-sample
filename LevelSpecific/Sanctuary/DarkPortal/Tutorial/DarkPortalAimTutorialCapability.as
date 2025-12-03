class UDarkPortalAimTutorialCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortal);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortalAim);
	default CapabilityTags.Add(n"DarkPortalTutorial");
	default CapabilityTags.Add(n"Tutorial");

	UDarkPortalUserComponent DarkPortalUserComponent;
	UDarkPortalTutorialComponent DarkPortalTutorialComponent;
	UPlayerAimingComponent PlayerAimingComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DarkPortalUserComponent = UDarkPortalUserComponent::Get(Player);
		DarkPortalTutorialComponent = UDarkPortalTutorialComponent::Get(Player);
		PlayerAimingComponent = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
//		if (DarkPortalTutorialComponent.bAimFireComplete)
//			return false;

		if (PlayerAimingComponent.IsAiming(DarkPortalUserComponent))
			return false;

		if (DarkPortalUserComponent.Portal.TargetData.IsValid())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
//		if (DarkPortalTutorialComponent.bAimFireComplete)
//			return true;

		if (PlayerAimingComponent.IsAiming(DarkPortalUserComponent))
			return true;

		if (DarkPortalUserComponent.Portal.TargetData.IsValid())
			return true;

		return false;
	}	

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		
		//Player.ShowTutorialPromptWorldSpace(DarkPortalTutorialComponent.PromptAim, this, Player.GetMeshOffsetComponent());
		Player.ShowTutorialPrompt(DarkPortalTutorialComponent.PromptAim, this);
//		Player.ShowTutorialPromptChain(DarkPortalTutorialComponent.PromptAimFireChain, this, 0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}
}