class UEnforcerShotgunAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	const FName WeaponTag = n"EnforcerWeaponShotgun";
	default CapabilityTags.Add(WeaponTag);
	default CapabilityTags.Add(n"Attack");

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UEnforcerShotgunComponent Weapon;
	UBasicAIHealthComponent HealthComp;
	private FVector AimTargetOffset = FVector(0, 0, -50);
	private FVector TargetLocation;
	private AHazeActor Target;

	UEnforcerShotgunSettings ShotgunSettings;
	float ShootTime = BIG_NUMBER;
	float LaunchTime = BIG_NUMBER;
	int NumShots = 0;
	float EndTime = BIG_NUMBER;

	UAnimSequence ShootingAnim;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		// Mesh is temporarily scaled
		AimTargetOffset.Z *= UHazeCharacterSkeletalMeshComponent::Get(Owner).GetWorldScale().Z;
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		Weapon = UEnforcerShotgunComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		if (Weapon == nullptr)
		{
			UBasicAIWeaponWielderComponent WielderComp = UBasicAIWeaponWielderComponent::Get(Owner);
			if (WielderComp != nullptr) 
			{
				if (WielderComp.Weapon != nullptr)
					Weapon = UEnforcerShotgunComponent::Get(WielderComp.Weapon);
				WielderComp.OnWieldWeapon.AddUFunction(this, n"OnWieldWeapon");
			}
			if(Weapon == nullptr)
			{
				// You can't block yourself using yourself as instigator, will need to use a name
				Owner.BlockCapabilities(WeaponTag, FName(GetPathName()));
			}
		}

		ShotgunSettings = UEnforcerShotgunSettings::GetSettings(Owner);

		AnimComp.bIsAiming = true;

		UBasicAIAnimationFeatureAdditiveShooting ShootingFeature = Cast<UBasicAIAnimationFeatureAdditiveShooting>(AnimComp.GetFeatureByClass(UBasicAIAnimationFeatureAdditiveShooting));
		if (ShootingFeature != nullptr)
			ShootingAnim = ShootingFeature.SingleShot;
	}

	UFUNCTION()
	private void OnWieldWeapon(ABasicAIWeapon WieldedWeapon)
	{
		if (WieldedWeapon == nullptr)
			return;
		UEnforcerShotgunComponent NewWeapon = UEnforcerShotgunComponent::Get(WieldedWeapon);
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
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, ShotgunSettings.MinimumAttackRange))
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
		if(!GentCostQueueComp.IsNext(this) && (ShotgunSettings.GentlemanCost != EGentlemanCost::None))
			return false;
		if(!GentCostComp.IsTokenAvailable(ShotgunSettings.GentlemanCost))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		GentCostComp.ClaimToken(this, ShotgunSettings.GentlemanCost);
				
		ShootTime = ShotgunSettings.ShootInterval;
		LaunchTime = BIG_NUMBER;
		NumShots = 0;
		EndTime = BIG_NUMBER;
		Target = TargetComp.Target;

		UEnforcerWeaponEffectHandler::Trigger_OnTelegraph(Weapon.WeaponActor, FEnforcerWeaponEffectTelegraphData(Weapon.GetLaunchLocation(), ShotgunSettings.LaunchDelay));
		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Weapon, ShotgunSettings.LaunchDelay));
		UEnforcerEffectHandler::Trigger_OnTelegraphShooting(Owner, FEnforcerEffectOnTelegraphData(ShotgunSettings.LaunchDelay));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this, ShotgunSettings.AttackTokenCooldown);
		UEnforcerWeaponEffectHandler::Trigger_OnStopTelegraph(Weapon.WeaponActor);
		UEnforcerWeaponEffectHandler::Trigger_OnStopAnticipation(Weapon.WeaponActor);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > ShootTime)
		{		
			UEnforcerWeaponEffectHandler::Trigger_OnStopTelegraph(Weapon.WeaponActor);
			UEnforcerWeaponEffectHandler::Trigger_OnAnticipation(Weapon.WeaponActor, FEnforcerWeaponEffectTelegraphData(Weapon.GetLaunchLocation(), ShotgunSettings.LaunchDelay));

			// Start firing off a shot
			if (ShootingAnim != nullptr)
				Owner.PlayAdditiveAnimation(FHazeAnimationDelegate(), ShootingAnim, AdditiveType = EHazeAdditiveType::HazeAdditiveType_MeshSpace);
			LaunchTime = ActiveDuration + ShotgunSettings.LaunchDelay;
			TargetLocation = Target.FocusLocation;

			NumShots++;
			if (NumShots < ShotgunSettings.NumShots)
			{
				ShootTime = ActiveDuration + ShotgunSettings.ShootInterval;
			}
			else 
			{
				// This was the final shot in salvo
				ShootTime = BIG_NUMBER;
				EndTime = ActiveDuration + ShotgunSettings.ShootInterval;
				UEnforcerEffectHandler::Trigger_OnPostFire(Owner);
			} 
		}

		if(LaunchTime == BIG_NUMBER)
			DestinationComp.RotateTowards(Target);

		if (ActiveDuration > LaunchTime)
			Launch();		

		if (ActiveDuration > EndTime)
			Cooldown.Set(ShotgunSettings.SalvoInterval - ActiveDuration);
	}

	private void Launch()
	{
		// Launch projectile at predicted location
		LaunchTime = BIG_NUMBER;
		FVector WeaponLoc = Weapon.GetLaunchLocation();
		FVector TargetLoc = TargetLocation + AimTargetOffset;
		float PredictionTime = WeaponLoc.Distance(TargetLoc) / Math::Max(100.0, ShotgunSettings.LaunchSpeed);
		FVector PredictedTargetLoc = TargetLoc + Target.ActorVelocity * PredictionTime * 0.5;
		FRotator AimRot = (PredictedTargetLoc - WeaponLoc).Rotation();

		UEnforcerWeaponEffectHandler::Trigger_OnLaunch(Weapon.WeaponActor, FEnforcerWeaponEffectLaunchParams(NumShots, ShotgunSettings.NumShots, WeaponLoc));
		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Weapon, NumShots, ShotgunSettings.NumShots));
		UEnforcerEffectHandler::Trigger_OnShotFired(Owner);

		for(int i = 0; i < ShotgunSettings.BulletAmount; ++i)
		{
			// Introduce scatter
			// TODO: This needs networking!
			FRotator Scatter; 
			if(ShotgunSettings.ScatterYawSpacing)
			{
				Scatter.Yaw = ShotgunSettings.ScatterYaw * Math::Lerp(-1.0, 1.0, float(i) / ShotgunSettings.BulletAmount);
			}
			else
			{
				Scatter.Yaw = Math::RandRange(-1.0, 1.0) * ShotgunSettings.ScatterYaw;
			}
			
			Scatter.Pitch = Math::RandRange(ShotgunSettings.ScatterPitchMin, ShotgunSettings.ScatterPitchMax);
			FVector ScatteredAimDir = Scatter.Compose(AimRot).Vector();

			UBasicAIProjectileComponent Projectile = Weapon.Launch(ScatteredAimDir * ShotgunSettings.LaunchSpeed);
			AEnforcerShotgunProjectile ShotgunProjectile = Cast<AEnforcerShotgunProjectile>(Projectile.Owner);
			ShotgunProjectile.Fire(Owner);
		}		
	}
}