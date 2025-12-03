

// class UScifiCopsGunHandShootCapability : UHazeCapability
// {
// 	default CapabilityTags.Add(n"CopsGun");
// 	default CapabilityTags.Add(n"CopsGunShoot");
// 	default CapabilityTags.Add(CombatBlockedWhileIn::GloryKill);

// 	default DebugCategory = n"CopsGun";

// 	default TickGroup = EHazeTickGroup::BeforeMovement;
// 	default TickGroupOrder = 100;
// 	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 120);

// 	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

// 	UScifiPlayerCopsGunManagerComponent Manager;
// 	UScifiPlayerCopsGunSettings Settings;

// 	AScifiCopsGun Weapon;
// 	AScifiCopsGun OtherWeapon;
// 	float LastActiveDeltaTime = 0;
// 	float DeactivationDuration = 0;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup()
// 	{
// 		Weapon = Cast<AScifiCopsGun>(Owner);
// 		Manager = UScifiPlayerCopsGunManagerComponent::Get(Weapon.PlayerOwner);
// 		Settings = Weapon.Settings;
// 		OtherWeapon = Weapon.OtherWeapon;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldActivate(FCopsGunShootCapabilityActivationParams& ActivationParam) const
// 	{
// 		if(!Weapon.IsWeaponAttachedToPlayerHand())
// 			return false;	

// 		if(!Weapon.bPlayerWantsToShoot)
// 			return false;

// 		if(Weapon.bHasTriggeredOverHeat)
// 			return false;
		
// 		if(Time::GetGameTimeSeconds() < Weapon.StartShootGameTime)
// 			return false;

// 		// Always wait while any weapon is shooting
// 		if(Weapon.bIsShooting)
// 			return false;

// 		// if(Weapon.WeaponWantsToReload())
// 		// 	return false;

// 		if(Weapon.IsWeaponBlocked())
// 			return false;

// 		if(OtherWeapon.bIsShooting)
// 			return false;
		
// 		// If the other hand can shoot, we should skip this hand
// 		if(Manager.LastWeapon == Weapon.AttachType && !OtherWeapon.IsWeaponBlocked())
// 			return false;

// 		ActivationParam.Bullet = Manager.GetOrCreateControlSideProjectile();
	
// 		if(Weapon.CurrentShootAtTarget != nullptr && Weapon.CurrentShootAtTarget.bCanTargetWhileHandShooting)
// 		{
// 			ActivationParam.Target = Weapon.CurrentShootAtTarget;
// 			ActivationParam.ShootDir = (ActivationParam.Target.WorldLocation - Weapon.MuzzlePoint.WorldLocation).GetSafeNormal();
// 		}
// 		else
// 		{
// 			FVector UpVector = Weapon.PlayerOwner.MovementWorldUp;

// 			// Offset for the crosshair;
// 			FVector CrossHairOffset = UpVector * 45.0;
// 			FRotator ViewRotation = Weapon.PlayerOwner.GetViewRotation();
// 			ViewRotation += FRotator(8.0, 0.0, 0.0); 
	
// 			FVector TraceFrom = Weapon.PlayerOwner.GetActorLocation() + (UpVector * Weapon.PlayerOwner.CapsuleComponent.GetScaledCapsuleHalfHeight() * 2) + CrossHairOffset;
// 			FVector TraceTo = TraceFrom + (ViewRotation.ForwardVector * 10000.0);

// 			auto TraceSettings = Trace::InitChannel(Settings.TraceChannel);
// 			TraceSettings.UseLine();
// 			// TraceSettings.DebugDraw(5);

// 			FHitResult Hit = TraceSettings.QueryTraceSingle(TraceFrom, TraceTo);
// 			if(Hit.bBlockingHit)
// 			{
// 				ActivationParam.ShootDir = (Hit.ImpactPoint - Weapon.MuzzlePoint.WorldLocation).GetSafeNormal();
// 			}
// 			else
// 			{
// 				ActivationParam.ShootDir = (TraceTo - Weapon.MuzzlePoint.WorldLocation).GetSafeNormal();
// 			}
// 		}
		
// 		return true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldDeactivate() const
// 	{		
// 		if(ActiveDuration >= DeactivationDuration)
// 			return true;

// 		return false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCopsGunShootCapabilityActivationParams ActivationParam)
// 	{
// 		Weapon.bIsShooting = true;
// 		Manager.LastWeapon = Weapon.AttachType;
// 		Weapon.LastShotGameTime = Time::GetGameTimeSeconds();

// 		auto Bullet = ActivationParam.Bullet;
// 		Bullet.WeaponInstigator = Weapon.AttachType;
// 		Bullet.CurrentMovementSpeed = Settings.BulletInitialSpeed;
// 		Bullet.PendingImpactTarget = ActivationParam.Target;
// 		Bullet.MoveDirection = ActivationParam.ShootDir;

// 		// if(Weapon.BulletsLeftToReload > 0)
// 		// 	Weapon.BulletsLeftToReload -= 1;

// 		DeactivationDuration = Settings.CooldownBetweenBullets * Weapon.GetCooldownBetweenBulletsModifier();

// 		// If we can't shoot both weapons individually
// 		// we need to half the shoot cooldown time
// 		// since we can't shoot both weapons at the same time
// 		DeactivationDuration *= 0.5;	

// 		// Handle heat
// 		if(Settings.HeatIncreasePerBullet > KINDA_SMALL_NUMBER)
// 		{
// 			Weapon.CurrentHeat += Settings.HeatIncreasePerBullet;	
// 		}

// 		FVector BulletStartLocation = Weapon.MuzzlePoint.WorldLocation;
// 		Bullet.SetActorLocation(BulletStartLocation);

// 		if(Bullet.PendingImpactTarget != nullptr)
// 		{
// 			FVector MoveDir = Bullet.PendingImpactTarget.GetWorldLocation() - BulletStartLocation;
// 			if(MoveDir.SizeSquared() > KINDA_SMALL_NUMBER)
// 				Bullet.MoveDirection = MoveDir.GetSafeNormal();
// 		}

// 		Manager.ActivateBullet(Bullet);
		
// 		// Trigger shoot event
// 		FScifiPlayerCopsGunOnShootEventData ShootData;
// 		ShootData.Bullet = Bullet;
// 		ShootData.MuzzleLocation = BulletStartLocation;
// 		ShootData.ShootDirection = Bullet.MoveDirection;
// 		ShootData.OverheatAmount = Weapon.CurrentHeat;
// 		ShootData.OverheatMaxAmount = Settings.MaxHeat;
// 		Weapon.TriggerEffectEvent(n"CopsGun.OnShoot", ShootData);

// 		//Only trigger on left gun for Overheat Audio
// 		if (Weapon.IsLeftWeapon())
// 			Weapon.PlayerOwner.TriggerEffectEvent(n"CopsGun.OnShoot", ShootData);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated()
// 	{
// 		Weapon.bIsShooting = false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		LastActiveDeltaTime = DeltaTime;
// 	}
// };
