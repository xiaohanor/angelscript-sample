class UIslandRedBlueBurstShootBulletCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(IslandRedBlueWeapon::IslandRedBlueWeapon);
	default CapabilityTags.Add(IslandRedBlueWeapon::IslandRedBlueEquipped);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UIslandRedBlueWeaponUserComponent WeaponUserComponent;
	UHazeActorLocalSpawnPoolComponent BulletSpawnPool;
	UPlayerTargetablesComponent PlayerTargetableComp;
	UPlayerAimingComponent AimComponent;
	UIslandSidescrollerComponent SidescrollerComp;
	UIslandRedBlueWeaponSettings Settings;
	UIslandRedBlueBurstSettings BurstSettings;
	EIslandRedBlueWeaponHandType HandType;
	AIslandRedBlueWeapon Weapon;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SidescrollerComp = UIslandSidescrollerComponent::Get(Player);
		WeaponUserComponent = UIslandRedBlueWeaponUserComponent::Get(Player);
		PlayerTargetableComp = UPlayerTargetablesComponent::Get(Player);
		AimComponent = UPlayerAimingComponent::Get(Player);
		Settings = UIslandRedBlueWeaponSettings::GetSettings(Player);
		BurstSettings = UIslandRedBlueBurstSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(WeaponUserComponent.CurrentUpgradeType != EIslandRedBlueWeaponUpgradeType::Burst)
			return false;

		if(!WeaponUserComponent.WantsToFireWeapon())
			return false;

		if(!WeaponUserComponent.HasEquippedWeapons())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(WeaponUserComponent.CurrentUpgradeType != EIslandRedBlueWeaponUpgradeType::Burst)
			return true;

		if(!WeaponUserComponent.WantsToFireWeapon())
			return true;

		if(!WeaponUserComponent.HasEquippedWeapons())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		WeaponUserComponent.WeaponAnimData.bShotThisTickLeft = false;
		WeaponUserComponent.WeaponAnimData.bShotThisTickRight = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		WeaponUserComponent.WeaponAnimData.bShotThisTickLeft = false;
		WeaponUserComponent.WeaponAnimData.bShotThisTickRight = false;

		if(WeaponUserComponent.NextShootDelayTimeLeft > 0.0)
			return;

		// If hand is blocked, try to switch hand
		if(WeaponUserComponent.IsHandBlocked(HandType))
		{
			SwitchHand();
			// If that hand is blocked we can't shoot!
			if(WeaponUserComponent.IsHandBlocked(HandType))
				return;
		}

		BulletSpawnPool = HazeActorLocalSpawnPoolStatics::GetOrCreateSpawnPool(WeaponUserComponent.GetRelevantBulletClass(), Player);

		if(WeaponUserComponent.TimeOfStartShooting < 0.0)
			WeaponUserComponent.TimeOfStartShooting = Time::GetGameTimeSeconds();

		UIslandRedBlueTargetableComponent Targetable;
		if(AimComponent.IsAiming(WeaponUserComponent) && AimComponent.IsUsingAutoAim(WeaponUserComponent))
		{
			Targetable = Cast<UIslandRedBlueTargetableComponent>(PlayerTargetableComp.GetPrimaryTarget(
				UIslandRedBlueTargetableComponent));
		}

		while(WeaponUserComponent.NextShootDelayTimeLeft <= 0.0)
		{
			Weapon = WeaponUserComponent.GetWeapon(HandType);
			float TimeSinceShouldHaveShot = Math::Abs(WeaponUserComponent.NextShootDelayTimeLeft);
			float CurrentCooldown = GetCurrentCooldownBetweenBullets(TimeSinceShouldHaveShot);
			WeaponUserComponent.NextShootDelayTimeLeft += CurrentCooldown;
			ShootBullet(Targetable, TimeSinceShouldHaveShot);

			WeaponUserComponent.LastWeaponFired = HandType;
			if(!IsOtherHandBlocked())
				SwitchHand();
		}
		
		// We want to switch to blocked hand, so we fire from that hand next time if it isn't blocked anymore
		if(IsOtherHandBlocked())
			SwitchHand();
	}

	void ShootBullet(UIslandRedBlueTargetableComponent Targetable, float TimeSinceShouldHaveShot)
	{
		if(HandType == EIslandRedBlueWeaponHandType::Left)
			WeaponUserComponent.WeaponAnimData.bShotThisTickLeft = true;
		else if(HandType == EIslandRedBlueWeaponHandType::Right)
			WeaponUserComponent.WeaponAnimData.bShotThisTickRight = true;

		FVector MuzzlePosition = Weapon.Muzzle.WorldLocation;

		FHitResult HitResult;
		FVector BulletTarget = WeaponUserComponent.GetBulletTargetLocation(HitResult);

		FVector Forward = (BulletTarget - MuzzlePosition).GetSafeNormal();

		FHazeActorSpawnParameters SpawnParams(this);
		SpawnParams.Location = MuzzlePosition;
		SpawnParams.Rotation = FRotator::MakeFromXZ(Forward, FVector::UpVector);
		auto Bullet = Cast<AIslandRedBlueWeaponBullet>(BulletSpawnPool.Spawn(SpawnParams));

		FIslandRedBlueWeaponBulletParams BulletParams;
		BulletParams.WeaponHand = HandType;
		BulletParams.TraceChannel = Settings.TraceChannel;
		BulletParams.BulletInitialSpeed = BurstSettings.BulletInitialSpeed;
		BulletParams.BulletSpeedAcceleration = BurstSettings.BulletSpeedAcceleration;
		BulletParams.BulletSpeedMax = BurstSettings.BulletSpeedMax;
		BulletParams.BulletDamageMultiplier = BurstSettings.BulletDamageMultiplier;
		
		FName ShoulderSocketName = HandType == EIslandRedBlueWeaponHandType::Left ? n"LeftArm" : n"RightArm";
		devCheck(Player.Mesh.DoesSocketExist(ShoulderSocketName), f"Tried to get socket {ShoulderSocketName}, but socket does not exist");
		Bullet.Initialize(HitResult, Player.Mesh.GetSocketLocation(ShoulderSocketName), Forward, Targetable, BulletParams, Weapon.WeaponType, BulletSpawnPool, Player, TimeSinceShouldHaveShot);

		FIslandRedBlueWeaponOnShootParams OnShootParams;
		OnShootParams.Bullet = Bullet;
		OnShootParams.ShootDirection = Forward;
		OnShootParams.MuzzleLocation = MuzzlePosition;
		OnShootParams.WeaponType = Weapon.WeaponType;
		UIslandRedBlueWeaponEffectHandler::Trigger_OnShootBullet(Weapon, OnShootParams);
	}

	void SwitchHand()
	{
		HandType = GetOtherHand(HandType);
	}

	EIslandRedBlueWeaponHandType GetOtherHand(EIslandRedBlueWeaponHandType Hand)
	{
		return Hand == EIslandRedBlueWeaponHandType::Left ? EIslandRedBlueWeaponHandType::Right : EIslandRedBlueWeaponHandType::Left;
	}

	bool IsOtherHandBlocked()
	{
		EIslandRedBlueWeaponHandType OtherHand = GetOtherHand(HandType);
		return WeaponUserComponent.IsHandBlocked(OtherHand);
	}

	float GetCurrentCooldownBetweenBullets(float TimeSinceShouldHaveShot) const
	{
		const float TimeSinceStartShooting = Time::GetGameTimeSince(WeaponUserComponent.TimeOfStartShooting) - TimeSinceShouldHaveShot;
		const float CurveAlpha = Math::Clamp(TimeSinceStartShooting / BurstSettings.CoolDownBetweenBulletsCurveDuration, 0.0, 1.0);
		const float CurveValue = BurstSettings.CoolDownBetweenBulletsCurve.GetFloatValue(CurveAlpha);
		return Math::Lerp(BurstSettings.StartCoolDownBetweenBullets, BurstSettings.TargetCoolDownBetweenBullets, CurveValue);
	}
}