
class UScifiPlayerCopsGunEquipCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"CopsGun");
	default CapabilityTags.Add(n"CopsGunShootInput");
	default CapabilityTags.Add(CombatBlockedWhileIn::GloryKill);
	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	default DebugCategory = n"CopsGun";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	const float TimeUntilWeaponDetach = 2;

	UScifiPlayerCopsGunManagerComponent Manager;
	UPlayerMovementComponent PlayerMoveComp;
	UScifiPlayerCopsGunSettings Settings;
	AScifiCopsGun LeftWeapon;
	AScifiCopsGun RightWeapon;

	const EScifiPlayerCopsGunType Hand;
	UScifiCopsGunCrosshair CrosshairWidget;
	float DontShootTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = UScifiPlayerCopsGunManagerComponent::Get(Player);
		PlayerMoveComp = UPlayerMovementComponent::Get(Player);
		Settings = Manager.Settings;
		Manager.EnsureWeaponSpawn(Player, LeftWeapon, RightWeapon);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Manager.bPlayerWantsToShootWeapon)
			return false;

		if(!Manager.WeaponsAreAttachedToPlayer())
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(DontShootTime >= TimeUntilWeaponDetach)
			return true;

		if(!Manager.WeaponsAreAttachedToPlayer())
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
		DontShootTime = 0;
		if(Manager.WeaponsAreAttachedToPlayerHand(this))
		{
			Manager.AttachWeaponToPlayerThigh(LeftWeapon, this);
			Manager.AttachWeaponToPlayerThigh(RightWeapon, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(Manager.bPlayerWantsToShootWeapon)
		{
			if(!Manager.WeaponsAreAttachedToPlayerHand(this))
			{
				Manager.AttachWeaponToPlayerHand(LeftWeapon, this);
				Manager.AttachWeaponToPlayerHand(RightWeapon, this);
			}

			DontShootTime = 0;	
		}
		else
		{
			DontShootTime += DeltaTime;
		}

		if(Player.Mesh.CanRequestOverrideFeature())
		{
			bool bCanRequestAnimation = Manager.bPlayerWantsToShootWeapon;
			if(Player.IsCapabilityTagBlocked(BlockedWhileIn::Dash))
				bCanRequestAnimation = false;
			else if(Player.IsCapabilityTagBlocked(BlockedWhileIn::AirJump))
				bCanRequestAnimation = false;

			// Keep the weapons in the hands but loosen up the upper body
			if(bCanRequestAnimation && DontShootTime < TimeUntilWeaponDetach * 0.5)
				Player.Mesh.RequestOverrideFeature(n"CopsGunAimOverride", this);
		}
	}


};