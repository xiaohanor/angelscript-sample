class UIslandRedBlueStickyGrenadeFireTutorialCapability : UHazePlayerCapability
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
		if(!IslandRedBlueStickyGrenadeUserComponent.Grenade.IsGrenadeThrown() && Time::GetGameTimeSince(IslandRedBlueStickyGrenadeTutorialComponent.LastTimeDetonatePromptShown) > 1)
			return true;

		if(!IslandRedBlueStickyGrenadeTutorialComponent.bFirstPromptShown)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(IslandRedBlueStickyGrenadeUserComponent.Grenade.IsGrenadeThrown())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ShowTutorialPrompt(IslandRedBlueStickyGrenadeTutorialComponent.PromptFire, this);

		if(!IslandRedBlueStickyGrenadeTutorialComponent.bFirstPromptShown)
			IslandRedBlueStickyGrenadeTutorialComponent.bFirstPromptShown = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}
};