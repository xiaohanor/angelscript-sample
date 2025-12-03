class UIslandShieldotronSidescrollerAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon); // weapon = attack
	default Requirements.AddBlock(EBasicBehaviourRequirement::Perception); // prevent switching targets midattack

	default CapabilityTags.Add(BasicAITags::Attack);

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIProjectileLauncherComponent Weapon;
	UBasicAIHealthComponent HealthComp;

	UIslandShieldotronSidescrollerSettings Settings;

	private float NextFireTime = 0.0;
	private int NumFiredProjectiles = 0;	
	private FVector TargetLoc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		Weapon = UBasicAIProjectileLauncherComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		
		Settings = UIslandShieldotronSidescrollerSettings::GetSettings(Owner);		
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
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
		if (Super::ShouldActivate() == false)
			return false;
		if (!WantsToAttack())
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.AttackGentlemanCost))
			return false;
		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if ((PlayerTarget != nullptr) && !SceneView::IsInView(PlayerTarget, Owner.ActorCenterLocation + Owner.ActorForwardVector * 100))
			return false; // Only start attack when on screen
		float EvadeHorizontalRange = 140;
		float ToTargetX = Math::Abs(TargetComp.Target.ActorLocation.X - Owner.ActorLocation.X);
		if (ToTargetX < EvadeHorizontalRange)
			return false;
		if (!PerceptionComp.Sight.VisibilityExists(Owner, TargetComp.Target, CollisionChannel = ECollisionChannel::WeaponTraceEnemy))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.AttackDuration && NumFiredProjectiles >= Settings.LemonAttackBurstNumber)
			return true;
		
		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		
		
		GentCostComp.ClaimToken(this, Settings.AttackGentlemanCost);

		NumFiredProjectiles = 0;
		NextFireTime = Time::GameTimeSeconds + Settings.AttackTelegraphDuration;

		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Weapon, Settings.AttackTelegraphDuration));
		AnimComp.bIsAiming = true;
		
		FVector WeaponLoc = Weapon.WorldLocation;
		FVector AimDir = (TargetLoc - WeaponLoc).GetSafeNormal();
		FRotator LocalAimRot = Owner.ActorTransform.InverseTransformVector(AimDir).Rotation();
		AnimComp.AimPitch.Apply(LocalAimRot.Pitch, this);
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this);

		Cooldown.Set(Settings.AttackCooldown + Math::RandRange(-0.25, 0.25));
		AnimComp.AimPitch.Clear(this);
		AnimComp.bIsAiming = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Update aimpitch continually to prevent AnimComp.Update() to override.
		TargetLoc = TargetComp.Target.ActorCenterLocation;
		FVector AimDir = (TargetLoc - Weapon.WorldLocation).GetSafeNormal();
		FRotator LocalAimRot = Owner.ActorTransform.InverseTransformVector(AimDir).Rotation();
		AnimComp.AimPitch.Apply(LocalAimRot.Pitch, this);

		if(NumFiredProjectiles < Settings.LemonAttackBurstNumber && NextFireTime < Time::GameTimeSeconds)
		{
			FireProjectile();			
			NextFireTime += Settings.AttackDuration / float(Settings.LemonAttackBurstNumber);
			if (NumFiredProjectiles >= Settings.LemonAttackBurstNumber)
				NextFireTime += BIG_NUMBER;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void FireProjectile()
	{
		NumFiredProjectiles++;		
		FVector WeaponLoc = Weapon.WorldLocation;
		FVector ToTarget = (TargetLoc - WeaponLoc).GetSafeNormal();
		FVector AimDir(Weapon.UpVector.X, ToTarget.Y, Weapon.UpVector.Z); // Use AimDir in XZ-plane, but aim towards player since launcher is offset from center of sidescroller spline.

		UBasicAIProjectileComponent Projectile = Weapon.Launch(AimDir * Settings.AttackProjectileSpeed);
		Projectile.Damage = Settings.LemonAttackDamage;

		UBasicAIHomingProjectileComponent HomingComp = UBasicAIHomingProjectileComponent::Get(Projectile.Owner);
		if (HomingComp != nullptr)
			HomingComp.Target = TargetComp.Target;
		
		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Weapon, NumFiredProjectiles, Settings.LemonAttackBurstNumber));
	}
	
} 