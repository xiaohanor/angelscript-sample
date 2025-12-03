class UEnforcerRifleBulletStreamAttackBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	
	const FName WeaponTag = n"EnforcerWeaponRifle";
	default CapabilityTags.Add(WeaponTag);
	default CapabilityTags.Add(n"Attack");
	default CapabilityTags.Add(n"BulletStream");

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UEnforcerRifleComponent Weapon;
	UBasicAIHealthComponent HealthComp;
	float EndTime;

	UEnforcerRifleSettings RifleSettings;

	float FireTime = 0.0;
	float RecoveryTime = 0.0;
	int FiredProjectiles = 0;
	int ExpiredProjectiles = 0;
	private float AimHeightOffset = -50.0;
	FVector FireDir;
	bool bHasCausedStumble = false;

	TPerPlayer<int> StreamHits;
	UTargetTrailComponent TrailComp;
	AHazePlayerCharacter Target;
	UAIFirePatternManager FirePatternManager = nullptr;
	FAIFirePattern FirePattern;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		AimHeightOffset *= UHazeCharacterSkeletalMeshComponent::Get(Owner).GetWorldScale().Z;
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		Weapon = UEnforcerRifleComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		if (Weapon == nullptr)
		{
			UBasicAIWeaponWielderComponent WielderComp = UBasicAIWeaponWielderComponent::Get(Owner);
			if (WielderComp != nullptr) 
			{
				if (WielderComp.Weapon != nullptr)
					Weapon = UEnforcerRifleComponent::Get(WielderComp.Weapon);
				WielderComp.OnWieldWeapon.AddUFunction(this, n"OnWieldWeapon");
			}
			if(Weapon == nullptr)
			{
				// You can't block yourself using yourself as instigator, will need to use a name
				Owner.BlockCapabilities(WeaponTag, FName(GetPathName()));
			}
		}

		UTargetTrailComponent::GetOrCreate(Game::Mio);
		UTargetTrailComponent::GetOrCreate(Game::Zoe);

		RifleSettings = UEnforcerRifleSettings::GetSettings(Owner);		

		AnimComp.bIsAiming = true;			
	}

	UFUNCTION()
	private void OnWieldWeapon(ABasicAIWeapon WieldedWeapon)
	{
		if (WieldedWeapon == nullptr)
			return;
		UEnforcerRifleComponent NewWeapon = UEnforcerRifleComponent::Get(WieldedWeapon);
		if (NewWeapon != nullptr)
		{
			Weapon = NewWeapon;
			Weapon.SetWielder(Owner);
			if(Owner.IsCapabilityTagBlocked(WeaponTag))
				Owner.UnblockCapabilities(WeaponTag, FName(GetPathName()));
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (Weapon == nullptr) 
			return;
		
		if ((FirePatternManager == nullptr) && (Weapon.FirePatterns != nullptr))
			FirePatternManager = AIFirePattern::GetOrCreateManager(Owner, Weapon.FirePatterns);	

		Weapon.Owner.AddTickPrerequisiteActor(Owner);

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
		if (Weapon == nullptr)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, BasicSettings.AttackRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, RifleSettings.MinimumAttackRange))
			return false;
		if (BasicSettings.RangedAttackRequireVisibility && !TargetComp.HasVisibleTarget(TargetOffset = TargetComp.Target.ActorUpVector * AimHeightOffset))
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
		if(!GentCostQueueComp.IsNext(this) && (RifleSettings.GentlemanCost != EGentlemanCost::None))
			return false;
		if(!GentCostComp.IsTokenAvailable(RifleSettings.GentlemanCost))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		

		Target = Cast<AHazePlayerCharacter>(TargetComp.Target);
		TrailComp = UTargetTrailComponent::Get(Target);

		GetFirePattern(FirePattern);

		FiredProjectiles = 0;
		ExpiredProjectiles = 0;
		FireTime = RifleSettings.TelegraphDuration + RifleSettings.AnticipationDuration + FirePattern.ProjectileIntervals[0];
		StreamHits[Game::Mio] = 0;
		StreamHits[Game::Zoe] = 0;
		bHasCausedStumble = false;
		RecoveryTime = 0;

		GentCostComp.ClaimToken(this, RifleSettings.GentlemanCost);

		UEnforcerWeaponEffectHandler::Trigger_OnTelegraph(Weapon.WeaponActor, FEnforcerWeaponEffectTelegraphData(Weapon.GetLaunchLocation(), RifleSettings.TelegraphDuration));
		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Weapon, RifleSettings.TelegraphDuration));
		UEnforcerEffectHandler::Trigger_OnTelegraphShooting(Owner, FEnforcerEffectOnTelegraphData(RifleSettings.TelegraphDuration));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this, RifleSettings.AttackTokenCooldown);
		UEnforcerEffectHandler::Trigger_OnPostFire(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(RecoveryTime > 0)
		{
			if(Time::GetGameTimeSince(RecoveryTime) > 0.25)
				Cooldown.Set(RifleSettings.BulletStreamCooldown);
			return;
		}

		if(ActiveDuration < RifleSettings.TelegraphDuration)
		{
			// Update direction of fire during telegraph, then fire in a steady stream
			FVector WeaponLoc = Weapon.GetLaunchLocation();
			FVector TargetLoc = Target.FocusLocation + Target.ActorUpVector * AimHeightOffset;
			FVector PredictionOffset = FVector::ZeroVector;

			// If the target has turned into not valid, we shoot past them on the sides
			if(!TargetComp.IsValidTarget(Target))
				TargetLoc += (TargetLoc - WeaponLoc).GetSafeNormal().Rotation().RightVector * 350;
			else
			{
				PredictionOffset = TrailComp.GetAverageVelocity(0.25) * RifleSettings.StreamPredictionTime;
				PredictionOffset.Z *= 0.2;
			}			

			FireDir = (TargetLoc + PredictionOffset - WeaponLoc).GetSafeNormal();
			FireDir = FireDir.ClampInsideCone(TargetLoc - WeaponLoc, 25);
		}

		if(ActiveDuration < RifleSettings.TelegraphDuration + RifleSettings.AnticipationDuration)
		{
			DestinationComp.RotateInDirection(FireDir);
			return;
		}

		if((FiredProjectiles < FirePattern.NumberOfProjectiles) && (ActiveDuration > FireTime))
			FireProjectile();
		
		if(FiredProjectiles >= FirePattern.NumberOfProjectiles)
			RecoveryTime = Time::GameTimeSeconds;
	}

	UFUNCTION(NotBlueprintCallable)
	private void FireProjectile()
	{
		FRotator Scatter; 
		Scatter.Yaw = Math::RandRange(-RifleSettings.ScatterYaw, RifleSettings.ScatterYaw);
		Scatter.Pitch = Math::RandRange(-RifleSettings.ScatterPitch, RifleSettings.ScatterPitch);
		FVector ScatterDir = Scatter.RotateVector(FireDir);

		// Launch projectile in same direction
		UBasicAIProjectileComponent Projectile = Weapon.Launch(ScatterDir * RifleSettings.LaunchSpeed);
		Projectile.Damage = 0.0; // Projectile will not do damage, stream does as a whole
		AEnforcerRifleProjectile StreamProjectile = Cast<AEnforcerRifleProjectile>(Projectile.Owner);
		StreamProjectile.OnPlayerHit.AddUFunction(this, n"OnPlayerHit");
		StreamProjectile.OnExpire.AddUFunction(this, n"OnProjectileExpire");
		
		UBasicAIAnimationFeatureAdditiveShooting ShootingFeature = Cast<UBasicAIAnimationFeatureAdditiveShooting>(AnimComp.GetFeatureByClass(UBasicAIAnimationFeatureAdditiveShooting));
		if ((ShootingFeature != nullptr) && (ShootingFeature.SingleShot != nullptr))
			Owner.PlayAdditiveAnimation(FHazeAnimationDelegate(), ShootingFeature.SingleShot);

		FiredProjectiles++;
		FireTime += (FiredProjectiles < FirePattern.NumberOfProjectiles) ? FirePattern.ProjectileIntervals[FiredProjectiles] : BIG_NUMBER;

		UEnforcerWeaponEffectHandler::Trigger_OnLaunch(Weapon.WeaponActor, FEnforcerWeaponEffectLaunchParams(FiredProjectiles, RifleSettings.ProjectileAmount, Weapon.GetLaunchLocation()));
		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Weapon, FiredProjectiles, RifleSettings.ProjectileAmount));
		UEnforcerEffectHandler::Trigger_OnShotFired(Owner);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnProjectileExpire(AEnforcerRifleProjectile Projectile)
	{
		// Projectile is ready for reuse, we need not keep track of it any longer
		Projectile.OnExpire.UnbindObject(this);
		Projectile.OnPlayerHit.UnbindObject(this);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerHit(AHazePlayerCharacter Player, FPlayerDeathDamageParams DeathEffectParams = FPlayerDeathDamageParams())
	{
		StreamHits[Player]++;
		if (StreamHits[Player] < RifleSettings.StreamHighDamageThreshold)
		{
			// Just warning damage
			// Player.DealBatchedDamageOverTime(0.01); // Can't deal batched damage or we will negate "second chance" grace period.
			UPlayerDamageEventHandler::Trigger_TakeDamageOverTime(Player);
		}
		else
		{
			UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(Player);
			float Damage = Time::GetGameTimeSince(PlayerHealthComp.Health.GameTimeAtMostRecentDamage) < RifleSettings.StreamHighDamageCooldown ? RifleSettings.StreamLowDamage : RifleSettings.StreamHighDamage;
			Player.DamagePlayerHealth(Damage, DeathEffectParams, Weapon.DamageEffect, Weapon.DeathEffect, false);
			UPlayerDamageEventHandler::Trigger_TakeSmallDamage(Player);
		}
		Player.ApplyAdditiveHitReaction(FireDir);

		if (!bHasCausedStumble && (StreamHits[Player] >= RifleSettings.StreamStumbleThreshold))
		{
			bHasCausedStumble = true;
			Player.ApplyStumble(FireDir.VectorPlaneProject(Player.ActorUpVector).GetSafeNormal() * RifleSettings.StreamStumbleDistance, RifleSettings.StreamStumbleDuration);
		}
	}

	void GetFirePattern(FAIFirePattern& Pattern)
	{
		// Fire patterns for this kind of attack should not be functionally different enough to make a difference in network
		if (FirePatternManager != nullptr)
			Pattern = FirePatternManager.ConsumePattern();

		// Fill out pattern if it was too short. We need to be able to cause damage propely at the very least
		for (int i = Pattern.ProjectileIntervals.Num(); i < RifleSettings.StreamHighDamageThreshold; i++)
		{
			Pattern.ProjectileIntervals.Add((i == 0) ? 0.0 : 0.1);
		}
	}
} 