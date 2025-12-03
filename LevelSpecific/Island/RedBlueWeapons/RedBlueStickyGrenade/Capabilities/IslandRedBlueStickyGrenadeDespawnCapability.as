class UIslandRedBlueStickyGrenadeDespawnCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(IslandRedBlueStickyGrenade::IslandRedBlueStickyGrenade);

	UIslandRedBlueStickyGrenadeUserComponent GrenadeUserComp;
	UPlayerInteractionsComponent InteractionsComp;
	UIslandSidescrollerComponent SidescrollerComp;
	UIslandRedBlueStickyGrenadeSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrenadeUserComp = UIslandRedBlueStickyGrenadeUserComponent::Get(Player);
		InteractionsComp = UPlayerInteractionsComponent::Get(Player);
		SidescrollerComp = UIslandSidescrollerComponent::GetOrCreate(Player);
		Settings = UIslandRedBlueStickyGrenadeSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandRedBlueStickyGrenadeDespawnActivatedParams& Params) const
	{
		if(!GrenadeUserComp.Grenade.IsGrenadeThrown())
			return false;

		if(Player.IsPlayerDead())
			return true;

		if(InteractionsComp.ActiveInteraction != nullptr)
			return true;

		if(Player.ActorLocation.Distance(GrenadeUserComp.Grenade.ActorLocation) > Settings.DespawnDistance)
		{
			Params.bShouldPlayFailEffect = true;
			return true;
		}

		if(!GrenadeUserComp.IsGrenadeAttached() && Settings.MaxInAirTime > 0.0 && Time::GetGameTimeSince(GrenadeUserComp.Grenade.TimeOfThrow) > Settings.MaxInAirTime)
		{
			Params.bShouldPlayFailEffect = true;
			return true;
		}

		if(GrenadeUserComp.Grenade.IsGrenadeAttached() && 
			(GrenadeUserComp.Grenade.RootComponent.AttachParent == nullptr || 
			!Cast<UPrimitiveComponent>(GrenadeUserComp.Grenade.RootComponent.AttachParent).IsCollisionEnabled()))
		{
			Params.bShouldPlayFailEffect = true;
			return true;
		}

		// If we are in sidescroller and the grenade goes off screen we want it to despawn
		if(SidescrollerComp.IsInSidescrollerMode() && !SceneView::ViewFrustumPointRadiusIntersection(Game::Mio, GrenadeUserComp.Grenade.ActorLocation, GrenadeUserComp.Grenade.Collision.SphereRadius))
		{
			Params.bShouldPlayFailEffect = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandRedBlueStickyGrenadeDespawnActivatedParams Params)
	{
		GrenadeUserComp.Grenade.ResetGrenade(Params.bShouldPlayFailEffect);
	}
}

struct FIslandRedBlueStickyGrenadeDespawnActivatedParams
{
	bool bShouldPlayFailEffect = false;
}