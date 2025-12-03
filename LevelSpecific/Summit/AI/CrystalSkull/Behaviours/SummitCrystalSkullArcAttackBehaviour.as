class USummitCrystalSkullArcAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Perception); // Do not change target while attacking

	USummitCrystalSkullSettings FlyerSettings;

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	USummitCrystalSkullComponent FlyerComp;
	USummitArcProjectileLauncher Launcher;
	UHazeCapsuleCollisionComponent Capsule;
	AHazePlayerCharacter PlayerTarget;

	float LaunchPitch;
	float LaunchYaw;
	float LaunchYawDelta;

	float DeployProjectileTime;
	int NumDeployedProjectiles;
	int NumTotalProjectiles;
	float YawWidth;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		FlyerSettings = USummitCrystalSkullSettings::GetSettings(Owner);
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::GetOrCreate(Owner); 
		FlyerComp = USummitCrystalSkullComponent::GetOrCreate(Owner);
		Launcher = USummitArcProjectileLauncher::Get(Owner);
		Capsule = Cast<AHazeCharacter>(Owner).CapsuleComponent;
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;

		if (Launcher.bSplitTargets)
		{
			// Skip attack if both players are out of range
			if (!Owner.ActorLocation.IsWithinDist(Game::Mio.ActorLocation, FlyerSettings.ArcAttackMaxRange) &&
				!Owner.ActorLocation.IsWithinDist(Game::Zoe.ActorLocation, FlyerSettings.ArcAttackMaxRange))
				return false;
		}
		else
		{
			// Single target attack
			AHazeActor Target = TargetComp.Target;
			FVector TargetLoc = TargetComp.Target.ActorLocation;
			if (!Owner.ActorLocation.IsWithinDist(TargetLoc, FlyerSettings.ArcAttackMaxRange))
				return false;
			if (Owner.ActorLocation.IsWithinDist(TargetLoc, FlyerSettings.ArcAttackMinRange))
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
				float MinCosAngle = Math::Cos(Math::DegreesToRadians(FlyerSettings.ArcAttackMinAngle));
				FVector CapsuleClosestLoc = CapsuleCenterLoc + (TargetPassByLoc - CapsuleCenterLoc).GetSafeNormal() * Capsule.ScaledCapsuleRadius;
				float Dot = TargetFwd.DotProduct((CapsuleClosestLoc - TargetLoc).GetSafeNormal());
				if (Dot < MinCosAngle)
					return false; // Not aiming near us either	
			}
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
		if(!GentCostComp.IsTokenAvailable(FlyerSettings.ArcAttackGentlemanCost))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;

		if (!TargetComp.IsValidTarget(PlayerTarget))
			return true;

		if (ActiveDuration > GetFullDuration())
			return true;

		if (!Launcher.bSplitTargets && (ActiveDuration > FlyerSettings.ArcAttackTelegraphDuration)) 
		{
			// Deactivate when target has passed us by
			FVector FromTarget = Owner.ActorLocation - PlayerTarget.ActorLocation;
			if (PlayerTarget.ActorForwardVector.DotProduct(FromTarget) < 0.0)
				return true; 
		}
		return false;
	}

	float GetFullDuration() const
	{
		return FlyerSettings.ArcAttackTelegraphDuration + FlyerSettings.ArcAttackDeployDuration;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentCostComp.ClaimToken(this, FlyerSettings.ArcAttackGentlemanCost);
		DeployProjectileTime = Time::GameTimeSeconds;
		NumDeployedProjectiles = 0;
		USummitCrystalSkullEventHandler::Trigger_OnTelegraphArcAttack(Owner);

		PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);

		NumTotalProjectiles = Math::FloorToInt(FlyerSettings.ArcAttackNumber * Launcher.ProjectilesMultiple);
		YawWidth = FlyerSettings.ArcAttackYawWidth * Launcher.ProjectilesMultiple;

		// Alternate left-to-right and right-to-left arc sweeps
		float SweepDir = (LaunchYawDelta > 0.0) ? -1.0 : 1.0;
		if (NumTotalProjectiles < 2)
			LaunchYawDelta = 0.0;
		else
			LaunchYawDelta = SweepDir * (YawWidth / float(NumTotalProjectiles - 1));
		FRotator ToTargetRot = (PlayerTarget.ActorCenterLocation - Owner.ActorCenterLocation).Rotation(); 
		LaunchYaw = ToTargetRot.Yaw - SweepDir * YawWidth * 0.5; 
		LaunchPitch = ToTargetRot.Pitch;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(FlyerSettings.ArcAttackCooldown);
		GentCostComp.ReleaseToken(this, FlyerSettings.ArcAttackTokenCooldown);
		FlyerComp.ClearVulnerable();
		FlyerComp.LastAttackTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if ((NumDeployedProjectiles < NumTotalProjectiles) && (Time::GameTimeSeconds > DeployProjectileTime))
		{
			// Launching arc projectiles will set them into a telegraphing mode, then properly launch them after telegraphing delay
			// This is handled by the ASummitCrystalSkullArcProjectile itself, but we set initial position and velocity to use when launched here.
			float Fraction = float(NumDeployedProjectiles) / float(NumTotalProjectiles);
			FRotator LaunchRot;
			LaunchRot.Yaw = LaunchYaw;
			LaunchRot.Pitch = LaunchPitch + Math::RandRange(-1.0, 1.0) * FlyerSettings.ArcAttackScatterPitch;
			FRotator LocalLaunchRot = FRotator(0.0, LaunchRot.Yaw, 0.0).Compose(Owner.ActorRotation.Inverse);
			FVector DeployOffset = LocalLaunchRot.Vector();
			DeployOffset.X *= 0.0;
			DeployOffset.Y *= 2000.0;
			DeployOffset.Z -= 1000.0 * (Math::Square(Fraction) - Fraction) * 4.0;
			FVector DeployLocation = Launcher.LaunchLocation + Owner.ActorRotation.RotateVector(DeployOffset);

			AHazePlayerCharacter Target = PlayerTarget;
			float LaunchYawOffset = Math::Sign(LaunchYawDelta) * YawWidth * (Fraction - 0.5);
			if (Launcher.bSplitTargets) 
			{
				if (Fraction > 0.5)
				{
					Target = PlayerTarget.OtherPlayer;
					LaunchYawOffset -= Math::Sign(LaunchYawDelta) * YawWidth * 0.25;
				}
				else
				{
					LaunchYawOffset += Math::Sign(LaunchYawDelta) * YawWidth * 0.25;
				}
			}

			UBasicAIProjectileComponent ProjectileComp = Launcher.Launch(FVector::ZeroVector, Owner.ActorUpVector.Rotation());
			ProjectileComp.Owner.SetActorLocation(DeployLocation);
			ProjectileComp.Target = Target;
			ASummitCrystalSkullArcProjectile ArcProjectile = Cast<ASummitCrystalSkullArcProjectile>(ProjectileComp.Owner);
			ArcProjectile.LaunchYawOffset = LaunchYawOffset;

			DeployProjectileTime += (FlyerSettings.ArcAttackDeployDuration / float(NumTotalProjectiles));
			LaunchYaw += LaunchYawDelta;
			NumDeployedProjectiles++;
		}

#if EDITOR
	 	// Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(PlayerTarget.ActorCenterLocation + FVector(0,0,400), 100, 4, FLinearColor::Purple, 10);
		}
#endif
	}
}

