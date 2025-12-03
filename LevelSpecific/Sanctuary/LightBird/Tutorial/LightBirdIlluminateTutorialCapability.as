class ULightBirdIlluminateTutorialCapability : UHazePlayerCapability
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
		if (!LightBirdTutorialComponent.bAimFireComplete)
			return false;

		if (PlayerAimingComponent.IsAiming(LightBirdUserComponent))
			return false;

		if (!HasResponseComponent())
			return false;

		if (LightBirdUserComponent.IsIlluminating())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!LightBirdTutorialComponent.bAimFireComplete)
			return true;

		if (PlayerAimingComponent.IsAiming(LightBirdUserComponent))
			return true;

		if (!HasResponseComponent())
			return true;

		if (LightBirdUserComponent.IsIlluminating())
			return true;

		if(LightBirdUserComponent.Companion.CompanionComp.State == ELightBirdCompanionState::Launched)
			return true;

		return false;
	}	

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TListedActors<ALightBirdTutorialSocket> SocketTutorials;
		Player.ShowTutorialPromptWorldSpace(LightBirdTutorialComponent.PromptIlluminate, this, SocketTutorials.Single.Root,  FVector(0.0, 0.0, 300.0), 0.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	bool HasResponseComponent() const
	{
		if (LightBirdUserComponent.AttachResponse != nullptr)
			return true;

		return false;
	}
}