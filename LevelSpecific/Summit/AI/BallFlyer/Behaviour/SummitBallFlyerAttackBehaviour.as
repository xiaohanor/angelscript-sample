class USummitBallFlyerAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USummitBallFlyerSettings Settings;

	UGentlemanCostComponent GentCostComp;
	UBasicAIHealthComponent HealthComp;
	UBasicAINetworkedProjectileLauncherComponent Launcher;
	UHazeCapsuleCollisionComponent Capsule;

	float LaunchPitch;
	float LaunchYaw;
	float LaunchYawDelta;

	float DeployProjectileTime;
	int NumDeployedProjectiles;

	float LaunchProjectileTime;
	int NumLaunchedProjectiles;
	TArray<ASummitBallFlyerProjectile> DeployedProjectiles;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitBallFlyerSettings::GetSettings(Owner);
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::GetOrCreate(Owner); 
		Launcher = UBasicAINetworkedProjectileLauncherComponent::Get(Owner);
		Capsule = Cast<AHazeCharacter>(Owner).CapsuleComponent;

		// Set up projectiles for immediate use on remote side in network. 
		// Allow for one flight of missiles in the air when a second is launched.
		Launcher.PrepareProjectiles(Settings.AttackNumber * 2); 
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;

		AHazeActor Target = TargetComp.Target;
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		if (!Owner.ActorLocation.IsWithinDist(TargetLoc, Settings.AttackMaxRange))
			return false;
		if (Owner.ActorLocation.IsWithinDist(TargetLoc, Settings.AttackMinRange))
			return false;

		// Ignore queue, always attack if possible
		if(!GentCostComp.IsTokenAvailable(Settings.AttackGentlemanCost))
			return false;

		// Check if target is looking near us
		FVector TargetFwd = Target.ActorForwardVector;
		FVector BottomLoc = Capsule.WorldLocation - Capsule.UpVector * Capsule.ScaledCapsuleHalfHeight; 
		FVector TopLoc = Capsule.WorldLocation + Capsule.UpVector * Capsule.ScaledCapsuleHalfHeight; 
		FVector TargetPassByLoc, CapsuleCenterLoc;
		Math::FindNearestPointsOnLineSegments(BottomLoc, TopLoc, TargetLoc, Target.ActorLocation + TargetFwd * 1000000.0, CapsuleCenterLoc, TargetPassByLoc);
		if (!TargetPassByLoc.IsWithinDist(CapsuleCenterLoc, Capsule.ScaledCapsuleRadius))
		{
			// Not aiming at capsule, check if aiming close enough
			float MinCosAngle = Math::Cos(Math::DegreesToRadians(Settings.AttackMinAngle));
			FVector CapsuleClosestLoc = CapsuleCenterLoc + (TargetPassByLoc - CapsuleCenterLoc).GetSafeNormal() * Capsule.ScaledCapsuleRadius;
			float Dot = TargetFwd.DotProduct((CapsuleClosestLoc - TargetLoc).GetSafeNormal());
			if (Dot < MinCosAngle)
				return false; // Not aiming near us either	
		}
	
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!WantsToAttack())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;

		if (!TargetComp.HasValidTarget())
			return true;

		if (NumLaunchedProjectiles >= Settings.AttackNumber)
			return true;

		if (ActiveDuration > Settings.AttackTelegraphDuration) 
		{
			// Deactivate when target has passed us by
			FVector FromTarget = Owner.ActorLocation - TargetComp.Target.ActorLocation;
			if (TargetComp.Target.ActorForwardVector.DotProduct(FromTarget) < 0.0)
				return true; 
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		DeployProjectileTime = Time::GameTimeSeconds;
		NumDeployedProjectiles = 0;
		LaunchProjectileTime = BIG_NUMBER;
		NumLaunchedProjectiles = 0;
		GentCostComp.ClaimToken(this, Settings.AttackGentlemanCost);
		DeployedProjectiles.Empty(Settings.AttackNumber);

		// Alternate left-to-right and right-to-left arc sweeps
		float SweepDir = (LaunchYawDelta > 0.0) ? -1.0 : 1.0;
		if (Settings.AttackNumber < 2)
			LaunchYawDelta = 0.0;
		else
			LaunchYawDelta = SweepDir * (Settings.AttackYawWidth / float(Settings.AttackNumber - 1));
		FRotator ToTargetRot = (TargetComp.Target.ActorCenterLocation - Owner.ActorCenterLocation).Rotation(); 
		LaunchYaw = ToTargetRot.Yaw - SweepDir * Settings.AttackYawWidth * 0.5; 
		LaunchPitch = ToTargetRot.Pitch;

		AnimComp.RequestFeature(FeatureTagStinger::RapidFire, SubTagStingerRapidFire::RapidFire, EBasicBehaviourPriority::Medium, this);

		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Launcher, Settings.AttackTelegraphDuration + Settings.AttackDeployDuration));	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(Settings.AttackCooldown);
		GentCostComp.ReleaseToken(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if ((NumDeployedProjectiles < Settings.AttackNumber) && (Time::GameTimeSeconds > DeployProjectileTime))
		{
			// Launching projectiles will set them into a telegraphing mode
			FRotator LaunchRot;
			LaunchRot.Yaw = LaunchYaw;
			LaunchRot.Pitch = LaunchPitch + Math::RandRange(-1.0, 1.0) * Settings.AttackScatterPitch;
			UBasicAIProjectileComponent ProjComp = Launcher.Launch(FVector::ZeroVector, Owner.ActorUpVector.Rotation());
			ASummitBallFlyerProjectile Projectile = Cast<ASummitBallFlyerProjectile>(ProjComp.Owner);
			ProjComp.Target = TargetComp.Target;
			FVector DeployOffset = (FRotator(0.0, LaunchRot.Yaw, 0.0).Compose(Owner.ActorRotation.Inverse).Vector());
			DeployOffset.X *= Settings.AttackDeployDistance;
			DeployOffset.Y *= Settings.AttackDeployDistance;
			Projectile.Prepare(Launcher.LaunchLocation + Owner.ActorRotation.RotateVector(DeployOffset));
			DeployedProjectiles.Add(Projectile);

			DeployProjectileTime += (Settings.AttackDeployDuration / float(Settings.AttackNumber));
			LaunchYaw += LaunchYawDelta;
			NumDeployedProjectiles++;

			if (NumDeployedProjectiles == Settings.AttackNumber)
			{
				AnimComp.RequestFeature(FeatureTagStinger::RapidFire, SubTagStingerRapidFire::RapidFireEnd, EBasicBehaviourPriority::Medium, this);
				LaunchProjectileTime = Time::GameTimeSeconds;	
			}
		}

		if ((NumLaunchedProjectiles < DeployedProjectiles.Num()) && (Time::GameTimeSeconds > LaunchProjectileTime))
		{
			DeployedProjectiles[NumLaunchedProjectiles].Launch(1000.0, 2000.0);
			NumLaunchedProjectiles++;
			LaunchProjectileTime += (Settings.AttackDeployDuration / float(Settings.AttackNumber));

			UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Launcher, NumLaunchedProjectiles, Settings.AttackNumber));
		}


		DestinationComp.RotateTowards(TargetComp.Target);

#if EDITOR
	 	// Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(TargetComp.Target.ActorCenterLocation + FVector(0,0,400), 100, 4, FLinearColor::Purple, 10);
		}
#endif
	}
}

