class USkylineSniperTurretAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UBasicAIProjectileLauncherComponent Weapon;
	float EndTime;

	USkylineSniperTurretAimingComponent AimingComp;
	USkylineSniperTurretSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USkylineSniperTurretSettings::GetSettings(Owner);
		
		Weapon = UBasicAIProjectileLauncherComponent::Get(Owner);
		if (Weapon == nullptr)
		{
			UBasicAIWeaponWielderComponent WielderComp = UBasicAIWeaponWielderComponent::Get(Owner);
			if (WielderComp != nullptr) 
			{
				if (WielderComp.Weapon != nullptr)
					Weapon = UBasicAIProjectileLauncherComponent::Get(WielderComp.Weapon);
				WielderComp.OnWieldWeapon.AddUFunction(this, n"OnWieldWeapon");
			}
		}

		AimingComp = USkylineSniperTurretAimingComponent::Get(Owner);

		AnimComp.bIsAiming = true;
	}

	UFUNCTION()
	private void OnWieldWeapon(ABasicAIWeapon WieldedWeapon)
	{
		if (WieldedWeapon == nullptr)
			return;
		UBasicAIProjectileLauncherComponent NewWeapon = UBasicAIProjectileLauncherComponent::Get(WieldedWeapon);
		if (NewWeapon != nullptr)
		{
			Weapon = NewWeapon;
			Weapon.SetWielder(Owner);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (Weapon == nullptr)
			return false;
		if (TargetComp.Target == nullptr)
			return false;
		// if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.AttackRange))
		// 	return false;
		if (BasicSettings.RangedAttackRequireVisibility && !TargetComp.HasVisibleTarget())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		// Launch projectile at predicted location
		FVector WeaponLoc = Weapon.WorldLocation;
		FVector TargetLoc = AimingComp.EndWorldPosition;
		FVector AimDir = (TargetLoc - WeaponLoc).GetSafeNormal();

		float DistanceMultiplier = 2 - Math::Clamp(TargetComp.Target.GetDistanceTo(Owner) / Settings.ProjectileLaunchSpeedMultiplierDistance, 0.25, 1);
		UBasicAIProjectileComponent Projectile = Weapon.Launch(AimDir * Settings.ProjectileLaunchSpeed * DistanceMultiplier);
		Projectile.Damage = 1.0;

		UBasicAIAnimationFeatureAdditiveShooting ShootingFeature = Cast<UBasicAIAnimationFeatureAdditiveShooting>(AnimComp.GetFeatureByClass(UBasicAIAnimationFeatureAdditiveShooting));
		if ((ShootingFeature != nullptr) && (ShootingFeature.SingleShot != nullptr))
			Owner.PlayAdditiveAnimation(FHazeAnimationDelegate(), ShootingFeature.SingleShot);

		USkylineSniperTurretAimingEffectHandler::Trigger_OnShotFired(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > Weapon.LaunchInterval * 0.5)
		{
			Cooldown.Set(Weapon.LaunchInterval - ActiveDuration);
		}
	}
}