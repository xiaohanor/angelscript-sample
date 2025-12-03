class USanctuaryGhostLightBirdIlluminateTutorialCapability : UHazePlayerCapability
{
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

		if (GetTutorialGhost() == nullptr)
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

		return false;
	}

	ASanctuaryGhost GetTutorialGhost() const
	{
		TListedActors<ASanctuaryGhostTutorial> GhostTutorials;
		if (GhostTutorials.GetArray().Num() == 0)
			return nullptr;
		return GhostTutorials.Single.TutorialGhost;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ShowTutorialPromptWorldSpace(LightBirdTutorialComponent.PromptIlluminate, this, GetTutorialGhost().Root);
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