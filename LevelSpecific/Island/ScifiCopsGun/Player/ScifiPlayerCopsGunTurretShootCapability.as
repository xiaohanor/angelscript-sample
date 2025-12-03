
struct FScifiPlayerCopsGunTurretShootActivation
{
	int RandomSeedIndex = 0;
}

class UScifiPlayerCopsGunTurretShootCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"CopsGun");
	default CapabilityTags.Add(n"CopsGunShoot");
	default CapabilityTags.Add(BlockedWhileIn::Swimming);

	default DebugCategory = n"CopsGun";

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UScifiPlayerCopsGunManagerComponent Manager;
	UScifiPlayerCopsGunSettings Settings;
	ACopsGunTurret Turret;
	AScifiCopsGun LeftWeapon;
	AScifiCopsGun RightWeapon;
	float NextShootTime = 0;
	AScifiCopsGun NextShootWeapon;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = UScifiPlayerCopsGunManagerComponent::Get(Player);
		Turret = Manager.Turret;
		//Weapon = Turret.WeaponLink;
		Settings = Manager.Settings;
		Manager.EnsureWeaponSpawn(Player, LeftWeapon, RightWeapon);
		NextShootWeapon = LeftWeapon;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FScifiPlayerCopsGunTurretShootActivation& Activation) const
	{
		if(!Manager.bTurretIsActive)
			return false;

		if(Manager.Turret.CurrentAttachment != nullptr 
			&& Manager.Turret.CurrentAttachment.Type == EScifiPlayerCopsGunAttachTargetType::Hacking)	
			return false;

		if(!IsActioning(ActionNames::WeaponFire))
			return false;

		if(Manager.HasTriggeredOverheat())
			return false;
		
		Activation.RandomSeedIndex = Math::RandRange(0, Manager.RandomBulletDirection.Num() - 1);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{		
		if(!Manager.bTurretIsActive)
			return true;

		if(Manager.Turret.CurrentAttachment != nullptr 
			&& Manager.Turret.CurrentAttachment.Type == EScifiPlayerCopsGunAttachTargetType::Hacking)	
			return true;

		if(!IsActioning(ActionNames::WeaponFire))
			return true;

		if(Manager.HasTriggeredOverheat())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FScifiPlayerCopsGunTurretShootActivation Activation)
	{
		Manager.RandomBulletDirectonIndex = Activation.RandomSeedIndex;
		Manager.WantToShootInstigators.Add(this);	 	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LeftWeapon.bIsShooting = false;
		RightWeapon.bIsShooting = false;
		Manager.WantToShootInstigators.RemoveSingleSwap(this);
		NextShootTime = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		NextShootTime -= DeltaTime;
		if(NextShootTime <= 0)
		{		
			NextShootTime += Settings.CooldownBetweenBullets * Manager.GetCooldownBetweenBulletsModifier();
			Manager.IncreaseHeat(Settings.TurretHeadModifier);
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

		if(Manager.CurrentShootAtTarget != nullptr)
		{
			Bullet.PendingImpactTarget = Manager.CurrentShootAtTarget;
			Bullet.MoveDirection = (Manager.CurrentShootAtTarget.WorldLocation - Turret.Muzzle.WorldLocation).GetSafeNormal();
		}
		else
		{
			Bullet.MoveDirection = Turret.ActorForwardVector;
		}

		FVector BulletStartLocation = Turret.Muzzle.WorldLocation;
		Bullet.SetActorLocation(BulletStartLocation);
		Manager.ActivateBullet(Bullet);
		
		// Trigger shoot event
		FScifiPlayerCopsGunOnShootEventData ShootData;
		ShootData.WeaponInstigator = Bullet.WeaponInstigator;
		ShootData.Bullet = Bullet;
		ShootData.MuzzleLocation = BulletStartLocation;
		ShootData.ShootDirection = Bullet.MoveDirection;
		ShootData.OverheatAmount = Manager.CurrentHeat;
		ShootData.OverheatMaxAmount = Settings.MaxHeat;
		UScifiCopsGunEventHandler::Trigger_OnShoot(Weapon, ShootData);
		UScifiPlayerCopsGunEventHandler::Trigger_OnShoot(Weapon.PlayerOwner, ShootData);
	}
};
