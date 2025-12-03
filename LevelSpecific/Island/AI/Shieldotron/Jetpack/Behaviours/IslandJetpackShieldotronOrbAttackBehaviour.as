class UIslandJetpackShieldotronOrbAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	default CapabilityTags.Add(BasicAITags::Attack);
	default CapabilityTags.Add(n"RocketAttack"); // Legacy
	default CapabilityTags.Add(n"OrbAttack");

	UGentlemanCostComponent GentCostComp;
	UIslandShieldotronOrbLauncher Weapon;
	UBasicAIHealthComponent HealthComp;
	UIslandJetpackShieldotronAttackComponent AttackComp;

	UIslandShieldotronSettings ShieldotronSettings;
	UIslandJetpackShieldotronSettings JetpackSettings;

	const EIslandJetpackShieldotronAttack RocketAttack = EIslandJetpackShieldotronAttack::OrbAttack;

	float NextFireTime = 0.0;	
	int NumFiredProjectiles = 0;
	bool bHasTriggeredTelegraph = false;
	bool bHasPrimed = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		Weapon = UIslandShieldotronOrbLauncher::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AttackComp = UIslandJetpackShieldotronAttackComponent::Get(Owner);
		
		ShieldotronSettings = UIslandShieldotronSettings::GetSettings(Owner);
		JetpackSettings = UIslandJetpackShieldotronSettings::GetSettings(Owner);
	}

	bool WantsToAttack() const
	{
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;		
		if (!TargetComp.HasValidTarget())
			return false;
		if (!TargetComp.HasGeometryVisibleTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, JetpackSettings.OrbAttackMaxRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, JetpackSettings.OrbAttackMinRange))
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
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
		if (ActiveDuration > ShieldotronSettings.AttackDuration + ShieldotronSettings.AttackTelegraphDuration && NumFiredProjectiles >= JetpackSettings.OrbAttackBurstNumber)
			return true;
		
		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		
		
		GentCostComp.ClaimToken(this, ShieldotronSettings.AttackGentlemanCost);

		NumFiredProjectiles = 0;
		NextFireTime = Time::GameTimeSeconds + ShieldotronSettings.AttackTelegraphDuration + Math::RandRange(0.0, 0.25);
		
		AnimComp.bIsAiming = true;
		
		Owner.BlockCapabilities(n"CloseRangeAttack", this); // Let attack finish before close range attack is executed.
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this);

		Owner.UnblockCapabilities(n"CloseRangeAttack", this); // Let attack finish before close range attack is executed.

		Cooldown.Set(ShieldotronSettings.AttackCooldown + Math::RandRange(ShieldotronSettings.AttackCooldownRandRangeMin, ShieldotronSettings.AttackCooldownRandRangeMax));
		AnimComp.bIsAiming = false;
		bHasTriggeredTelegraph = false;
		bHasPrimed = false;
		
		AttackComp.NextAttackAfter(RocketAttack);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Move away from target until at proper distance or duration is up
		FVector OwnLoc = Owner.ActorLocation;
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		FVector AwayFromTarget = (OwnLoc - TargetLoc).ConstrainToPlane(Owner.ActorUpVector).GetSafeNormal();
		FVector AwayLoc = OwnLoc + AwayFromTarget * (DestinationComp.MinMoveDistance + 80.0);
		
		float EvadeRange = 200;
		if (OwnLoc.IsWithinDist(TargetLoc, EvadeRange))
		{
			DestinationComp.MoveTowards(AwayLoc, ShieldotronSettings.ChaseMoveSpeed);
		}

		if (ActiveDuration > 0.25 && !bHasTriggeredTelegraph)
		{
			UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Weapon, ShieldotronSettings.AttackTelegraphDuration));
			UIslandShieldotronEffectHandler::Trigger_OnOrbAttackTelegraphStart(Owner, FIslandShieldotronOrbAttackTelegraphParams(Weapon, ShieldotronSettings.AttackTelegraphDuration));			
			bHasTriggeredTelegraph = true;
		}
		else if (ActiveDuration > ShieldotronSettings.AttackTelegraphDuration - 0.3 && !bHasPrimed)
		{
			Weapon.Prime();
			bHasPrimed = true;
		}
		if (ActiveDuration < ShieldotronSettings.AttackTelegraphDuration)
			return;

		if(NumFiredProjectiles < JetpackSettings.OrbAttackBurstNumber && NextFireTime < Time::GameTimeSeconds)
		{
			FireProjectile();			
			NextFireTime += ShieldotronSettings.AttackDuration / float(JetpackSettings.OrbAttackBurstNumber);
			if (NumFiredProjectiles >= JetpackSettings.OrbAttackBurstNumber)
				NextFireTime += BIG_NUMBER;
			AnimComp.RequestFeature(FeatureTagIslandSecurityMech::BullitShot, EBasicBehaviourPriority::Medium, this);
		}
		else
			AnimComp.ClearFeature(this);
	}

	UFUNCTION(NotBlueprintCallable)
	private void FireProjectile()
	{
		NumFiredProjectiles++;
		FVector AimDir = Weapon.ForwardVector;
		FVector LaunchVelocity = AimDir * JetpackSettings.OrbProjectileLaunchSpeed;
		LaunchVelocity += Owner.ActorVelocity;
		UBasicAIProjectileComponent Projectile = Weapon.Prime();		
		UBasicAIHomingProjectileComponent HomingComp = UBasicAIHomingProjectileComponent::Get(Projectile.Owner);
		
		AIslandShieldotronOrbProjectile ProjectileActor = Cast<AIslandShieldotronOrbProjectile>(Projectile.Owner);
		HomingComp.Target = TargetComp.Target;
		ProjectileActor.Target = TargetComp.Target;
		ProjectileActor.ExpirationTime = JetpackSettings.OrbProjectileExpirationTime;
		ProjectileActor.ReducedExpirationTime = JetpackSettings.OrbProjectileReducedExpirationTime;
		ProjectileActor.InitialLaunchSpeed = JetpackSettings.OrbProjectileLaunchSpeed;
		ProjectileActor.MaxSpeed = JetpackSettings.OrbProjectileSpeed;
		ProjectileActor.HomingStrength = JetpackSettings.OrbHomingStrength;
		ProjectileActor.ScaleTime = JetpackSettings.OrbScaleTime;
		ProjectileActor.MaxPlanarHomingSpeed = JetpackSettings.OrbProjectileMaxPlanarHomingSpeed;
		
		Weapon.Launch(LaunchVelocity);

		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Weapon, NumFiredProjectiles, JetpackSettings.OrbAttackBurstNumber));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnLaunchOrbAttack(Game::Zoe, FIslandShieldotronOrbAttackPlayerEventData(Owner, TargetComp.Target));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnLaunchOrbAttack(Game::Mio, FIslandShieldotronOrbAttackPlayerEventData(Owner, TargetComp.Target));
	}
	
} 