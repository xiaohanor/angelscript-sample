class USummitStoneBeastCrystalTurretAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UGentlemanCostComponent GentCostComp;
	UBasicAIProjectileLauncherComponent LauncherComp;

	UBasicAIHealthComponent HealthComp;

	USummitStoneBeastCrystalTurretSettings Settings;

	private float FiredTime = 0.0;
	private int FiredProjectiles = 0;
	private float ActivationDelayTime = 1.0;
	private float TargetInvisibleTimer = 0.0;
	private const float TargetInvisibleTimeLimit = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		auto OwnerTurret = Cast<AAISummitStoneBeastCrystalTurret>(Owner);
		LauncherComp = UBasicAIProjectileLauncherComponent::Get(Owner);

		HealthComp = UBasicAIHealthComponent::Get(Owner);

		Settings = USummitStoneBeastCrystalTurretSettings::GetSettings(Owner);

		AnimComp.bIsAiming = true;
	}
	
	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;		
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.MaxAttackRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.MinAttackRange))
			return false;
		if (BasicSettings.RangedAttackRequireVisibility && !TargetComp.HasGeometryVisibleTarget())
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
		if(!GentCostComp.IsTokenAvailable(Settings.GentlemanCost))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if (TargetInvisibleTimer > TargetInvisibleTimeLimit)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		

		FiredProjectiles = 0;

		UBasicAIAnimationFeatureAdditiveShooting ShootingFeature = Cast<UBasicAIAnimationFeatureAdditiveShooting>(AnimComp.GetFeatureByClass(UBasicAIAnimationFeatureAdditiveShooting));
		if ((ShootingFeature != nullptr) && (ShootingFeature.SingleShot != nullptr))
			Owner.PlayAdditiveAnimation(FHazeAnimationDelegate(), ShootingFeature.SingleShot);

		GentCostComp.ClaimToken(this, Settings.GentlemanCost);
		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(LauncherComp, Settings.TelegraphDuration));
		USummitStoneBeastCrystalTurretEffectHandler::Trigger_OnStartTelegraphing(Owner, FSummitStoneBeastCrystalTurretTelegraphingParams(LauncherComp.WorldLocation, Owner.ActorLocation));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this, Settings.AttackTokenCooldown);
		bHasStartedTelegraphing = false;
		bHasStoppedTelegraphing = false;
		bHasStartedLaunchTelegraphing = false;
		TargetInvisibleTimer = 0.0;
		USummitStoneBeastCrystalTurretEffectHandler::Trigger_OnStopTelegraphing(Owner);
	}

	bool bHasStartedTelegraphing = false;
	bool bHasStoppedTelegraphing = false;
	bool bHasStartedLaunchTelegraphing = false;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Fire and draft version of kickback
		if(HasControl() && FiredProjectiles < Settings.ProjectileAmount && (FiredTime == 0 || Time::GetGameTimeSince(FiredTime) > Settings.TimeBetweenBurstProjectiles))
		{
			CrumbFireProjectile();
		}
		else if (FiredProjectiles == Settings.ProjectileAmount)
		{
			// Reset positions after burst has finished
			Cooldown.Set(Settings.LaunchInterval - ActiveDuration);
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbFireProjectile()
	{		
		// Aim forward
		FVector AimDir = LauncherComp.ForwardVector;

		UBasicAIProjectileComponent ProjectileComp = LauncherComp.Launch(AimDir * Settings.LaunchSpeed);

		FiredProjectiles++;
		FiredTime = Time::GetGameTimeSeconds();

		//UIslandBeamTurretronProjectileEventHandler::Trigger_OnLaunch(ProjectileComp.HazeOwner);
		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(LauncherComp, FiredProjectiles, Settings.ProjectileAmount));		
	}
}

