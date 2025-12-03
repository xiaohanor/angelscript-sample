
struct FScifiCopsGunHandShootActivation
{
	int RandomSeedIndex = 0;
	bool bWithAttachAnimationDelay = false;
}

class UScifiPlayerCopsGunHandShootCapability : UHazePlayerCapability
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
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	default CapabilityTags.Add(BlockedWhileIn::AirJump);
	default CapabilityTags.Add(BlockedWhileIn::Dash);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	default DebugCategory = n"CopsGun";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UScifiPlayerCopsGunManagerComponent Manager;
	UPlayerMovementComponent PlayerMoveComp;
	UPlayerAimingComponent AimingComp;
	UScifiPlayerCopsGunSettings Settings;
	AScifiCopsGun LeftWeapon;
	AScifiCopsGun RightWeapon;

	const EScifiPlayerCopsGunType Hand;
	UScifiCopsGunCrosshair CrosshairWidget;
	float NextShootTime = 0;
	AScifiCopsGun NextShootWeapon;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = UScifiPlayerCopsGunManagerComponent::Get(Player);
		PlayerMoveComp = UPlayerMovementComponent::Get(Player);
		AimingComp = UPlayerAimingComponent::Get(Player);
		Settings = Manager.Settings;
		Manager.EnsureWeaponSpawn(Player, LeftWeapon, RightWeapon);
		NextShootWeapon = LeftWeapon;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FScifiCopsGunHandShootActivation& Activation) const
	{
		if(!IsActioning(ActionNames::WeaponFire))
			return false;

		if(!Manager.WeaponsAreAttachedToPlayer())
			return false;

		if(Manager.bPlayerWantsToThrowWeapon)
			return false;

		if(Manager.HasTriggeredOverheat())
			return false;

		if(Time::GetGameTimeSince(Manager.CurrentWeaponStatusGameTime) < 0.25)
			return false;
		
		Activation.RandomSeedIndex = Math::RandRange(0, Manager.RandomBulletDirection.Num() - 1);
		if(!Manager.WeaponsAreAttachedToPlayerHand())
			Activation.bWithAttachAnimationDelay = true;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!IsActioning(ActionNames::WeaponFire))
			return true;

		if(!Manager.WeaponsAreAttachedToPlayer())
			return true;

		if(Manager.bPlayerWantsToThrowWeapon)
			return true;

		if(Manager.HasTriggeredOverheat())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FScifiCopsGunHandShootActivation Activation)
	{
		Manager.WantToShootInstigators.Add(this);	 
		Manager.RandomBulletDirectonIndex = Activation.RandomSeedIndex;

		if(Activation.bWithAttachAnimationDelay)
			NextShootTime = 0.1;
		else
			NextShootTime = 0;

		AimingComp.StartAiming(Manager, Manager.AimSettings);
		CrosshairWidget = Cast<UScifiCopsGunCrosshair>(AimingComp.GetCrosshairWidget(Manager));
		CrosshairWidget.bShooting = true;
		CrosshairWidget.bHasAimTarget = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LeftWeapon.bIsShooting = false;
		RightWeapon.bIsShooting = false;
		Manager.WantToShootInstigators.RemoveSingleSwap(this);

		AimingComp.StopAiming(Manager);
		CrosshairWidget.bShooting = false;
		CrosshairWidget = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(CrosshairWidget != nullptr)
			CrosshairWidget.bHasShootTarget = Manager.CurrentShootAtTarget != nullptr;

		NextShootTime -= DeltaTime;
		if(NextShootTime <= 0)
		{		
			NextShootTime += Settings.CooldownBetweenBullets * Manager.GetCooldownBetweenBulletsModifier();
			Manager.IncreaseHeat();
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
			FVector UpVector = Weapon.PlayerOwner.MovementWorldUp;

			// Offset for the crosshair;
			FVector CrossHairOffset = UpVector * 45.0;
			FRotator ViewRotation = Weapon.PlayerOwner.GetViewRotation();
			ViewRotation += FRotator(8.0, 0.0, 0.0); 
	
			FVector TraceFrom = Weapon.PlayerOwner.GetActorLocation() + (UpVector * Weapon.PlayerOwner.CapsuleComponent.GetScaledCapsuleHalfHeight() * 2) + CrossHairOffset;
			FVector TraceTo = TraceFrom + (ViewRotation.ForwardVector * 10000.0);

			auto TraceSettings = Trace::InitChannel(Settings.TraceChannel);
			TraceSettings.UseLine();
			// TraceSettings.DebugDraw(5);

			FHitResult Hit = TraceSettings.QueryTraceSingle(TraceFrom, TraceTo);
			if(Hit.bBlockingHit)
			{
				Bullet.MoveDirection = (Hit.ImpactPoint - Weapon.MuzzlePoint.WorldLocation).GetSafeNormal();
			}
			else
			{
				Bullet.MoveDirection = (TraceTo - Weapon.MuzzlePoint.WorldLocation).GetSafeNormal();
			}
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