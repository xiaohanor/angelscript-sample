class UIslandJetpackShieldotronMoonAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Focus);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Movement);

	default CapabilityTags.Add(BasicAITags::Attack);

	UGentlemanCostComponent GentCostComp;
	UBasicAIProjectileLauncherComponent Weapon;
	UBasicAIHealthComponent HealthComp;

	UIslandJetpackShieldotronSettings JetpackSettings;

	float NextFireTime = 0.0;	
	int NumFiredProjectiles = 0;

	AAIIslandJetpackShieldotron JetpackShieldotron;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		
		JetpackSettings = UIslandJetpackShieldotronSettings::GetSettings(Owner);		
		JetpackShieldotron = Cast<AAIIslandJetpackShieldotron>(Owner);
		Weapon = JetpackShieldotron.MoonLauncherComp;
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
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, JetpackSettings.MoonAttackMaxRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, JetpackSettings.MoonAttackMinRange))
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
		if(!GentCostComp.IsTokenAvailable(JetpackSettings.MoonAttackGentlemanCost))
			return false;
		// Should have roughly the same altitude
		if ( Math::Abs(Owner.ActorCenterLocation.Z - TargetComp.Target.ActorCenterLocation.Z) > 50)
			return false;
		
		// Only attack when we're facing target
		FVector ToTarget = (TargetComp.Target.ActorCenterLocation - Owner.ActorCenterLocation);
		ToTarget.Z = 0.0;
		if (Owner.ActorForwardVector.DotProduct(ToTarget.GetSafeNormal()) < 0.707) //45 deg
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > JetpackSettings.MoonAttackDuration && NumFiredProjectiles >= JetpackSettings.MoonAttackBurstNumber)
			return true;
		
		return false;
	}

	bool bIsVertical = true;
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		
		
		GentCostComp.ClaimToken(this, JetpackSettings.MoonAttackGentlemanCost);

		NumFiredProjectiles = 0;
		NextFireTime = Time::GameTimeSeconds + Math::RandRange(0.0, 0.25); // TODO: network random time offset
		
		//UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Weapon, ShieldotronSettings.AttackTelegraphDuration));
		AnimComp.bIsAiming = true;
		CurrentFwdAimDir = Owner.ActorForwardVector;
		bIsVertical = !bIsVertical;
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this);

		Cooldown.Set(JetpackSettings.MoonAttackCooldown + Math::RandRange(-0.25, 0.25));
		AnimComp.bIsAiming = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if(NumFiredProjectiles < JetpackSettings.MoonAttackBurstNumber && NextFireTime < Time::GameTimeSeconds)
		{
			if (bIsVertical)
				FireProjectileVertical();
			else
				FireProjectileHorizontal();
			NextFireTime += 0.05; //;JetpackSettings.MoonAttackDuration / float(JetpackSettings.MoonAttackBurstNumber);
			if (NumFiredProjectiles >= JetpackSettings.MoonAttackBurstNumber)
				NextFireTime += BIG_NUMBER;
			AnimComp.RequestFeature(FeatureTagIslandSecurityMech::BullitShot, EBasicBehaviourPriority::Medium, this);
		}
		else
			AnimComp.ClearFeature(this);
	}

	FVector CurrentFwdAimDir;
	UFUNCTION(NotBlueprintCallable)
	private void FireProjectileVertical()
	{
		NumFiredProjectiles++;
		FVector AimDir;
		float Angle = 30.0;
		AimDir = CurrentFwdAimDir.RotateTowards(FVector::UpVector, Angle);
		AimDir = AimDir.RotateTowards(FVector::DownVector, NumFiredProjectiles * Angle * 2.0 / (float(JetpackSettings.MoonAttackBurstNumber)));

		UBasicAIProjectileComponent Projectile = Weapon.Launch(AimDir * JetpackSettings.MoonAttackProjectileSpeed);
		Cast<AIslandShieldotronProjectile>(Projectile.Owner).bIsRotating = true;
		
		UBasicAIHomingProjectileComponent HomingComp = UBasicAIHomingProjectileComponent::Get(Projectile.Owner);
		if (HomingComp != nullptr)
			HomingComp.Target = TargetComp.Target;

		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Weapon, NumFiredProjectiles, JetpackSettings.MoonAttackBurstNumber));
		// TODO: new events
		//UIslandShieldotronPlayerEffectHandler::Trigger_OnLaunchRocketAttack(Game::Zoe, FIslandShieldotronRocketAttackPlayerEventData(Owner, TargetComp.Target));
		//UIslandShieldotronPlayerEffectHandler::Trigger_OnLaunchRocketAttack(Game::Mio, FIslandShieldotronRocketAttackPlayerEventData(Owner, TargetComp.Target));
	}
	
	UFUNCTION(NotBlueprintCallable)
	private void FireProjectileHorizontal()
	{
		NumFiredProjectiles++;
		FVector AimDir;
		float Angle = 30.0;
		AimDir = CurrentFwdAimDir.RotateTowards(FVector::LeftVector, Angle);
		AimDir = AimDir.RotateTowards(FVector::RightVector, NumFiredProjectiles * Angle * 2.0 / (float(JetpackSettings.MoonAttackBurstNumber)));

		UBasicAIProjectileComponent Projectile = Weapon.Launch(AimDir * JetpackSettings.MoonAttackProjectileSpeed);
		Projectile.Owner.SetActorRotation(FRotator(0,0, 90));
		Cast<AIslandShieldotronProjectile>(Projectile.Owner).bIsRotating = true;

		UBasicAIHomingProjectileComponent HomingComp = UBasicAIHomingProjectileComponent::Get(Projectile.Owner);
		if (HomingComp != nullptr)
			HomingComp.Target = TargetComp.Target;

		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Weapon, NumFiredProjectiles, JetpackSettings.MoonAttackBurstNumber));
		// TODO: new events
		//UIslandShieldotronPlayerEffectHandler::Trigger_OnLaunchRocketAttack(Game::Zoe, FIslandShieldotronRocketAttackPlayerEventData(Owner, TargetComp.Target));
		//UIslandShieldotronPlayerEffectHandler::Trigger_OnLaunchRocketAttack(Game::Mio, FIslandShieldotronRocketAttackPlayerEventData(Owner, TargetComp.Target));
	}
	

} 