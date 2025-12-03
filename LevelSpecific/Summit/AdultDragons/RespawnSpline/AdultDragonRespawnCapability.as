class UAdultDragonRespawnCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);
	// default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	bool bHasBlockedRespawn = false;

	FSplinePosition RespawnSplinePos;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplyRespawnPointOverrideDelegate(this, FOnRespawnOverride(this, n"HandleRespawn"), EInstigatePriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearRespawnPointOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (CheckShouldBlockRespawn())
		{
			if (!bHasBlockedRespawn)
			{
				TEMPORAL_LOG(Player).Event("BlockedRespawn");
				bHasBlockedRespawn = true;
				Player.BlockCapabilities(CapabilityTags::Respawn, this);
			}
		}
		else
		{
			if (bHasBlockedRespawn)
			{
				TEMPORAL_LOG(Player).Event("UnblockedRespawn");
				bHasBlockedRespawn = false;
				Player.UnblockCapabilities(CapabilityTags::Respawn, this);
			}
		}
	}

	bool CheckShouldBlockRespawn()
	{
		auto SplineComp = UAdultDragonSplineFollowManagerComponent::Get(Player.OtherPlayer);
		if (SplineComp == nullptr)
			return false;

		RespawnSplinePos = SplineComp.CurrentSplineFollowData.Value.GetMostActiveSplinePosition();
		auto RespawnSpline = Cast<AAdultDragonRespawnSpline>(RespawnSplinePos.CurrentSpline.Owner);
		if (RespawnSpline == nullptr)
			return false;

		auto RespawnBlockZoneComp = RespawnSpline.GetClosestOfMultipleRespawnBlockZoneAtDistanceAlongSpline(RespawnSplinePos.CurrentSplineDistance);
		if (RespawnBlockZoneComp == nullptr)
		{
			RespawnBlockZoneComp = RespawnSpline.GetClosestRespawnBlockZoneAtDistanceAlongSpline(RespawnSplinePos.CurrentSplineDistance);
			if (RespawnBlockZoneComp == nullptr)
				return false;
		}

		return true;
	}

	UFUNCTION()
	private bool HandleRespawn(AHazePlayerCharacter RespawningPlayer, FRespawnLocation& OutLocation)
	{
		if (Player.OtherPlayer.IsPlayerDead())
			return false;

		OutLocation.RespawnTransform.Location = RespawnSplinePos.WorldLocation;
		OutLocation.RespawnTransform.Rotation = RespawnSplinePos.WorldRotation;
		auto OtherComp = UAdultDragonSplineFollowManagerComponent::Get(Player.OtherPlayer);
		if (HasControl())
			UAdultDragonSplineFollowManagerComponent::Get(Player).CrumbSetSplineToFollow(OtherComp.CurrentSplineActor);
		return true;
	}
};