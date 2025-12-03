class UDarkPortalGrabTutorialCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortal);
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
		if (PlayerAimingComponent.IsAiming(DarkPortalUserComponent))
			return false;

		if (!DarkPortalUserComponent.Portal.IsSettled())
			return false;

		if (DarkPortalUserComponent.Portal.IsGrabbingAny())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PlayerAimingComponent.IsAiming(DarkPortalUserComponent))
			return true;

		if (!DarkPortalUserComponent.Portal.IsSettled())
			return true;

		if (DarkPortalUserComponent.Portal.IsGrabbingAny())
			return true;

		return false;
	}	

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TListedActors<ASanctuaryTiltablePillar> PillarTutorials;
		Player.ShowTutorialPromptWorldSpace(DarkPortalTutorialComponent.PromptGrab, this, PillarTutorials.Single.AimLocation,  FVector(0.0, 0.0, 100.0), 0.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}
}