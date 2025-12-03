class UWingsuitBossWeaponsActiveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	// default CapabilityTags.Add(WingsuitBossTags::WingsuitBossAttack);

	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AWingsuitBoss Boss;
	UWingsuitBossSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<AWingsuitBoss>(Owner);
		Settings = UWingsuitBossSettings::GetSettings(Boss);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Boss.bWeaponsActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Boss.bWeaponsActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.MineLauncher.Extend(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.MineLauncher.Retract(this);
	}
}