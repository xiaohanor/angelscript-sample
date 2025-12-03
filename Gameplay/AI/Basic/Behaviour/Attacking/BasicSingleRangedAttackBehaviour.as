
class UBasicSingleRangedAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UBasicAIProjectileLauncherComponent Weapon;
	float EndTime;

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
		if (!TargetComp.HasValidTarget())
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
		FVector TargetLoc = TargetComp.Target.ActorCenterLocation;	
		float PredictionTime = WeaponLoc.Distance(TargetLoc) / Math::Max(100.0, Weapon.LaunchSpeed);
		FVector PredictedTargetLoc = TargetLoc + TargetComp.Target.ActorVelocity * PredictionTime;
		FVector AimDir = (PredictedTargetLoc - WeaponLoc).GetSafeNormal();

		// Introduce scatter
		// TODO: This needs networking!
		FRotator Scatter; 
		Scatter.Yaw = Math::RandRange(-BasicSettings.RangedAttackScatterYaw, BasicSettings.RangedAttackScatterYaw);
		Scatter.Pitch = Math::RandRange(-BasicSettings.RangedAttackScatterPitch, BasicSettings.RangedAttackScatterPitch);
		AimDir = Scatter.RotateVector(AimDir);

		UBasicAIProjectileComponent Projectile = Weapon.Launch(AimDir * Weapon.LaunchSpeed);
		
		UBasicAIHomingProjectileComponent HomingComp = UBasicAIHomingProjectileComponent::Get(Projectile.Owner);
		if (HomingComp != nullptr)
			HomingComp.Target = TargetComp.Target;

		UBasicAIAnimationFeatureAdditiveShooting ShootingFeature = Cast<UBasicAIAnimationFeatureAdditiveShooting>(AnimComp.GetFeatureByClass(UBasicAIAnimationFeatureAdditiveShooting));
		if ((ShootingFeature != nullptr) && (ShootingFeature.SingleShot != nullptr))
			Owner.PlayAdditiveAnimation(FHazeAnimationDelegate(), ShootingFeature.SingleShot);
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