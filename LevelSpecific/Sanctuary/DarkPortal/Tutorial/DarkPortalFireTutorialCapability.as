class UDarkPortalFireTutorialCapability : UHazePlayerCapability
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
//		if (DarkPortalTutorialComponent.bAimFireComplete)
//			return false;

		if (!PlayerAimingComponent.IsAiming(DarkPortalUserComponent))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
//		if (DarkPortalTutorialComponent.bAimFireComplete)
//			return true;

		if (!PlayerAimingComponent.IsAiming(DarkPortalUserComponent))
			return true;

		return false;
	}	

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TListedActors<ASanctuaryTiltablePillar> PillarTutorials;
		Player.ShowTutorialPromptWorldSpace(DarkPortalTutorialComponent.PromptFire, this, PillarTutorials.Single.AimLocation,  FVector(0.0, 0.0, 100.0), 0.0);
//		Player.ShowTutorialPromptChain(DarkPortalTutorialComponent.PromptAimFireChain, this, 1);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);

	//	if (WasActionStopped(ActionNames::PrimaryLevelAbility))
	//		DarkPortalTutorialComponent.bAimFireComplete = true;
	}

/*
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (WasActionStarted(ActionNames::PrimaryLevelAbility))
			DarkPortalTutorialComponent.bAimFireComplete = true;
	}
*/
}