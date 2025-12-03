class UGravityWhipSlingTutorialCapability : UHazePlayerCapability
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
		if (!GravityWhipUserComponent.IsGrabbingAny())
			return false;

		if (GravityWhipUserComponent.GetPrimaryGrabMode() != EGravityWhipGrabMode::Sling)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!GravityWhipUserComponent.IsGrabbingAny())
			return true;

		if (GravityWhipUserComponent.GetPrimaryGrabMode() != EGravityWhipGrabMode::Sling)
			return true;

		return false;
	}	

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ShowTutorialPrompt(GravityWhipTutorialComponent.PromptSling, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}
}