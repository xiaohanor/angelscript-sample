class UCoastBossAeronauticHomingPowerUpCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default CapabilityTags.Add(CoastBossTags::CoastBossPlayerShootTag);
	default CapabilityTags.Add(CoastBossTags::CoastBossPowerUp);

	UCoastBossAeronauticComponent AeroComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AeroComp = UCoastBossAeronauticComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasPowerUp())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HasPowerUp())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilitiesExcluding(CoastBossTags::CoastBossPlayerShootTag, CoastBossTags::CoastBossPowerUp, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CoastBossTags::CoastBossPlayerShootTag, this);
	}

	bool HasPowerUp() const
	{
		if(CoastBossDevToggles::HomingPlayerPowerUp.IsEnabled())
			return true;

		if(Time::GetGameTimeSince(AeroComp.LastPowerUpTimestamp) > CoastBossConstants::PowerUp::HomingPowerUpDuration)
			return false;

		if(AeroComp.LastPowerUpType != ECoastBossPlayerPowerUpType::Homing)
			return false;

		return true;
	}
}