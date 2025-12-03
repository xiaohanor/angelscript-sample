class UGravityBladeAttackTutorialCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"GravityBladeTutorial");
	default CapabilityTags.Add(n"Tutorial");

	UGravityBladeCombatUserComponent GravityBladeCombatUserComponent;
	UGravityBladeGrappleUserComponent GravityBladeGrappleUserComponent;
	UGravityBladeTutorialComponent GravityBladeTutorialComponent;
	UPlayerAimingComponent PlayerAimingComponent;

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
		if (GravityBladeTutorialComponent.bAttackTutorialComplete)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
//		if (GravityBladeCombatUserComponent.HasActiveAttack())
//			return true;

		if (GravityBladeTutorialComponent.bAttackTutorialComplete)
			return true;

		return false;
	}	

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ShowTutorialPrompt(GravityBladeTutorialComponent.PromptAttack, this);

		//TListedActors<AGravityBladeTutorialActor> GravityBladeTutorials;
		//Player.ShowTutorialPromptWorldSpace(GravityBladeTutorialComponent.PromptAttack, this, GravityBladeTutorials.Single.AttackLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);

		GravityBladeTutorialComponent.bAttackTutorialComplete = true;
	}
}