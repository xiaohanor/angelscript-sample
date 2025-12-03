class UIslandShieldotronMissileAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Movement);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Focus);
	
	default CapabilityTags.Add(BasicAITags::Attack);
	default CapabilityTags.Add(n"MissileAttack");

	UGentlemanCostComponent GentCostComp;	
	UIslandShieldotronMissileLauncherLeft MissileLauncherLeftComp;
	UIslandShieldotronMissileLauncherRight MissileLauncherRightComp;
	UBasicAIHealthComponent HealthComp;
	UIslandShieldotronJumpComponent JumpComp;

	UIslandShieldotronSettings Settings;

	UBasicAIProjectileLauncherComponent NextPrimeLauncher;
	UBasicAIProjectileLauncherComponent NextFireLauncher;

	float NextFireTime = 0.0;	
	float NextPrimeTime = 0.0;	
	int NumPrimedProjectiles = 0;
	int NumFiredProjectiles = 0;
	float FireInterval;
	bool bHasAttackLocationInAir = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		MissileLauncherLeftComp = UIslandShieldotronMissileLauncherLeft::Get(Owner);
		MissileLauncherRightComp = UIslandShieldotronMissileLauncherRight::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HealthComp.OnDie.AddUFunction(this, n"OnDie");
		JumpComp = UIslandShieldotronJumpComponent::GetOrCreate(Owner);
		Settings = UIslandShieldotronSettings::GetSettings(Owner);		

		AnimComp.bIsAiming = false;
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
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.MissileAttackMaxRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.MissileAttackMinRange))
			return false;		
		FVector ToTargetDir = (TargetComp.Target.ActorCenterLocation - Owner.ActorCenterLocation).GetSafeNormal2D();
		if (Owner.ActorForwardVector.DotProduct(ToTargetDir) < 0.707) // 45 degrees
			return false;

		if (!TargetComp.HasGeometryVisibleTarget())
			return false;
		
		// Does Projectile have an unbstructed trajectory path?
		FVector AttackLocation = TargetComp.Target.ActorLocation + TargetComp.Target.ActorVelocity * Settings.MissileAttackProjectileAirTime * 0.5;
		FVector LaunchVelocity = FVector::UpVector * Settings.MissileAttackProjectileSpeed; // temp
		if (!IslandShieldotron::HasClearMortarTrajectory(MissileLauncherLeftComp.WorldLocation, AttackLocation, LaunchVelocity, Settings.MissileAttackLandingSteepness))
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!Settings.bHasMissileAttack)
			return false;
		if (Owner.IsAnyCapabilityActive(n"RocketAttack"))
			return false;
		if (!CanAttack())
			return false;
		if (JumpComp.bIsJumping)
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.MissileAttackGentlemanCost))
			return false;


		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.MissileAttackDuration + Settings.MissileAttackTelegraphDuration + 2.0 && NumFiredProjectiles >= Settings.MissileAttackBurstNumber)
			return true;
		
		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		
		
		GentCostComp.ClaimToken(this, Settings.MissileAttackGentlemanCost);

		NumFiredProjectiles = 0;
		NumPrimedProjectiles = 0;
		NextFireTime = Time::GameTimeSeconds + Settings.MissileAttackTelegraphDuration;
		NextPrimeTime = Time::GameTimeSeconds  + Settings.MissileAttackTelegraphDuration * 0.9;
		FireInterval = Settings.MissileAttackDuration / float(Settings.MissileAttackBurstNumber);
		LastAttackLocation = FVector::ZeroVector;
		AttackDir = FVector::ZeroVector;

		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(MissileLauncherLeftComp, Settings.MissileAttackTelegraphDuration));
		AnimComp.RequestFeature(FeatureTagIslandSecurityMech::LaunchRocket, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this);

		Cooldown.Set(Settings.MissileAttackCooldown + Math::RandRange(-0.5, 0.5));
		bHasPrimed = false;
		bHasAttackLocationInAir = false;
		AnimComp.ClearFeature(this);

		ExpirePrimedProjectiles();		
	}

	bool bHasPrimed = false; //temp
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if (NumPrimedProjectiles < Settings.MissileAttackBurstNumber && NextPrimeTime < Time::GameTimeSeconds)
		{
			if (NumPrimedProjectiles % 2 == 0)
				PrimeProjectile(MissileLauncherRightComp);
			else
				PrimeProjectile(MissileLauncherLeftComp);

			
			NextPrimeTime += FireInterval;
		}

		if (ActiveDuration < Settings.MissileAttackTelegraphDuration)
			return;

		if(NumFiredProjectiles < Settings.MissileAttackBurstNumber && NextFireTime < Time::GameTimeSeconds)
		{			
			if (NumFiredProjectiles % 2 == 0)
				FireProjectile(MissileLauncherRightComp);			
			else
				FireProjectile(MissileLauncherLeftComp);
			NextFireTime += FireInterval;			
			if (NumFiredProjectiles >= Settings.MissileAttackBurstNumber)
				NextFireTime += BIG_NUMBER;			
		}
			
	}

	FVector CenterOfAttackLocation;
	FVector LastAttackLocation;
	FVector AttackDir;
	AActor CurrentGround;
	FVector InitialGroundActorLocation;
	// Prime and start telegraphing
	private void PrimeProjectile(UBasicAIProjectileLauncherComponent Launcher)
	{
		devCheck(Launcher.PrimedProjectile == nullptr, "Launcher tries to prime a new projectile before launching previous.");
		NumPrimedProjectiles++;		
		UBasicAIProjectileComponent ProjectileComp = Launcher.Prime();
		FVector AttackLocation;
		
		// Target player and circle around player.
		if (AttackDir == FVector::ZeroVector)
		{
			CurrentGround = nullptr;
			AttackDir = (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal2D().CrossProduct(FVector::UpVector);
			CenterOfAttackLocation = TargetComp.Target.ActorLocation;			
			FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::WorldGeometry);
			Trace.UseLine();
			FHitResult Ground = Trace.QueryTraceSingle(CenterOfAttackLocation + FVector::UpVector * 50, CenterOfAttackLocation + FVector::DownVector * 500);			
			if (Ground.bBlockingHit)
			{
				CenterOfAttackLocation = Ground.ImpactPoint;
				CurrentGround = Ground.Actor;
				InitialGroundActorLocation = Ground.Actor.ActorLocation;
			}
			else
				bHasAttackLocationInAir = true;
		}		

		float Radius = 150;
		if (NumPrimedProjectiles == 1)
			AttackLocation = CenterOfAttackLocation;
		else
		{
			AttackLocation = CenterOfAttackLocation + AttackDir.RotateAngleAxis(360/5.0 * (NumPrimedProjectiles - 2), FVector::UpVector) * Radius;
		
			// Update height of target location
			if (CurrentGround != nullptr)
				AttackLocation.Z += (CurrentGround.ActorLocation.Z - InitialGroundActorLocation.Z);
		}

		// Add a random offset to expire in air at different heights.
		if (bHasAttackLocationInAir)
			AttackLocation += FVector(0,0,Math::RandRange(-100, 0));

		LastAttackLocation = AttackLocation;
		AIslandShieldotronMissileProjectile ProjectileOwner = Cast<AIslandShieldotronMissileProjectile>(ProjectileComp.Owner);
		ProjectileOwner.TargetLocation = AttackLocation;

		UIslandShieldotronMortarProjectileEventHandler::Trigger_OnStartTargetTelegraph(ProjectileOwner, FIslandShieldotronMortarProjectileOnTargetTelegraphEventData(AttackLocation, CurrentGround));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnStartTelegraphMortarAttack(Game::Zoe, FIslandShieldotronMortarTelegraphPlayerEventData(Launcher.LauncherActor, TargetComp.Target));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnStartTelegraphMortarAttack(Game::Mio, FIslandShieldotronMortarTelegraphPlayerEventData(Launcher.LauncherActor, TargetComp.Target));
		
		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Launcher, Settings.MissileAttackTelegraphDuration));	
	}

	// Launch the primed projectile
	UFUNCTION(NotBlueprintCallable)
	private void FireProjectile(UBasicAIProjectileLauncherComponent Launcher)
	{
		NumFiredProjectiles++;		
		FVector AimDir = Launcher.ForwardVector;
		UBasicAIProjectileComponent ProjectileComp = Launcher.Launch(AimDir * Settings.MissileAttackProjectileLaunchSpeed);
		AIslandShieldotronMissileProjectile ProjectileOwner = Cast<AIslandShieldotronMissileProjectile>(ProjectileComp.Owner);
		ProjectileOwner.LaunchAt(ProjectileOwner.TargetLocation, CurrentGround);		

		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Launcher, NumFiredProjectiles, Settings.MissileAttackBurstNumber));
	}

	private void ExpirePrimedProjectiles()
	{
		if (MissileLauncherLeftComp.PrimedProjectile != nullptr)
		{
			Cast<AIslandShieldotronMissileProjectile>(MissileLauncherLeftComp.PrimedProjectile.Owner).Expire();
			MissileLauncherLeftComp.PrimedProjectile = nullptr;

		}
		if (MissileLauncherRightComp.PrimedProjectile != nullptr)
		{
			Cast<AIslandShieldotronMissileProjectile>(MissileLauncherRightComp.PrimedProjectile.Owner).Expire();
			MissileLauncherRightComp.PrimedProjectile = nullptr;
		}
	}	
} 