class USummitCrystalSkullRegrowArmourCapability : UHazeCapability
{
	USummitCrystalSkullArmourComponent ArmourComp;
	USummitCrystalSkullArmourSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ArmourComp = USummitCrystalSkullArmourComponent::Get(Owner);
		Settings = USummitCrystalSkullArmourSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (ArmourComp == nullptr)
			return false;
		if (ArmourComp.Armour == nullptr)
			return false;
		if (ArmourComp.HasArmour())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ArmourComp.HasArmour())
			return true;
		if (ActiveDuration > Settings.RegrowDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (ActiveDuration > Settings.RegrowDuration)
			ArmourComp.Armour.Regrow();	
	}
}
