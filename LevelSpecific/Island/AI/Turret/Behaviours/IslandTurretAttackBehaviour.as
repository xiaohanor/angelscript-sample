class UIslandTurretAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIProjectileLauncherComponent Weapon;
	UBasicAIHealthComponent HealthComp;
	float EndTime;

	UIslandTurretSettings TurretSettings;

	
	float FiredTime = 0.0;
	float PrimeTime = 0.0;
	int FiredProjectiles = 0;
	int ExpiredProjectiles = 0;
	FVector TargetLoc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		Weapon = UBasicAIProjectileLauncherComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
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

		TurretSettings = UIslandTurretSettings::GetSettings(Owner);		

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
	void PreTick(float DeltaTime)
	{
		if (Weapon == nullptr) 
			return;

		if (!IsActive() && HealthComp.IsAlive() && WantsToAttack() && !IsBlocked())
			GentCostQueueComp.JoinQueue(this);
		else
			GentCostQueueComp.LeaveQueue(this);
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (Weapon == nullptr)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, BasicSettings.AttackRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, TurretSettings.MinimumAttackRange))
			return false;
		if (BasicSettings.RangedAttackRequireVisibility && !TargetComp.HasVisibleTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!WantsToAttack())
			return false;
		if(!GentCostQueueComp.IsNext(this) && (TurretSettings.GentlemanCost != EGentlemanCost::None))
			return false;
		if(!GentCostComp.IsTokenAvailable(TurretSettings.GentlemanCost))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		

		FiredProjectiles = 0;
		ExpiredProjectiles = 0;
		
		UBasicAIAnimationFeatureAdditiveShooting ShootingFeature = Cast<UBasicAIAnimationFeatureAdditiveShooting>(AnimComp.GetFeatureByClass(UBasicAIAnimationFeatureAdditiveShooting));
		if ((ShootingFeature != nullptr) && (ShootingFeature.SingleShot != nullptr))
			Owner.PlayAdditiveAnimation(FHazeAnimationDelegate(), ShootingFeature.SingleShot);

		GentCostComp.ClaimToken(this, TurretSettings.GentlemanCost);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this, TurretSettings.AttackTokenCooldown);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < TurretSettings.TelegraphDuration)
			return;

		if(HasControl() && FiredProjectiles < TurretSettings.ProjectileAmount && (FiredTime == 0 || Time::GetGameTimeSince(FiredTime) > TurretSettings.TimeBetweenBurstProjectiles))
		{
			CrumbFireProjectile();
		}
		
		if(FiredProjectiles >= TurretSettings.ProjectileAmount)
		{
			Cooldown.Set(TurretSettings.LaunchInterval - ActiveDuration);
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbFireProjectile()
	{
		TargetLoc = TargetComp.Target.ActorCenterLocation;	
		FVector WeaponLoc = Weapon.WorldLocation;
		FVector AimDir = (TargetLoc - WeaponLoc).GetSafeNormal();
		Weapon.Launch(AimDir * TurretSettings.LaunchSpeed);
		FiredProjectiles++;
		FiredTime = Time::GetGameTimeSeconds();
	}
}

