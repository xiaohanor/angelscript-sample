class UIslandFloatotronAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon); // weapon = attack

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIProjectileLauncherComponent Weapon;
	UBasicAIHealthComponent HealthComp;

	UIslandFloatotronSettings FloatotronSettings;

	float NextFireTime = 0.0;	
	int NumFiredProjectiles = 0;	

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		Weapon = UBasicAIProjectileLauncherComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		
		FloatotronSettings = UIslandFloatotronSettings::GetSettings(Owner);		

		AnimComp.bIsAiming = true;			
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
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
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, FloatotronSettings.AttackMaxRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, FloatotronSettings.AttackMinRange))
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
		if(!GentCostQueueComp.IsNext(this))
			return false;
		if(!GentCostComp.IsTokenAvailable(FloatotronSettings.AttackGentlemanCost))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > FloatotronSettings.AttackDuration && NumFiredProjectiles >= FloatotronSettings.AttackBurstNumber)
			return true;
		
		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		
		
		GentCostComp.ClaimToken(this, FloatotronSettings.AttackGentlemanCost);

		NumFiredProjectiles = 0;
		NextFireTime = Time::GameTimeSeconds;
		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Weapon, 0.0));		
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this);

		Cooldown.Set(FloatotronSettings.AttackCooldown);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(NumFiredProjectiles < FloatotronSettings.AttackBurstNumber && NextFireTime < Time::GameTimeSeconds)
		{
			FireProjectile();			
			NextFireTime += FloatotronSettings.AttackDuration / float(FloatotronSettings.AttackBurstNumber);
			if (NumFiredProjectiles >= FloatotronSettings.AttackBurstNumber)
				NextFireTime += BIG_NUMBER;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void FireProjectile()
	{
		// Launch projectile at predicted location
		NumFiredProjectiles++;
		auto TargetLoc = TargetComp.Target.ActorCenterLocation;
		FVector WeaponLoc = Weapon.WorldLocation;
		FVector AimDir = (TargetLoc - WeaponLoc).GetSafeNormal();

		FRotator Scatter; 
		Scatter.Yaw = Math::RandRange(-FloatotronSettings.AttackScatterYaw, FloatotronSettings.AttackScatterYaw);
		Scatter.Pitch = Math::RandRange(-FloatotronSettings.AttackScatterPitch, FloatotronSettings.AttackScatterPitch);
		AimDir = Scatter.RotateVector(AimDir);

		UBasicAIProjectileComponent Projectile = Weapon.Launch(AimDir * FloatotronSettings.AttackProjectileSpeed);
		
		UBasicAIHomingProjectileComponent HomingComp = UBasicAIHomingProjectileComponent::Get(Projectile.Owner);
		if (HomingComp != nullptr)
			HomingComp.Target = TargetComp.Target;
		
		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Weapon, NumFiredProjectiles, FloatotronSettings.AttackBurstNumber));
	}
	
} 