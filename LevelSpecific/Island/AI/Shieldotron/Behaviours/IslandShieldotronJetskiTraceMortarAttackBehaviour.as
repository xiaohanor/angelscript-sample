class UIslandShieldotronJetskiTraceMortarAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Movement);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Focus);
	
	default CapabilityTags.Add(BasicAITags::Attack);
	default CapabilityTags.Add(n"MortarAttack");

	UGentlemanCostComponent GentCostComp;	
	UIslandShieldotronMortarLauncherLeft MortarLauncherLeftComp;
	UIslandShieldotronMortarLauncherRight MortarLauncherRightComp;
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
	bool bIsFirstActivation = true;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		MortarLauncherLeftComp = UIslandShieldotronMortarLauncherLeft::Get(Owner);
		MortarLauncherRightComp = UIslandShieldotronMortarLauncherRight::Get(Owner);
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
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.MortarAttackMaxRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.MortarAttackMinRange))
			return false;		
		FVector ToTargetDir = (TargetComp.Target.ActorCenterLocation - Owner.ActorCenterLocation).GetSafeNormal2D();
		if (Owner.ActorForwardVector.DotProduct(ToTargetDir) < 0.707) // 45 degrees
			return false;
				
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!Settings.bHasMortarAttack)
			return false;
		if (Owner.IsAnyCapabilityActive(n"RocketAttack")) // includes orb
			return false;
		if (!CanAttack())
			return false;		
		if(!GentCostComp.IsTokenAvailable(Settings.JetskiMortarAttackGentlemanCost))
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

		if (bIsFirstActivation)
		{
			DeactivateBehaviour();			
			return;
		}

		GentCostComp.ClaimToken(this, Settings.JetskiMortarAttackGentlemanCost);

		NumFiredProjectiles = 0;
		NumPrimedProjectiles = 0;
		NextFireTime = Time::GameTimeSeconds + Settings.MortarAttackTelegraphDuration;
		NextPrimeTime = Time::GameTimeSeconds  + Settings.MortarAttackTelegraphDuration * 0.9;
		FireInterval = Settings.MortarAttackDuration / float(Settings.MortarAttackBurstNumber);
		LastAttackLocation = FVector::ZeroVector;
		AttackDir = FVector::ZeroVector;

		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(MortarLauncherLeftComp, Settings.MortarAttackTelegraphDuration));
		AnimComp.RequestFeature(FeatureTagIslandSecurityMech::LaunchRocket, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(Settings.JetskiMortarAttackCooldown + Math::RandRange(Settings.JetskiMortarAttackCooldownMinRandomRange, Settings.JetskiMortarAttackCooldownMaxRandomRange));

		if (bIsFirstActivation)
		{
			bIsFirstActivation = false;
			return;
		}

		GentCostComp.ReleaseToken(this);		
		
		bHasPrimed = false;
		bHasAttackLocationInAir = false;
		AnimComp.ClearFeature(this);

		ExpirePrimedProjectiles();		
	}

	bool bHasPrimed = false; //temp
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if(bIsFirstActivation)
			return;

		if (NumPrimedProjectiles < Settings.MortarAttackBurstNumber && NextPrimeTime < Time::GameTimeSeconds)
		{
			if (NumPrimedProjectiles % 2 == 0)
				PrimeProjectile(MortarLauncherRightComp);
			else
				PrimeProjectile(MortarLauncherLeftComp);

			
			NextPrimeTime += FireInterval;
		}

		if (ActiveDuration < Settings.MortarAttackTelegraphDuration)
			return;

		if(NumFiredProjectiles < Settings.MortarAttackBurstNumber && NextFireTime < Time::GameTimeSeconds)
		{			
			if (NumFiredProjectiles % 2 == 0)
				FireProjectile(MortarLauncherRightComp);			
			else
				FireProjectile(MortarLauncherLeftComp);
			NextFireTime += FireInterval;			
			if (NumFiredProjectiles >= Settings.MortarAttackBurstNumber)
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
			CenterOfAttackLocation = TargetComp.Target.ActorLocation + TargetComp.Target.ActorVelocity * 0.3;
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
			if (TargetComp.Target.ActorVelocity.Size2D() > 25)
				AttackLocation = TargetComp.Target.ActorLocation + TargetComp.Target.ActorVelocity * 0.3;
			else
				AttackLocation = CenterOfAttackLocation + AttackDir.RotateAngleAxis(360/5.0 * (NumPrimedProjectiles - 2), FVector::UpVector) * Radius;
		
			// Update height of target location
			if (CurrentGround != nullptr)
				AttackLocation.Z += (CurrentGround.ActorLocation.Z - InitialGroundActorLocation.Z);
		}

		// Add a random offset to expire in air at different heights.
		if (bHasAttackLocationInAir)
			AttackLocation += FVector(0,0,Math::RandRange(-100, 0));

		LastAttackLocation = AttackLocation;
		AIslandShieldotronMortarProjectile MortarProjectile = Cast<AIslandShieldotronMortarProjectile>(ProjectileComp.Owner);
		MortarProjectile.TargetLocation = AttackLocation;
		
		MortarProjectile.SpawnDecal(AttackLocation);

		UIslandShieldotronMortarProjectileEventHandler::Trigger_OnStartTargetTelegraph(MortarProjectile, FIslandShieldotronMortarProjectileOnTargetTelegraphEventData(AttackLocation, CurrentGround));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnStartTelegraphMortarAttack(Game::Zoe, FIslandShieldotronMortarTelegraphPlayerEventData(Launcher.LauncherActor, TargetComp.Target));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnStartTelegraphMortarAttack(Game::Mio, FIslandShieldotronMortarTelegraphPlayerEventData(Launcher.LauncherActor, TargetComp.Target));
		
		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Launcher, Settings.MortarAttackTelegraphDuration));	
	}

	// Launch the primed projectile
	UFUNCTION(NotBlueprintCallable)
	private void FireProjectile(UBasicAIProjectileLauncherComponent Launcher)
	{
		NumFiredProjectiles++;		
		FVector AimDir = Launcher.ForwardVector;
		UBasicAIProjectileComponent ProjectileComp = Launcher.Launch(AimDir * Settings.MortarAttackProjectileLaunchSpeed);
		AIslandShieldotronMortarProjectile ProjectileOwner = Cast<AIslandShieldotronMortarProjectile>(ProjectileComp.Owner);
		ProjectileOwner.LaunchAt(ProjectileOwner.TargetLocation, CurrentGround);		

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