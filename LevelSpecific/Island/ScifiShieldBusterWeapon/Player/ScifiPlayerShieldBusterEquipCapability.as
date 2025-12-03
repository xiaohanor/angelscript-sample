

class UScifiPlayerShieldBusterEquipCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"ShieldBuster");
	default CapabilityTags.Add(n"ShieldBusterEquipped");

	default DebugCategory = n"ShieldBuster";
	
	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 100;

	UScifiPlayerShieldBusterManagerComponent Manager;
	AScifiPlayerShieldBusterWeapon LeftWeapon;
	AScifiPlayerShieldBusterWeapon RightWeapon;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = UScifiPlayerShieldBusterManagerComponent::Get(Player);
		Manager.EnsureWeaponSpawn(Player, LeftWeapon, RightWeapon);
		LeftWeapon.AddActorDisable(this);
		RightWeapon.AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return Manager.HasEquipedWeapons();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !Manager.HasEquipedWeapons();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Manager.bHasEquipedWeapons = true;
		LeftWeapon.RemoveActorDisable(this);
		RightWeapon.RemoveActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Manager.bHasEquipedWeapons = false;
		LeftWeapon.AddActorDisable(this);
		RightWeapon.AddActorDisable(this);
	}
}