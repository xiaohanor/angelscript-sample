class UIslandRedBlueWeaponCoolDownCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(IslandRedBlueWeapon::IslandRedBlueWeapon);
	default CapabilityTags.Add(IslandRedBlueWeapon::IslandRedBlueEquipped);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	UIslandRedBlueWeaponUserComponent WeaponUserComponent;
	UIslandRedBlueWeaponSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeaponUserComponent = UIslandRedBlueWeaponUserComponent::Get(Player);
		Settings = UIslandRedBlueWeaponSettings::GetSettings(Player);
	}

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
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!WeaponUserComponent.WantsToFireWeapon())
		{
			WeaponUserComponent.NextShootDelayTimeLeft = Settings.StartShootDelay;
		}
		else if(WeaponUserComponent.NextShootDelayTimeLeft > 0)
		{
			WeaponUserComponent.NextShootDelayTimeLeft -= DeltaTime;
		}
	}
};