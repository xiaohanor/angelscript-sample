class UIslandShieldotronOrbAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	default CapabilityTags.Add(BasicAITags::Attack);
	default CapabilityTags.Add(n"RocketAttack"); // Legacy
	default CapabilityTags.Add(n"OrbAttack");

	UGentlemanCostComponent GentCostComp;
	UIslandShieldotronOrbLauncher Weapon;
	UBasicAIHealthComponent HealthComp;

	UIslandShieldotronSettings ShieldotronSettings;

	float NextFireTime = 0.0;	
	int NumBurstProjectiles = 1;
	int NumFiredProjectiles = 0;
	bool bHasTriggeredTelegraph = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		Weapon = UIslandShieldotronOrbLauncher::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		
		ShieldotronSettings = UIslandShieldotronSettings::GetSettings(Owner);
		NumBurstProjectiles = ShieldotronSettings.AttackBurstNumber;	
	}

	bool WantsToAttack() const
	{
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;		
		if (!TargetComp.HasValidTarget())
			return false;
		if (!TargetComp.HasGeometryVisibleTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, ShieldotronSettings.AttackMaxRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, ShieldotronSettings.AttackMinRange))
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!ShieldotronSettings.bHasRocketAttack)
			return false;
		if (!WantsToAttack())
			return false;
		if(!GentCostComp.IsTokenAvailable(ShieldotronSettings.AttackGentlemanCost))
			return false;
		if (Owner.IsAnyCapabilityActive(n"TraversalChase"))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > ShieldotronSettings.AttackDuration + ShieldotronSettings.AttackTelegraphDuration && NumFiredProjectiles >= NumBurstProjectiles)
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
		Owner.BlockCapabilities(n"MeleeAttack", this);
		//NumBurstProjectiles = (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, ShieldotronSettings.MortarAttackMinRange)) ? ShieldotronSettings.AttackCloseRangeBurstNumber : ShieldotronSettings.AttackBurstNumber;
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this);

		Owner.UnblockCapabilities(n"CloseRangeAttack", this);
		Owner.UnblockCapabilities(n"MeleeAttack", this);

		Cooldown.Set(ShieldotronSettings.AttackCooldown + Math::RandRange(ShieldotronSettings.AttackCooldownRandRangeMin, ShieldotronSettings.AttackCooldownRandRangeMax));
		AnimComp.bIsAiming = false;
		bHasTriggeredTelegraph = false;
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
		if (ActiveDuration < ShieldotronSettings.AttackTelegraphDuration)
			return;

		if(NumFiredProjectiles < NumBurstProjectiles && NextFireTime < Time::GameTimeSeconds)
		{
			FireProjectile();			
			NextFireTime += ShieldotronSettings.AttackDuration / float(NumBurstProjectiles);
			if (NumFiredProjectiles >= NumBurstProjectiles)
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
		FVector AimDir = Weapon.UpVector;
		FVector LaunchVelocity = AimDir * ShieldotronSettings.AttackProjectileLaunchSpeed;
		LaunchVelocity += Owner.ActorVelocity;
		UBasicAIProjectileComponent Projectile = Weapon.Launch(LaunchVelocity);
		
		UBasicAIHomingProjectileComponent HomingComp = UBasicAIHomingProjectileComponent::Get(Projectile.Owner);
		HomingComp.Target = TargetComp.Target;
		Cast<AIslandShieldotronOrbProjectile>(Projectile.Owner).Target = TargetComp.Target;
		Cast<AIslandShieldotronOrbProjectile>(Projectile.Owner).ExpirationTime = ShieldotronSettings.OrbProjectileExpirationTime;
		Cast<AIslandShieldotronOrbProjectile>(Projectile.Owner).MaxPlanarHomingSpeed = ShieldotronSettings.OrbProjectileMaxPlanarHomingSpeed;

		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Weapon, NumFiredProjectiles, NumBurstProjectiles));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnLaunchOrbAttack(Game::Zoe, FIslandShieldotronOrbAttackPlayerEventData(Owner, TargetComp.Target));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnLaunchOrbAttack(Game::Mio, FIslandShieldotronOrbAttackPlayerEventData(Owner, TargetComp.Target));
	}
	
} 