class UIslandShieldotronSidescrollerMortarAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	default CapabilityTags.Add(BasicAITags::Attack);

	UGentlemanCostComponent GentCostComp;	
	UIslandShieldotronMortarLauncherLeft MortarLauncherLeftComp;
	UIslandShieldotronMortarLauncherRight MortarLauncherRightComp;
	UBasicAIHealthComponent HealthComp;

	UIslandShieldotronSettings Settings;

	UBasicAIProjectileLauncherComponent NextPrimeLauncher;
	UBasicAIProjectileLauncherComponent NextFireLauncher;

	float NextFireTime = 0.0;	
	float NextPrimeTime = 0.0;	
	int NumPrimedProjectiles = 0;
	int NumFiredProjectiles = 0;
	float FireInterval;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		MortarLauncherLeftComp = UIslandShieldotronMortarLauncherLeft::Get(Owner);
		MortarLauncherRightComp = UIslandShieldotronMortarLauncherRight::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HealthComp.OnDie.AddUFunction(this, n"OnDie");
		Settings = UIslandShieldotronSettings::GetSettings(Owner);		
	}

	UFUNCTION()
	private void OnDie(AHazeActor ActorBeingKilled)
	{
		ExpirePrimedProjectiles();
	}

	bool CanAttack() const
	{
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;		
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.AttackMaxRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.AttackMinRange))
			return false;		
				
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!CanAttack())
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.MortarAttackGentlemanCost))
			return false;


		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.MortarAttackDuration + Settings.MortarAttackTelegraphDuration + 2.0 && NumFiredProjectiles >= Settings.MortarAttackBurstNumber)
			return true;
		
		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		
		
		GentCostComp.ClaimToken(this, Settings.MortarAttackGentlemanCost);

		NumFiredProjectiles = 0;
		NumPrimedProjectiles = 0;
		NextFireTime = Time::GameTimeSeconds + Settings.MortarAttackTelegraphDuration;
		NextPrimeTime = Time::GameTimeSeconds; // now
		FireInterval = Settings.MortarAttackDuration / float(Settings.MortarAttackBurstNumber);
		
		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(MortarLauncherLeftComp, Settings.MortarAttackTelegraphDuration));
		AnimComp.RequestFeature(FeatureTagIslandSecurityMech::LaunchRocket, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this);

		Cooldown.Set(Settings.MortarAttackCooldown + Math::RandRange(-0.5, 0.5));
		bHasPrimed = false;
		AnimComp.ClearFeature(this);

		ExpirePrimedProjectiles();		
	}

	bool bHasPrimed = false; //temp
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if (NumPrimedProjectiles < Settings.MortarAttackBurstNumber && NextPrimeTime < Time::GameTimeSeconds)
		{
			if (NumPrimedProjectiles % 2 == 0)
				PrimeProjectile(MortarLauncherLeftComp);
			else
				PrimeProjectile(MortarLauncherRightComp);

			
			NextPrimeTime += FireInterval * 0.9;
			
			if (!bHasPrimed && NumPrimedProjectiles == 2)
			{
				NextPrimeTime += Settings.MortarAttackTelegraphDuration;
				bHasPrimed = true;
			}
		}

		if (ActiveDuration < Settings.MortarAttackTelegraphDuration)
			return;

		if(NumFiredProjectiles < Settings.MortarAttackBurstNumber && NextFireTime < Time::GameTimeSeconds)
		{			
			if (NumFiredProjectiles % 2 == 0)
				FireProjectile(MortarLauncherLeftComp);
			else
				FireProjectile(MortarLauncherRightComp);			
			NextFireTime += FireInterval;			
			if (NumFiredProjectiles >= Settings.MortarAttackBurstNumber)
				NextFireTime += BIG_NUMBER;			
		}
			
	}

	// Prime and start telegraphing
	private void PrimeProjectile(UBasicAIProjectileLauncherComponent Launcher)
	{
		devCheck(Launcher.PrimedProjectile == nullptr, "Launcher tries to prime a new projectile before launching previous.");
		NumPrimedProjectiles++;
		UBasicAIProjectileComponent ProjectileComp = Launcher.Prime();
		// TODO: select trailing actor location and one predicted location
		FVector AttackLocation = TargetComp.Target.ActorLocation + TargetComp.Target.ActorVelocity * Settings.MortarAttackProjectileAirTime * 0.5;
		AIslandShieldotronMortarProjectile ProjectileOwner = Cast<AIslandShieldotronMortarProjectile>(ProjectileComp.Owner);
		ProjectileOwner.TargetLocation = AttackLocation;

		//FVector LaunchVelocity = FVector::UpVector * Settings.MortarAttackProjectileSpeed; // temp
		//if (IslandShieldotron::HasClearMortarTrajectory(Launcher.WorldLocation, AttackLocation, LaunchVelocity, Settings.MortarAttackLandingSteepness))
			//UIslandShieldotronMortarProjectileEventHandler::Trigger_OnStartTargetTelegraph(ProjectileOwner, FIslandShieldotronMortarProjectileOnTargetTelegraphEventData(AttackLocation));
		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Launcher, Settings.MortarAttackTelegraphDuration));	
	}

	// Launch the primed projectile
	UFUNCTION(NotBlueprintCallable)
	private void FireProjectile(UBasicAIProjectileLauncherComponent Launcher)
	{
		NumFiredProjectiles++;		
		FVector AimDir = FVector::UpVector;
		UBasicAIProjectileComponent ProjectileComp = Launcher.Launch(AimDir * Settings.MortarAttackProjectileEndSpeed);
		AIslandShieldotronMortarProjectile ProjectileOwner = Cast<AIslandShieldotronMortarProjectile>(ProjectileComp.Owner);
		ProjectileOwner.LaunchAt(ProjectileOwner.TargetLocation);		

		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Launcher, NumFiredProjectiles, Settings.MortarAttackBurstNumber));
	}

	private void ExpirePrimedProjectiles()
	{
		if (MortarLauncherLeftComp.PrimedProjectile != nullptr)
		{
			Cast<AIslandShieldotronMortarProjectile>(MortarLauncherLeftComp.PrimedProjectile.Owner).Expire();
			MortarLauncherLeftComp.PrimedProjectile = nullptr;

		}
		if (MortarLauncherRightComp.PrimedProjectile != nullptr)
		{
			Cast<AIslandShieldotronMortarProjectile>(MortarLauncherRightComp.PrimedProjectile.Owner).Expire();
			MortarLauncherRightComp.PrimedProjectile = nullptr;
		}
	}	
} 