class UIslandRedBlueStickyGrenadeThrowForceFeedbackTriggerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(IslandRedBlueStickyGrenade::IslandRedBlueStickyGrenade);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	UIslandRedBlueStickyGrenadeUserComponent GrenadeUserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrenadeUserComp = UIslandRedBlueStickyGrenadeUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(GrenadeUserComp.Grenade.IsGrenadeThrown())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(GrenadeUserComp.Grenade.IsGrenadeThrown())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
}