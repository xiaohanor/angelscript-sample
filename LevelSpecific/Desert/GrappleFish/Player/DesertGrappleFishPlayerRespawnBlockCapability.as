class UDesertGrappleFishRespawnBlockCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::AfterGameplay;
	UDesertGrappleFishPlayerComponent PlayerComp;
	bool bHasBlockedRespawn = false;

	UPlayerHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDesertGrappleFishPlayerComponent::Get(Player);
		HealthComp = UPlayerHealthComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Desert::GetRelevantLandscapeLevel() != ESandSharkLandscapeLevel::Secondary)
			return false;

		if (PlayerComp.GrappleFish == nullptr)
			return false;

		if (PlayerComp.GrappleFish.State.Get() != EDesertGrappleFishState::Mounted)
			return false;

		if (PlayerComp.GrappleFish.AutoPilotSplinePosition.CurrentSpline == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Desert::GetRelevantLandscapeLevel() != ESandSharkLandscapeLevel::Secondary)
			return true;
		
		if (PlayerComp.GrappleFish == nullptr)
			return true;

		if (PlayerComp.GrappleFish.State.Get() != EDesertGrappleFishState::Mounted)
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
		if (bHasBlockedRespawn)
		{
			Player.UnblockCapabilities(n"Respawn", this);
			bHasBlockedRespawn = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bHasBlockedRespawn)
		{
			if (!CanRespawn())
			{
				bHasBlockedRespawn = true;
				Player.BlockCapabilities(n"Respawn", this);
				TEMPORAL_LOG(PlayerComp.GrappleFish).Event("Respawn Blocked");
			}
		}
		else
		{
			if (CanRespawn() && Time::GetGameTimeSince(HealthComp.GameTimeOfDeath) > GrappleFishPlayer::MinRespawnCooldown)
			{
				Player.UnblockCapabilities(n"Respawn", this);
				bHasBlockedRespawn = false;
				TEMPORAL_LOG(PlayerComp.GrappleFish).Event("Respawn Unblocked");
			}
		}
	}

	bool CanRespawn() const
	{
		const float DistanceAlongSpline = PlayerComp.GrappleFish.AutoPilotSplinePosition.CurrentSplineDistance;

		if (PlayerComp.GrappleFish.AnimData.bIsDiving)
			return false;

		if (PlayerComp.GrappleFish.bWantsToDive)
			return false;

		if (!PlayerComp.GrappleFish.CanPlayerRespawnOnFish())
			return false;

		float TimeSinceStoppedDiving = Time::GetGameTimeSince(PlayerComp.GrappleFish.TimeWhenStoppedDiving);

		if (TimeSinceStoppedDiving > 0 && TimeSinceStoppedDiving < 0.4)
			return false;

		if (!PlayerComp.GrappleFish.bIsFollowingSpline)
			return false;
		
		const ASandSharkSpline Spline = Cast<ASandSharkSpline>(PlayerComp.GrappleFish.AutoPilotSplinePosition.CurrentSpline.Owner);
		
		if (Spline == nullptr)
			return true;

		if (Spline.GetRespawnBlockZoneAtDistanceAlongSpline(DistanceAlongSpline) == nullptr)
			return true;

		return false;
	}
};