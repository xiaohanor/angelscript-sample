class UIslandJetpackShieldotronLemonVerticalAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Focus);

	default CapabilityTags.Add(BasicAITags::Attack);

	UGentlemanCostComponent GentCostComp;
	UBasicAIProjectileLauncherComponent Weapon;
	UBasicAIHealthComponent HealthComp;
	UIslandJetpackShieldotronAttackComponent AttackComp;
	UIslandJetpackShieldotronAimComponent AimComp;

	UIslandJetpackShieldotronSettings JetpackSettings;

	float NextFireTime = 0.0;	
	int NumFiredProjectiles = 0;

	FVector InitialTargetLoc;
	FVector CurrentAimCenterDir;
	AAIIslandJetpackShieldotron JetpackShieldotron;

	const EIslandJetpackShieldotronAttack LemonVerticalAttack = EIslandJetpackShieldotronAttack::LemonVertical;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AttackComp = UIslandJetpackShieldotronAttackComponent::Get(Owner);
		AimComp = UIslandJetpackShieldotronAimComponent::Get(Owner);
		
		JetpackSettings = UIslandJetpackShieldotronSettings::GetSettings(Owner);		
		JetpackShieldotron = Cast<AAIIslandJetpackShieldotron>(Owner);
		Weapon = JetpackShieldotron.LemonLauncherComp;
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
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, JetpackSettings.LemonAttackMaxRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, JetpackSettings.LemonAttackMinRange))
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;		
		if (!AttackComp.CanAttack(LemonVerticalAttack))
			return false;
		if (!WantsToAttack())
			return false;
		if(!GentCostComp.IsTokenAvailable(JetpackSettings.LemonAttackGentlemanCost))
			return false;
		
		// Only attack when we're facing target
		FVector ToTarget = (TargetComp.Target.ActorCenterLocation - Owner.ActorCenterLocation).GetSafeNormal2D();
		if (Owner.ActorForwardVector.DotProduct(ToTarget) < 0.866) // 30 deg
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > JetpackSettings.LemonAttackDuration && NumFiredProjectiles >= JetpackSettings.LemonAttackBurstNumber)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		
		
		GentCostComp.ClaimToken(this, JetpackSettings.LemonAttackGentlemanCost);

		NumFiredProjectiles = 0;
		const float InitialDelay = 0.5;
		NextFireTime = Time::GameTimeSeconds + InitialDelay + Math::RandRange(0.0, 0.25); // Not necessary to network this small random time offset. Spawns locally.
		
		//UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Weapon, ShieldotronSettings.AttackTelegraphDuration));
		AnimComp.bIsAiming = true;
		InitialTargetLoc = TargetComp.Target.ActorCenterLocation;
		CurrentAimCenterDir = (InitialTargetLoc - Weapon.WorldLocation).GetSafeNormal(ResultIfZero = Owner.ActorForwardVector);

		FVector AimDir = CalculateAimDir();
		UpdateAnimationAimSpace(AimDir);
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this);

		Cooldown.Set(JetpackSettings.LemonAttackCooldown + Math::RandRange(-0.25, 0.25));
		AnimComp.bIsAiming = false;
		AimComp.DesiredPitch = 0.0;
		AimComp.DesiredYaw = 0.0;

		AttackComp.NextAttackAfter(LemonVerticalAttack);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if(NumFiredProjectiles < JetpackSettings.LemonAttackBurstNumber && NextFireTime < Time::GameTimeSeconds)
		{
			FireProjectileVertical();
			NextFireTime += 0.05; // fire interval
			if (NumFiredProjectiles >= JetpackSettings.LemonAttackBurstNumber)
				NextFireTime += BIG_NUMBER;
			//AnimComp.RequestFeature(FeatureTagIslandSecurityMech::BullitShot, EBasicBehaviourPriority::Medium, this);
		}
		else
			AnimComp.ClearFeature(this);
		
		if (NumFiredProjectiles >= JetpackSettings.LemonAttackBurstNumber)
		{
			AimComp.DesiredPitch = 0.0;
			AimComp.DesiredYaw = 0.0;
		}

		// Keep facing initial aim dir.
		DestinationComp.RotateTowards(Owner.ActorCenterLocation + CurrentAimCenterDir);
	}
	
	UFUNCTION(NotBlueprintCallable)
	private void FireProjectileVertical()
	{
		CurrentAimCenterDir = (InitialTargetLoc - Weapon.WorldLocation).GetSafeNormal(ResultIfZero = Owner.ActorForwardVector);
		NumFiredProjectiles++;
		FVector AimDir = CalculateAimDir();
		UpdateAnimationAimSpace(AimDir);
		
		UBasicAIProjectileComponent Projectile = Weapon.Launch(AimDir * JetpackSettings.LemonAttackProjectileSpeed);
		Projectile.Damage = JetpackSettings.LemonAttackDamage;

		UBasicAIHomingProjectileComponent HomingComp = UBasicAIHomingProjectileComponent::Get(Projectile.Owner);
		if (HomingComp != nullptr)
			HomingComp.Target = TargetComp.Target;

		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Weapon, NumFiredProjectiles, JetpackSettings.LemonAttackBurstNumber));
		// TODO: new events
		//UIslandShieldotronPlayerEffectHandler::Trigger_OnLaunchRocketAttack(Game::Zoe, FIslandShieldotronRocketAttackPlayerEventData(Owner, TargetComp.Target));
		//UIslandShieldotronPlayerEffectHandler::Trigger_OnLaunchRocketAttack(Game::Mio, FIslandShieldotronRocketAttackPlayerEventData(Owner, TargetComp.Target));
	}

	FVector CalculateAimDir()
	{
		FVector AimDir;
		float SpreadAngle = 30.0;
		AimDir = CurrentAimCenterDir.RotateTowards(FVector::UpVector, SpreadAngle);
		AimDir = AimDir.RotateTowards(FVector::DownVector, NumFiredProjectiles * SpreadAngle * 2.0 / (float(JetpackSettings.LemonAttackBurstNumber)));
		return AimDir;
	}

	void UpdateAnimationAimSpace(FVector AimDir)
	{
		// Project AimDir onto Forward/Up-plane and set aim pitch
		FVector AimDirProj = AimDir.VectorPlaneProject(Owner.ActorRightVector).GetSafeNormal();
		float PitchSign = AimDirProj.DotProduct(Owner.ActorUpVector) > 0 ? 1.0 : -1.0;  // Up is positive, down is negative
		float AimPitchAngle = Math::DotToDegrees(AimDirProj.DotProduct(Owner.ActorForwardVector));
		AimComp.DesiredPitch = PitchSign * AimPitchAngle;
		AimComp.DesiredYaw = 0.0;
	}

} 