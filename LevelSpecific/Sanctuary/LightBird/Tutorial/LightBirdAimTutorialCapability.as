class ULightBirdAimTutorialCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(LightBird::Tags::LightBird);
	default CapabilityTags.Add(LightBird::Tags::LightBirdAim);
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

		if (PlayerAimingComponent.IsAiming(LightBirdUserComponent))
			return false;

//		if (LightBirdUserComponent.Bird.TargetData.IsValid())
//			return false;

		if (LightBirdUserComponent.State == ELightBirdState::Attached)
			return false;

		if (HasResponseComponent())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
//		if (LightBirdTutorialComponent.bAimFireComplete)
//			return true;

		if (PlayerAimingComponent.IsAiming(LightBirdUserComponent))
			return true;

//		if (LightBirdUserComponent.Bird.TargetData.IsValid())
//			return true;

		if (LightBirdUserComponent.State == ELightBirdState::Attached)
			return true;

		if (HasResponseComponent())
			return true;

		return false;
	}	

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ShowTutorialPrompt(LightBirdTutorialComponent.PromptAim, this);
//		Player.ShowTutorialPromptChain(LightBirdTutorialComponent.PromptAimFireChain, this, 0);
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