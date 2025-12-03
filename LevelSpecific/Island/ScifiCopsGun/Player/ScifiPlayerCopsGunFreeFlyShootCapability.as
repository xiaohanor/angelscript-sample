struct FScifiCopsGunFreeFlyShootActivation
{
	int RandomSeedIndex = 0;
	bool bWithOverheat = false;
}

class UScifiPlayerCopsGunFreeFlyShootCapability : UHazePlayerCapability
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

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	default DebugCategory = n"CopsGun";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UScifiPlayerCopsGunManagerComponent Manager;
	UPlayerMovementComponent PlayerMoveComp;
	UScifiPlayerCopsGunSettings Settings;
	AScifiCopsGun LeftWeapon;
	AScifiCopsGun RightWeapon;

	bool bShootWithOverheat = false;
	float NextShootTime = 0;
	AScifiCopsGun NextShootWeapon;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = UScifiPlayerCopsGunManagerComponent::Get(Player);
		PlayerMoveComp = UPlayerMovementComponent::Get(Player);
		Settings = Manager.Settings;
		Manager.EnsureWeaponSpawn(Player, LeftWeapon, RightWeapon);
		NextShootWeapon = LeftWeapon;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FScifiCopsGunFreeFlyShootActivation& Activation) const
	{
		if(Manager.WeaponsAreAttachedToPlayer())
			return false;

		if(Manager.WeaponsAreAttachedToTarget())
			return false;

		if(Manager.bPlayerWantsToThrowWeapon)
			return false;

		if(!IsActioning(ActionNames::WeaponFire) && !Manager.HasTriggeredOverheat())
			return false;

		Activation.RandomSeedIndex = Math::RandRange(0, Manager.RandomBulletDirection.Num() - 1);
		Activation.bWithOverheat = Manager.HasTriggeredOverheat();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Manager.WeaponsAreAttachedToPlayer())
			return true;

		if(Manager.WeaponsAreAttachedToTarget())
			return true;

		if(Manager.bPlayerWantsToThrowWeapon)
			return true;

		if(!IsActioning(ActionNames::WeaponFire) && !Manager.HasTriggeredOverheat())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FScifiCopsGunFreeFlyShootActivation Activation)
	{
		Manager.WantToShootInstigators.Add(this);	 
		bShootWithOverheat = Activation.bWithOverheat;
		Manager.RandomBulletDirectonIndex = Activation.RandomSeedIndex;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LeftWeapon.bIsShooting = false;
		RightWeapon.bIsShooting = false;
		Manager.WantToShootInstigators.RemoveSingleSwap(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		NextShootTime -= DeltaTime;
		if(NextShootTime <= 0)
		{		
			NextShootTime += Settings.CooldownBetweenBullets * Manager.GetCooldownBetweenBulletsModifier();
			if(bShootWithOverheat)
				NextShootTime *= 0.3;

			ShootInternal(NextShootWeapon);
			NextShootWeapon = NextShootWeapon.OtherWeapon;
		}
	}


	void ShootInternal(AScifiCopsGun Weapon)
	{
		Weapon.OtherWeapon.bIsShooting = false;
		Weapon.bIsShooting = true;
		Weapon.LastShotGameTime = Time::GetGameTimeSeconds();
		
		auto Bullet = Manager.GetOrCreateLocalProjectile();
		Bullet.WeaponInstigator = Weapon.AttachType;
		Bullet.CurrentMovementSpeed = Settings.BulletInitialSpeed;

		if(Weapon.CurrentShootAtTarget != nullptr)
		{
			Bullet.PendingImpactTarget = Weapon.CurrentShootAtTarget;
			Bullet.MoveDirection = (Weapon.CurrentShootAtTarget.WorldLocation - Weapon.MuzzlePoint.WorldLocation).GetSafeNormal();
		}
		else
		{
			Bullet.MoveDirection = Manager.RandomBulletDirection[Manager.RandomBulletDirectonIndex];
			Manager.RandomBulletDirectonIndex++;
			if(Manager.RandomBulletDirectonIndex >= Manager.RandomBulletDirection.Num())
				Manager.RandomBulletDirectonIndex = 0;
		}

		Manager.LastWeapon = Weapon.AttachType;
		Weapon.LastShotGameTime = Time::GetGameTimeSeconds();

		FVector BulletStartLocation = Weapon.MuzzlePoint.WorldLocation;
		Bullet.SetActorLocation(BulletStartLocation);
		Manager.ActivateBullet(Bullet);
		
		// Trigger shoot event
		FScifiPlayerCopsGunOnShootEventData ShootData;
		ShootData.WeaponInstigator = Weapon.AttachType;
		ShootData.Bullet = Bullet;
		ShootData.MuzzleLocation = BulletStartLocation;
		ShootData.ShootDirection = Bullet.MoveDirection;
		ShootData.OverheatAmount = Manager.CurrentHeat;
		ShootData.OverheatMaxAmount = Settings.MaxHeat;
		UScifiCopsGunEventHandler::Trigger_OnShoot(Weapon, ShootData);
		UScifiPlayerCopsGunEventHandler::Trigger_OnShoot(Weapon.PlayerOwner, ShootData);
	}

};