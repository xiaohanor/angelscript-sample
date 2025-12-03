class UJetskiDriverBlockRespawnCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::AfterGameplay;

	UJetskiDriverComponent DriverComp;
	UPlayerHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UJetskiDriverComponent::Get(Player);
		HealthComp = UPlayerHealthComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(CanRespawnPlayer())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(CanRespawnPlayer())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::Respawn, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Respawn, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	bool CanRespawnPlayer() const
	{
		if(!HealthComp.bIsDead)
			return false;

		const AJetski OtherJetski = Jetski::GetOtherJetski(DriverComp.Jetski);
		const AJetskiRespawnSpline ClosestRespawnSpline = Jetski::GetClosestRespawnSpline(OtherJetski.ActorLocation);
		if(ClosestRespawnSpline == nullptr)
		{
			check(false, "No respawn spline found!");
			return false;
		}

		const float OtherDistanceAlongRespawnSpline = ClosestRespawnSpline.Spline.GetClosestSplineDistanceToWorldLocation(OtherJetski.ActorLocation);

		auto FollowingDeath = AJetskiFollowingDeath::Get();
		if(FollowingDeath != nullptr)
		{
			const float FollowingDeathDistanceAlongRespawnSpline = ClosestRespawnSpline.Spline.GetClosestSplineDistanceToWorldLocation(TListedActors<AJetskiFollowingDeath>().Single.GetWorldLocation());

			if(OtherDistanceAlongRespawnSpline < FollowingDeathDistanceAlongRespawnSpline)
			{
				// The other player is behind the following death, we can't possibly respawn!
				return false;
			}
		}

		const TOptional<FAlongSplineComponentData> ZoneData = ClosestRespawnSpline.Spline.FindPreviousComponentAlongSpline(UJetskiRespawnSplineZoneComponent, false, OtherDistanceAlongRespawnSpline);

		if(ZoneData.IsSet())
		{
			auto ZoneComp = Cast<UJetskiRespawnSplineZoneComponent>(ZoneData.Value.Component);
			if(!ZoneComp.CanRespawnWithinZone())
				return false;
		}

		return true;
	}
};