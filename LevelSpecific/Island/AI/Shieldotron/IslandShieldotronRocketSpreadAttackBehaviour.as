class UIslandShieldotronRocketSpreadAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	default CapabilityTags.Add(n"RocketAttack");

	UGentlemanCostComponent GentCostComp;
	UBasicAIProjectileLauncherComponent Weapon;
	UBasicAIHealthComponent HealthComp;

	UIslandShieldotronSettings ShieldotronSettings;

	FVector InitialTargetLoc;
	FVector CurrentAimCenterDir;

	float NextFireTime = 0.0;	
	int NumBurstProjectiles = 1;
	int NumFiredProjectiles = 0;
	bool bHasTriggeredTelegraph = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		Weapon = UBasicAIProjectileLauncherComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		
		ShieldotronSettings = UIslandShieldotronSettings::GetSettings(Owner);
		NumBurstProjectiles = ShieldotronSettings.RocketSpreadAttackBurstNumber;	
	}

	bool WantsToAttack() const
	{
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;		
		if (!TargetComp.HasValidTarget())
			return false;
		if (!TargetComp.HasGeometryVisibleTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, ShieldotronSettings.RocketSpreadAttackMaxRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, ShieldotronSettings.RocketSpreadAttackMinRange))
			return false;
				
		// Only launch rocket when in camera view of target
		FVector FromTarget = (Owner.ActorCenterLocation - TargetComp.Target.ActorCenterLocation);
		FromTarget.Z = 0.0;
		FromTarget.Normalize();
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if (Player != nullptr)
		{
			FVector ViewYawDir = FRotator(0.0, Player.ViewRotation.Yaw, 0.0).Vector();
			//Debug::DrawDebugLine(Player.ActorLocation, Player.ActorLocation + ViewYawDir * 300, Duration = 2.0);
			//Debug::DrawDebugLine(Player.ActorLocation, Player.ActorLocation + FromTarget * 300, Duration = 2.0, LineColor = FLinearColor::Red);
			if (ViewYawDir.DotProduct(FromTarget) < 0.707) // 45 degrees
				return false;
			//Debug::DrawDebugLine(Player.ActorLocation, Player.ActorLocation + FromTarget * 300, Duration = 2.0, LineColor = FLinearColor::Green);
		}
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!ShieldotronSettings.bHasRocketSpreadAttack)
			return false;
		if (!WantsToAttack())
			return false;
		if(!GentCostComp.IsTokenAvailable(ShieldotronSettings.AttackGentlemanCost))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > ShieldotronSettings.RocketSpreadAttackDuration + ShieldotronSettings.AttackTelegraphDuration && NumFiredProjectiles >= NumBurstProjectiles)
			return true;
		
		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		
		
		GentCostComp.ClaimToken(this, ShieldotronSettings.AttackGentlemanCost);

		NumFiredProjectiles = 0;
		NextFireTime = Time::GameTimeSeconds + ShieldotronSettings.AttackTelegraphDuration + Math::RandRange(0.0, 0.25);
		
		AnimComp.bIsAiming = true;
		Owner.BlockCapabilities(n"DefaultAim", this);
		//NumBurstProjectiles = (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, ShieldotronSettings.MortarAttackMinRange)) ? ShieldotronSettings.AttackCloseRangeBurstNumber : ShieldotronSettings.AttackBurstNumber;
		NumBurstProjectiles = 6;
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

		Cooldown.Set(ShieldotronSettings.AttackCooldown + Math::RandRange(-0.25, 0.25));
		// Always aiming
		// AnimComp.bIsAiming = false;
		Owner.UnblockCapabilities(n"DefaultAim", this);
		AnimComp.AimPitch.Clear(this);
		AnimComp.AimYaw.Clear(this);
		bHasTriggeredTelegraph = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > ShieldotronSettings.AttackTelegraphDuration - 0.25 && !bHasTriggeredTelegraph)
		{
			UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Weapon, ShieldotronSettings.AttackTelegraphDuration));
			UIslandShieldotronEffectHandler::Trigger_OnRocketAttackTelegraphStart(Owner, FIslandShieldotronRocketAttackTelegraphParams(Weapon));
			bHasTriggeredTelegraph = true;
		}
		if (ActiveDuration < ShieldotronSettings.AttackTelegraphDuration)
			return;

		if(NumFiredProjectiles < NumBurstProjectiles && NextFireTime < Time::GameTimeSeconds)
		{
			FireProjectile();			
			NextFireTime += ShieldotronSettings.RocketSpreadAttackDuration / float(NumBurstProjectiles);
			if (NumFiredProjectiles >= NumBurstProjectiles)
				NextFireTime += BIG_NUMBER;
			//AnimComp.RequestFeature(FeatureTagIslandSecurityMech::BullitShot, EBasicBehaviourPriority::Medium, this);
		}
		else
			AnimComp.ClearFeature(this);
	}

	UFUNCTION(NotBlueprintCallable)
	private void FireProjectile()
	{
		FVector AimDir = CalculateAimDir(); //Weapon.UpVector;
		//Debug::DrawDebugArrow(Weapon.WorldLocation, Weapon.WorldLocation + AimDir * 100, 5.0, Duration = 2.0);
		NumFiredProjectiles++;
		FVector LaunchVelocity = AimDir * ShieldotronSettings.AttackProjectileLaunchSpeed;
		LaunchVelocity += Owner.ActorVelocity;
		UBasicAIProjectileComponent Projectile = Weapon.Launch(LaunchVelocity * 2.0);
		
		UBasicAIHomingProjectileComponent HomingComp = UBasicAIHomingProjectileComponent::Get(Projectile.Owner);
		if (HomingComp != nullptr && TargetComp.HasValidTarget())
		{
			HomingComp.Target = TargetComp.Target;
			//Cast<AIslandShieldotronRocketProjectile>(Projectile.Owner).Target = TargetComp.Target;
			Cast<AIslandShieldotronRocketProjectile>(Projectile.Owner).TargetGroundLocation = TargetComp.Target.ActorLocation;
			Cast<AIslandShieldotronRocketProjectile>(Projectile.Owner).HomingStrength = ShieldotronSettings.RocketHomingStrength * 0.25;
		}

		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Weapon, NumFiredProjectiles, NumBurstProjectiles));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnLaunchRocketAttack(Game::Zoe, FIslandShieldotronRocketAttackPlayerEventData(Owner, TargetComp.Target));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnLaunchRocketAttack(Game::Mio, FIslandShieldotronRocketAttackPlayerEventData(Owner, TargetComp.Target));
	}

	FVector CalculateAimDir()
	{
		FVector AimDir;
		float Angle = 30.0;
		float AngleSteps = (2 *Angle) / (NumBurstProjectiles - 1); // Assumes at least three in burst.
		FVector RightVector = Owner.ActorUpVector.CrossProduct(CurrentAimCenterDir).GetSafeNormal(); 
		AimDir = CurrentAimCenterDir.RotateTowards(RightVector * -1.0, Angle);
		AimDir = AimDir.RotateTowards(RightVector, NumFiredProjectiles * AngleSteps);		
		return AimDir;
	}

	void UpdateAnimationAimSpace(FVector AimDir)
	{
		FVector AimDirProjVertical = CurrentAimCenterDir.VectorPlaneProject(Owner.ActorRightVector).GetSafeNormal();
		float PitchSign = AimDirProjVertical.DotProduct(Owner.ActorUpVector) > 0 ? 1.0 : -1.0;  // Up is positive, down is negative
		float AimPitchAngle = Math::DotToDegrees(AimDirProjVertical.DotProduct(Owner.ActorForwardVector));
		AnimComp.AimPitch.Apply(PitchSign * AimPitchAngle, this, EInstigatePriority::High);
		//AnimComp.AimPitch.Apply(-30, this, EInstigatePriority::High);

		FVector AimDirProjHorizontal = AimDir.VectorPlaneProject(Owner.ActorUpVector).GetSafeNormal();
		float YawSign = AimDirProjHorizontal.DotProduct(Owner.ActorRightVector) < 0 ? 1.0 : -1.0; // Left is positive, right is negative
		float AimYawAngle = Math::DotToDegrees(AimDirProjHorizontal.DotProduct(Owner.ActorForwardVector));
		AnimComp.AimYaw.Apply(YawSign * AimYawAngle, this, EInstigatePriority::High);
	}


} 