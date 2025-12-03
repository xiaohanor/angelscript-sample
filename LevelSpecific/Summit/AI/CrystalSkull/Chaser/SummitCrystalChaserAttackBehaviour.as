class USummitCrystalChaserAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USummitCrystalChaserSettings ChaserSettings;

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	USummitCrystalSkullComponent FlyerComp;
	UBasicAIProjectileLauncherComponent Launcher;
	UHazeCapsuleCollisionComponent Capsule;
	USummitCrystalSkullArmourComponent ArmourComp;

	float LaunchPitch;
	float LaunchYaw;
	float LaunchYawDelta;

	float DeployProjectileTime;
	int NumDeployedProjectiles;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ChaserSettings = USummitCrystalChaserSettings::GetSettings(Owner);
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::GetOrCreate(Owner); 
		FlyerComp = USummitCrystalSkullComponent::GetOrCreate(Owner);
		Launcher = UBasicAIProjectileLauncherComponent::Get(Owner);
		Capsule = Cast<AHazeCharacter>(Owner).CapsuleComponent;
		ArmourComp = USummitCrystalSkullArmourComponent::Get(Owner);
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;

		if ((ArmourComp != nullptr) && ArmourComp.HadArmour(2.0))
			return false;

		AHazeActor Target = TargetComp.Target;
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		if (!Owner.ActorLocation.IsWithinDist(TargetLoc, ChaserSettings.ChaserAttackMaxRange))
			return false;
		if (Owner.ActorLocation.IsWithinDist(TargetLoc, ChaserSettings.ChaserAttackMinRange))
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
			float MinCosAngle = Math::Cos(Math::DegreesToRadians(ChaserSettings.ChaserAttackMinAngle));
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
		// Ignore queue, always attack if possible
		if(!GentCostComp.IsTokenAvailable(ChaserSettings.ChaserAttackGentlemanCost))
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

		if (ActiveDuration > GetFullDuration())
			return true;

		if (ActiveDuration > ChaserSettings.ChaserAttackTelegraphDuration) 
		{
			// Deactivate when target has passed us by
			FVector FromTarget = Owner.ActorLocation - TargetComp.Target.ActorLocation;
			if (TargetComp.Target.ActorForwardVector.DotProduct(FromTarget) < 0.0)
				return true; 
		}
		return false;
	}

	float GetFullDuration() const
	{
		return ChaserSettings.ChaserAttackTelegraphDuration + ChaserSettings.ChaserAttackDeployDuration;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentCostComp.ClaimToken(this, ChaserSettings.ChaserAttackGentlemanCost);
		DeployProjectileTime = Time::GameTimeSeconds;
		NumDeployedProjectiles = 0;

		// Alternate left-to-right and right-to-left arc sweeps
		float SweepDir = (LaunchYawDelta > 0.0) ? -1.0 : 1.0;
		if (ChaserSettings.ChaserAttackNumber < 2)
			LaunchYawDelta = 0.0;
		else
			LaunchYawDelta = SweepDir * (ChaserSettings.ChaserAttackYawWidth / float(ChaserSettings.ChaserAttackNumber - 1));
		FRotator ToTargetRot = (TargetComp.Target.ActorCenterLocation - Owner.ActorCenterLocation).Rotation(); 
		LaunchYaw = ToTargetRot.Yaw - SweepDir * ChaserSettings.ChaserAttackYawWidth * 0.5; 
		LaunchPitch = ToTargetRot.Pitch;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(ChaserSettings.ChaserAttackCooldown);
		GentCostComp.ReleaseToken(this, ChaserSettings.ChaserAttackTokenCooldown);
		FlyerComp.ClearVulnerable();
		FlyerComp.LastAttackTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if ((NumDeployedProjectiles < ChaserSettings.ChaserAttackNumber) && (Time::GameTimeSeconds > DeployProjectileTime))
		{
			// Launching arc projectiles will set them into a telegraphing mode, then properly launch them after telegraphing delay
			// This is handled by the ASummitCrystalSkullArcProjectile itself, but we set initial position and velocity to use when launched here.
			FRotator LaunchRot;
			LaunchRot.Yaw = LaunchYaw;
			LaunchRot.Pitch = LaunchPitch + Math::RandRange(-1.0, 1.0) * ChaserSettings.ChaserAttackScatterPitch;
			UBasicAIProjectileComponent Projectile = Launcher.Launch(LaunchRot.Vector() * ChaserSettings.ChaserAttackProjectileSpeed, Owner.ActorUpVector.Rotation());
			Projectile.Target = TargetComp.Target;
			FVector DeployOffset = (FRotator(0.0, LaunchRot.Yaw, 0.0).Compose(Owner.ActorRotation.Inverse).Vector());
			DeployOffset.X *= 500.0;
			DeployOffset.Y *= 500.0;
			Projectile.Owner.SetActorLocation(Launcher.LaunchLocation + Owner.ActorRotation.RotateVector(DeployOffset));
			DeployProjectileTime += (ChaserSettings.ChaserAttackDeployDuration / float(ChaserSettings.ChaserAttackNumber));
			LaunchYaw += LaunchYawDelta;
			NumDeployedProjectiles++;
		}

#if EDITOR
	 	// Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(TargetComp.Target.ActorCenterLocation + FVector(0,0,400), 100, 4, FLinearColor::Purple, 10);
		}
#endif
	}
}

