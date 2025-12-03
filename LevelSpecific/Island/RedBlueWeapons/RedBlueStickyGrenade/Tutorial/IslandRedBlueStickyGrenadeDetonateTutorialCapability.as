class UIslandRedBlueStickyGrenadeDetonateTutorialCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(IslandRedBlueStickyGrenade::IslandRedBlueStickyGrenade);
	default CapabilityTags.Add(n"IslandRedBlueStickyGrenadeTutorial");
	default CapabilityTags.Add(n"Tutorial");

	UIslandRedBlueStickyGrenadeUserComponent IslandRedBlueStickyGrenadeUserComponent;
	UIslandRedBlueStickyGrenadeTutorialComponent IslandRedBlueStickyGrenadeTutorialComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		IslandRedBlueStickyGrenadeUserComponent = UIslandRedBlueStickyGrenadeUserComponent::Get(Player);
		IslandRedBlueStickyGrenadeTutorialComponent = UIslandRedBlueStickyGrenadeTutorialComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(IslandRedBlueStickyGrenadeUserComponent.Grenade.IsGrenadeAttached() && !IslandRedBlueStickyGrenadeUserComponent.Grenade.IsActorDisabled())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(IslandRedBlueStickyGrenadeUserComponent.Grenade.IsActorDisabled())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ShowTutorialPrompt(IslandRedBlueStickyGrenadeTutorialComponent.PromptDetonate, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
		IslandRedBlueStickyGrenadeTutorialComponent.LastTimeDetonatePromptShown = Time::GetGameTimeSeconds();
	}
};