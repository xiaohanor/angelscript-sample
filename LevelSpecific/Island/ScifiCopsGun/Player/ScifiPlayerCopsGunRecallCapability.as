

class UScifiPlayerCopsGunRecallCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"CopsGun");
	default CapabilityTags.Add(n"CopsGunThrow");
	default CapabilityTags.Add(CombatBlockedWhileIn::GloryKill);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);

	default DebugCategory = n"CopsGun";

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 95;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 110);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UScifiPlayerCopsGunManagerComponent Manager;
	UScifiPlayerCopsGunSettings Settings;
	AScifiCopsGun LeftWeapon;
	AScifiCopsGun RightWeapon;
	TArray<bool> InternalWeaponsAreBack;
	default InternalWeaponsAreBack.SetNum(EScifiPlayerCopsGunType::MAX);


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = UScifiPlayerCopsGunManagerComponent::Get(Player);
		Settings = Manager.Settings;
		Manager.EnsureWeaponSpawn(Player, LeftWeapon, RightWeapon);
		InternalWeaponsAreBack[EScifiPlayerCopsGunType::Left] = true;
		InternalWeaponsAreBack[EScifiPlayerCopsGunType::Right] = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(LeftWeapon.IsWeaponAttachedToPlayer())
			return false;

		if(RightWeapon.IsWeaponAttachedToPlayer())
			return false;
				
		if(Time::GetGameTimeSince(LeftWeapon.CurrentStateActivationTime) < Settings.RecallDelayTime)
			return false;

		if(Time::GetGameTimeSince(RightWeapon.CurrentStateActivationTime) < Settings.RecallDelayTime)
			return false;

		if(WasActionStarted(ActionNames::WeaponAim))
			return true;	

		if(Manager.bForceRecal)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!LeftWeapon.IsWeaponAttachedToPlayer())
			return false;

		if(!RightWeapon.IsWeaponAttachedToPlayer())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Manager.RecallWeapons(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Manager.bForceRecal = false;
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

	}
};