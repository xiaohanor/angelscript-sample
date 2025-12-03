class ULightBirdFireTutorialCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(LightBird::Tags::LightBird);
	default CapabilityTags.Add(n"LightBirdTutorial");
	default CapabilityTags.Add(n"Tutorial");

	ULightBirdUserComponent LightBirdUserComponent;
	ULightBirdTutorialComponent LightBirdTutorialComponent;
	UPlayerAimingComponent PlayerAimingComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LightBirdUserComponent = ULightBirdUserComponent::Get(Player);
		LightBirdTutorialComponent = ULightBirdTutorialComponent::Get(Player);
		PlayerAimingComponent = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
//		if (LightBirdTutorialComponent.bAimFireComplete)
//			return false;

		if (!PlayerAimingComponent.IsAiming(LightBirdUserComponent))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
//		if (LightBirdTutorialComponent.bAimFireComplete)
//			return true;

		if (!PlayerAimingComponent.IsAiming(LightBirdUserComponent))
			return true;

		return false;
	}	

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		//Player.ShowTutorialPrompt(LightBirdTutorialComponent.PromptFire, this);

		TListedActors<ALightBirdTutorialSocket> SocketTutorials;
		Player.ShowTutorialPromptWorldSpace(LightBirdTutorialComponent.PromptFire, this, SocketTutorials.Single.Root,  FVector(0.0, 0.0, 300.0), 0.0);
//		Player.ShowTutorialPromptChain(LightBirdTutorialComponent.PromptAimFireChain, this, 1);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);

		if (WasActionStopped(ActionNames::PrimaryLevelAbility))
			LightBirdTutorialComponent.bAimFireComplete = true;
	}

/*
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (WasActionStopped(ActionNames::PrimaryLevelAbility))
			LightBirdTutorialComponent.bAimFireComplete = true;
	}
*/
}