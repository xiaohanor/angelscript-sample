class UEnforcerRifleDualWieldingAttackBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	const FName WeaponTag = n"EnforcerWeaponRifle";
	default CapabilityTags.Add(WeaponTag);
	default CapabilityTags.Add(n"Attack");

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UEnforcerRifleComponent Weapon;
	UBasicAIHealthComponent HealthComp;
	float EndTime;

	UEnforcerDualWieldingSettings Settings;
	UAIFirePatternManager FirePatternManager = nullptr;
	FAIFirePattern FirePattern;

	float FireTime = 0.0;
	int FiredProjectiles = 0;
	int ExpiredProjectiles = 0;
	private FVector AimTargetOffset = FVector(0, 0, -50);
	FVector TargetLoc;
	

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		// Mesh is temporarily scaled
		AimTargetOffset.Z *= UHazeCharacterSkeletalMeshComponent::Get(Owner).GetWorldScale().Z;
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		Weapon = UEnforcerRifleComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		if (Weapon == nullptr)
		{			
			// Multiple WeaponWielders for HoverEnforcer. Assumes at most one rifle per owner. 
			TArray<UActorComponent> WielderComponents;
			Owner.GetAllComponents(UBasicAIWeaponWielderComponent, WielderComponents);
			for (UActorComponent& Comp : WielderComponents)
			{
				UBasicAIWeaponWielderComponent WielderComp = Cast<UBasicAIWeaponWielderComponent>(Comp);
				if (WielderComp != nullptr) 
				{
					WielderComp.OnWieldWeapon.AddUFunction(this, n"OnWieldWeapon");
					if (WielderComp.Weapon != nullptr)
					{
						Weapon = UEnforcerRifleComponent::Get(WielderComp.Weapon);
						break;
					}
				}
			}
			if(Weapon == nullptr)
			{
				// You can't block yourself using yourself as instigator, will need to use a name
				Owner.BlockCapabilities(WeaponTag, FName(GetPathName()));
			}
		}

		Settings = UEnforcerDualWieldingSettings::GetSettings(Owner);		

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
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.RifleMinimumAttackRange))
			return false;
		if (BasicSettings.RangedAttackRequireVisibility && !TargetComp.HasVisibleTarget(TargetOffset = AimTargetOffset))
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
		if(!GentCostQueueComp.IsNext(this) && (Settings.RifleGentlemanCost != EGentlemanCost::None))
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.RifleGentlemanCost))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		

		GetFirePattern(FirePattern);
		FireTime = Settings.RifleTelegraphDuration + FirePattern.ProjectileIntervals[0];
		FiredProjectiles = 0;
		ExpiredProjectiles = 0;

		GentCostComp.ClaimToken(this, Settings.RifleGentlemanCost);

		UEnforcerWeaponEffectHandler::Trigger_OnTelegraph(Weapon.WeaponActor, FEnforcerWeaponEffectTelegraphData(Weapon.GetLaunchLocation(), Settings.RifleTelegraphDuration));
		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Weapon, Settings.RifleTelegraphDuration));
		UEnforcerEffectHandler::Trigger_OnTelegraphShooting(Owner, FEnforcerEffectOnTelegraphData(Settings.RifleTelegraphDuration));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this, Settings.RifleAttackTokenCooldown);
		UEnforcerEffectHandler::Trigger_OnPostFire(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < Settings.RifleTelegraphDuration)
			return;

		if ((FiredProjectiles < FirePattern.NumberOfProjectiles) && (ActiveDuration > FireTime))
		{
			TargetLoc = TargetComp.Target.FocusLocation + AimTargetOffset;
			FireProjectile();
		}
		
		if (FiredProjectiles >= FirePattern.NumberOfProjectiles)
			Cooldown.Set(Settings.RifleLaunchInterval - ActiveDuration);
	}

	UFUNCTION(NotBlueprintCallable)
	private void FireProjectile()
	{
		// Launch projectile at predicted location
		FVector WeaponLoc = Weapon.GetLaunchLocation();
		FVector AimDir = (TargetLoc - WeaponLoc).GetSafeNormal();

		// Introduce scatter
		// TODO: This needs networking!
		FRotator Scatter; 
		Scatter.Yaw = Math::RandRange(-BasicSettings.RangedAttackScatterYaw, BasicSettings.RangedAttackScatterYaw);
		Scatter.Pitch = Math::RandRange(-BasicSettings.RangedAttackScatterPitch, BasicSettings.RangedAttackScatterPitch);
		// AimDir = Scatter.RotateVector(AimDir);

		UBasicAIProjectileComponent Projectile = Weapon.Launch(AimDir * Settings.RifleLaunchSpeed);
		
		UBasicAIHomingProjectileComponent HomingComp = UBasicAIHomingProjectileComponent::Get(Projectile.Owner);
		if (HomingComp != nullptr)
			HomingComp.Target = TargetComp.Target;

		UBasicAIAnimationFeatureAdditiveShooting ShootingFeature = Cast<UBasicAIAnimationFeatureAdditiveShooting>(AnimComp.GetFeatureByClass(UBasicAIAnimationFeatureAdditiveShooting));
		if ((ShootingFeature != nullptr) && (ShootingFeature.SingleShot != nullptr))
			Owner.PlayAdditiveAnimation(FHazeAnimationDelegate(), ShootingFeature.SingleShot);

		FiredProjectiles++;
		FireTime += (FiredProjectiles < FirePattern.NumberOfProjectiles) ? FirePattern.ProjectileIntervals[FiredProjectiles] : BIG_NUMBER;

		UEnforcerWeaponEffectHandler::Trigger_OnLaunch(Weapon.WeaponActor, FEnforcerWeaponEffectLaunchParams(FiredProjectiles, FirePattern.NumberOfProjectiles, WeaponLoc));
		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Weapon, FiredProjectiles, FirePattern.NumberOfProjectiles));
		UEnforcerEffectHandler::Trigger_OnShotFired(Owner);
	}

	void GetFirePattern(FAIFirePattern& Pattern)
	{
		// Fire patterns for this kind of attack should not be functionally different enough to make a difference in network
		if (FirePatternManager != nullptr)
			Pattern = FirePatternManager.ConsumePattern();

		// Fill out pattern if it was too short. We need to be able to cause damage properly at the very least
		for (int i = Pattern.ProjectileIntervals.Num(); i < 3; i++)
		{
			Pattern.ProjectileIntervals.Add((i == 0) ? 0.0 : 0.1);
		}
	}
} 