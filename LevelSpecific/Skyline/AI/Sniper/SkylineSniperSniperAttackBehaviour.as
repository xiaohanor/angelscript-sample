class USkylineSniperSniperAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UBasicAIProjectileLauncherComponent Weapon;
	float EndTime;

	USkylineSniperAimingComponent AimingComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
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

		AimingComp = USkylineSniperAimingComponent::Get(Owner);

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
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, BasicSettings.AttackRange))
			return false;
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

		UBasicAIProjectileComponent Projectile = Weapon.Launch(AimDir * Weapon.LaunchSpeed);

		UBasicAIAnimationFeatureAdditiveShooting ShootingFeature = Cast<UBasicAIAnimationFeatureAdditiveShooting>(AnimComp.GetFeatureByClass(UBasicAIAnimationFeatureAdditiveShooting));
		if ((ShootingFeature != nullptr) && (ShootingFeature.SingleShot != nullptr))
			Owner.PlayAdditiveAnimation(FHazeAnimationDelegate(), ShootingFeature.SingleShot);

		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Weapon, 1, 1));
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