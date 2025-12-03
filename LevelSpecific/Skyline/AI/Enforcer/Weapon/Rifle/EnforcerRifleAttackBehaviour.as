class UEnforcerRifleAttackBehaviour : UBasicBehaviour
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

	UEnforcerRifleSettings RifleSettings;

	float FiredTime = 0.0;
	float PrimeTime = 0.0;
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

		FiredProjectiles = 0;
		ExpiredProjectiles = 0;

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
		if(ActiveDuration < RifleSettings.TelegraphDuration)
			return;

		if(FiredProjectiles < RifleSettings.ProjectileAmount && (FiredTime == 0 || Time::GetGameTimeSince(FiredTime) > RifleSettings.TimeBetweenBurstProjectiles))
		{
			if(PrimeTime == 0)
			{
				Weapon.Prime();
				PrimeTime = Time::GetGameTimeSeconds();
			}
			
			if(Time::GetGameTimeSince(PrimeTime) > RifleSettings.PrimeDuration)
				return;		

			TargetLoc = TargetComp.Target.FocusLocation + AimTargetOffset;
			FireProjectile();
		}
		
		if(FiredProjectiles >= RifleSettings.ProjectileAmount)
		{
			Cooldown.Set(RifleSettings.LaunchInterval - ActiveDuration);
		}
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

		UBasicAIProjectileComponent Projectile = Weapon.Launch(AimDir * RifleSettings.LaunchSpeed);
		Projectile.Damage = RifleSettings.PlayerDamage;
		
		UBasicAIHomingProjectileComponent HomingComp = UBasicAIHomingProjectileComponent::Get(Projectile.Owner);
		if (HomingComp != nullptr)
			HomingComp.Target = TargetComp.Target;

		UBasicAIAnimationFeatureAdditiveShooting ShootingFeature = Cast<UBasicAIAnimationFeatureAdditiveShooting>(AnimComp.GetFeatureByClass(UBasicAIAnimationFeatureAdditiveShooting));
		if ((ShootingFeature != nullptr) && (ShootingFeature.SingleShot != nullptr))
			Owner.PlayAdditiveAnimation(FHazeAnimationDelegate(), ShootingFeature.SingleShot);

		FiredProjectiles++;
		FiredTime = Time::GetGameTimeSeconds();
		PrimeTime = 0;

		UEnforcerWeaponEffectHandler::Trigger_OnLaunch(Weapon.WeaponActor, FEnforcerWeaponEffectLaunchParams(FiredProjectiles, RifleSettings.ProjectileAmount, WeaponLoc));
		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Weapon, FiredProjectiles, RifleSettings.ProjectileAmount));
		UEnforcerEffectHandler::Trigger_OnShotFired(Owner);
	}
} 