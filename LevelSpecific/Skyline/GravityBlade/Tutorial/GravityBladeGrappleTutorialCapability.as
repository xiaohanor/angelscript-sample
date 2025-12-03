class UGravityBladeGrappleTutorialCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"GravityBladeTutorial");
	default CapabilityTags.Add(n"Tutorial");

	UGravityBladeCombatUserComponent GravityBladeCombatUserComponent;
	UGravityBladeGrappleUserComponent GravityBladeGrappleUserComponent;
	UGravityBladeTutorialComponent GravityBladeTutorialComponent;
	UPlayerAimingComponent PlayerAimingComponent;
	UGravityBladeGrappleComponent TargetComp;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBladeCombatUserComponent = UGravityBladeCombatUserComponent::Get(Player);
		GravityBladeGrappleUserComponent = UGravityBladeGrappleUserComponent::Get(Player);
		GravityBladeTutorialComponent = UGravityBladeTutorialComponent::Get(Player);
		PlayerAimingComponent = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (GravityBladeTutorialComponent.bGrappleTutorialComplete)
			return false;

		if (!GravityBladeGrappleUserComponent.AimGrappleData.IsValid())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (GravityBladeTutorialComponent.bGrappleTutorialComplete)
			return true;

		if (!GravityBladeGrappleUserComponent.AimGrappleData.IsValid())
			return true;

		if (TargetComp != GravityBladeGrappleUserComponent.AimGrappleData.GrappleComponent)
			return true;

		return false;
	}	

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetComp = GravityBladeGrappleUserComponent.AimGrappleData.GrappleComponent;
		//Player.ShowTutorialPrompt(GravityBladeTutorialComponent.PromptGrapple, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (GravityBladeGrappleUserComponent.ActiveGrappleData.IsValid())
			GravityBladeTutorialComponent.bGrappleTutorialComplete = true;

		Player.ShowTutorialPromptWorldSpace(GravityBladeTutorialComponent.PromptGrapple, this, TargetComp, FVector(0, 0, 0), 70.0);
	}
}