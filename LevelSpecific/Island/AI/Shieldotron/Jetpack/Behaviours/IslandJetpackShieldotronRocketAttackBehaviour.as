class UIslandJetpackShieldotronRocketAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	default CapabilityTags.Add(BasicAITags::Attack);

	UGentlemanCostComponent GentCostComp;
	UBasicAIProjectileLauncherComponent Weapon;
	UBasicAIHealthComponent HealthComp;
	UIslandJetpackShieldotronAttackComponent AttackComp;
	UIslandJetpackShieldotronAimComponent AimComp;

	UIslandShieldotronSettings ShieldotronSettings;
	UIslandJetpackShieldotronSettings JetpackSettings;

	float NextFireTime = 0.0;	
	int NumFiredProjectiles = 0;

	const EIslandJetpackShieldotronAttack RocketAttack = EIslandJetpackShieldotronAttack::OrbAttack;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		Weapon = UBasicAIProjectileLauncherComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AttackComp = UIslandJetpackShieldotronAttackComponent::Get(Owner);
		AimComp = UIslandJetpackShieldotronAimComponent::Get(Owner);
		
		ShieldotronSettings = UIslandShieldotronSettings::GetSettings(Owner);		
		JetpackSettings = UIslandJetpackShieldotronSettings::GetSettings(Owner);		
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;		
		if (!TargetComp.HasValidTarget())
			return false;
		if (!TargetComp.HasGeometryVisibleTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, JetpackSettings.RocketAttackMaxRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, JetpackSettings.RocketAttackMinRange))
			return false;
				
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!ShieldotronSettings.bHasRocketAttack)
			return false;
		if (!AttackComp.CanAttack(RocketAttack))
			return false;
		if (!WantsToAttack())
			return false;
		if(!GentCostComp.IsTokenAvailable(ShieldotronSettings.AttackGentlemanCost))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > ShieldotronSettings.AttackDuration + ShieldotronSettings.AttackTelegraphDuration && NumFiredProjectiles >= JetpackSettings.RocketAttackBurstNumber)
			return true;
		
		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		
		
		GentCostComp.ClaimToken(this, ShieldotronSettings.AttackGentlemanCost);

		NumFiredProjectiles = 0;
		NextFireTime = Time::GameTimeSeconds + ShieldotronSettings.AttackTelegraphDuration + Math::RandRange(0.0, 0.25); // TODO: network random time offset

		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Weapon, ShieldotronSettings.AttackTelegraphDuration));
		AnimComp.bIsAiming = true;
		AnimComp.RequestFeature(FeatureTagIslandSecurityMech::AimingRocket, EBasicBehaviourPriority::Medium, this);
		AimComp.bClearDefaultAimOnDeactivated = true;
		Owner.BlockCapabilities(n"DefaultAim", this);
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this);

		Cooldown.Set(ShieldotronSettings.AttackCooldown + Math::RandRange(-0.25, 0.25));
		AnimComp.bIsAiming = false;
		AnimComp.ClearFeature(this);

		AttackComp.NextAttackAfter(RocketAttack);
		AimComp.bClearDefaultAimOnDeactivated = false;
		Owner.UnblockCapabilities(n"DefaultAim", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < ShieldotronSettings.AttackTelegraphDuration)
			return;

		if(NumFiredProjectiles < JetpackSettings.RocketAttackBurstNumber && NextFireTime < Time::GameTimeSeconds)
		{
			FireProjectile();			
			NextFireTime += ShieldotronSettings.AttackDuration / float(JetpackSettings.RocketAttackBurstNumber);
			if (NumFiredProjectiles >= JetpackSettings.RocketAttackBurstNumber)
				NextFireTime += BIG_NUMBER;
			AnimComp.RequestFeature(FeatureTagIslandSecurityMech::RocketShot, EBasicBehaviourPriority::Medium, this);
		}
		else
			AnimComp.RequestFeature(FeatureTagIslandSecurityMech::AimingRocket, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(NotBlueprintCallable)
	private void FireProjectile()
	{
		// Launch projectile at predicted location
		NumFiredProjectiles++;
		auto TargetLoc = TargetComp.Target.ActorCenterLocation;
		FVector WeaponLoc = Weapon.WorldLocation;		
		FVector AimDir = Weapon.UpVector; //(TargetLoc - WeaponLoc).GetSafeNormal();

		UBasicAIProjectileComponent Projectile = Weapon.Launch(AimDir * ShieldotronSettings.AttackProjectileSpeed);
		
		UIslandShieldotronHomingProjectileComponent HomingComp = UIslandShieldotronHomingProjectileComponent::Get(Projectile.Owner);
		if (HomingComp != nullptr)
		{
			HomingComp.Target = TargetComp.Target;
			HomingComp.bUseJetpackFriendlyHoming = true;
		}

		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Weapon, NumFiredProjectiles, JetpackSettings.RocketAttackBurstNumber));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnLaunchRocketAttack(Game::Zoe, FIslandShieldotronRocketAttackPlayerEventData(Owner, TargetComp.Target));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnLaunchRocketAttack(Game::Mio, FIslandShieldotronRocketAttackPlayerEventData(Owner, TargetComp.Target));
	}
	
} 