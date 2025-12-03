class UGravityWhipContainerGrabTutorialCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(GravityWhipTags::GravityWhip);
	default CapabilityTags.Add(n"GravityWhipTutorial");
	default CapabilityTags.Add(n"Tutorial");

	UGravityWhipUserComponent GravityWhipUserComponent;
	UGravityWhipTutorialComponent GravityWhipTutorialComponent;
	UPlayerAimingComponent PlayerAimingComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityWhipUserComponent = UGravityWhipUserComponent::Get(Player);
		GravityWhipTutorialComponent = UGravityWhipTutorialComponent::Get(Player);
		PlayerAimingComponent = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!GravityWhipUserComponent.IsTargetingAny())
			return false;

		if (GravityWhipUserComponent.IsGrabbingAny())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!GravityWhipUserComponent.IsTargetingAny())
			return true;

		if (GravityWhipUserComponent.IsGrabbingAny())
			return true;

		return false;
	}	

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
//		TListedActors<AGravityWhipContainerTutorialActor> GrabTutorials;
//		Player.ShowTutorialPromptWorldSpace(GravityWhipTutorialComponent.PromptGrab, this, GrabTutorials.Single.GrabLocation,  FVector(0.0, 0.0, 100.0), 0.0);

		auto GrabLocation = GravityWhipUserComponent.TargetData.TargetComponents[0];
		Player.ShowTutorialPromptWorldSpace(GravityWhipTutorialComponent.PromptGrab, this, GrabLocation, GravityWhipTutorialComponent.AttachOffset, GravityWhipTutorialComponent.ScreenSpaceOffset);

		//Player.ShowTutorialPrompt(GravityWhipTutorialComponent.PromptGrab, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}
}