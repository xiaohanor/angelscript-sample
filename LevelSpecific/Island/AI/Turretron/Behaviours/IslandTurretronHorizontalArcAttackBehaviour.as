class UIslandTurretronHorizontalArcAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	FVector InitialUpDir;
	AAIIslandTurretron Turret;

	bool bShouldPredict = false;
	bool bHasSetCurrentTargetLoc = false;
	FVector CurrentTargetLoc;


	UGentlemanCostComponent GentCostComp;
	UBasicAIProjectileLauncherComponent WeaponLeft;
	UBasicAIProjectileLauncherComponent WeaponRight;

	USceneComponent PivotBarrelLeft;
	USceneComponent PivotBarrelRight;
	FVector InitialBarrelLeftLocalLocation;
	FVector KickbackOffset;
	FVector InitialBarrelRightLocalLocation;

	UBasicAIHealthComponent HealthComp;

	UIslandTurretronSettings Settings;

	float CurrentTimeBetweenShotsInBurst = 0.0;
	int CurrentNumProjectilesInBurst = 0;

	float FiredTime = 0.0;
	int NumFiredProjectiles = 0;
	bool bIsLeftNext = false;
	FVector TargetLoc;
	FVector CurrentAimCenterDir;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		InitialUpDir = Owner.ActorUpVector;

		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		auto OwnerTurret = Cast<AAIIslandTurretron>(Owner);
		WeaponLeft = OwnerTurret.Weapon_Left;
		WeaponRight = OwnerTurret.Weapon_Right;
		PivotBarrelLeft = OwnerTurret.Pivot_BarrelLeft;
		InitialBarrelLeftLocalLocation = PivotBarrelLeft.GetRelativeLocation();
		KickbackOffset = FVector(-1, 0, 0) * 25;
		PivotBarrelRight = OwnerTurret.Pivot_BarrelRight;
		InitialBarrelRightLocalLocation = PivotBarrelRight.GetRelativeLocation();

		HealthComp = UBasicAIHealthComponent::Get(Owner);

		Settings = UIslandTurretronSettings::GetSettings(Owner);
		Turret = Cast<AAIIslandTurretron>(Owner);
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;		
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.MaxAttackRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.MinAttackRange))
			return false;
		if (BasicSettings.RangedAttackRequireVisibility && !TargetComp.HasGeometryVisibleTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandTurretronAttackParams& Params) const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.GentlemanCost))
			return false;

 		//Random time offset for nicer audio
		Params.TimeBetweenShotsInBurst = Settings.TimeBetweenBurstProjectiles * Math::RandRange(0.9, 1.1);
		Params.NumShotsInBurst = Settings.ArcProjectileAmount + Math::RandRange(-Settings.ProjectileAmountDeviationRange, Settings.ProjectileAmountDeviationRange);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		return false;
	}

	FHazeAcceleratedFloat BarrelRotationSpeed;
	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandTurretronAttackParams Params)
	{
		Super::OnActivated();

		NumFiredProjectiles = 0;
		CurrentTimeBetweenShotsInBurst = Params.TimeBetweenShotsInBurst;
		CurrentNumProjectilesInBurst = Params.NumShotsInBurst;

		UBasicAIAnimationFeatureAdditiveShooting ShootingFeature = Cast<UBasicAIAnimationFeatureAdditiveShooting>(AnimComp.GetFeatureByClass(UBasicAIAnimationFeatureAdditiveShooting));
		if ((ShootingFeature != nullptr) && (ShootingFeature.SingleShot != nullptr))
			Owner.PlayAdditiveAnimation(FHazeAnimationDelegate(), ShootingFeature.SingleShot);

		GentCostComp.ClaimToken(this, Settings.GentlemanCost);
		UIslandTurretronEffectHandler::Trigger_OnStartTelegraphing(Owner, FIslandTurretronTelegraphingParams(WeaponLeft, WeaponRight, Owner.ActorLocation));
		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(WeaponLeft, Settings.TelegraphDuration));

		CurrentAimCenterDir = (TargetComp.Target.ActorCenterLocation - Owner.ActorCenterLocation).GetSafeNormal(ResultIfZero = Owner.ActorForwardVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this, Settings.AttackTokenCooldown, Settings.AttackTokenPersonalCooldown);
		BarrelRotationSpeed.SnapTo(0);
		bHasStoppedTelegraphing = false;
	}

	bool bHasStoppedTelegraphing = false;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bShouldPredict)
			TargetDirectly(DeltaTime);
		else
			TargetPredictively(DeltaTime);

		UpdateBurstFire(DeltaTime);
	}

	void UpdateBurstFire(float DeltaTime)
	{
		// Rotate barrels
		if(NumFiredProjectiles >= CurrentNumProjectilesInBurst)
			BarrelRotationSpeed.AccelerateTo(0, Settings.TelegraphDuration, DeltaTime); // Stopping
		else
			BarrelRotationSpeed.AccelerateTo(1500, Settings.TelegraphDuration, DeltaTime); // Starting
			
		PivotBarrelLeft.AddLocalRotation(FRotator(0,0, -BarrelRotationSpeed.Value * DeltaTime));
		PivotBarrelRight.AddLocalRotation(FRotator(0,0, BarrelRotationSpeed.Value * DeltaTime));


		if(ActiveDuration < Settings.TelegraphDuration)
		{
			return;
		}
		if (!bHasStoppedTelegraphing)
		{
			bHasStoppedTelegraphing = true;
			UIslandTurretronEffectHandler::Trigger_OnStopTelegraphing(Owner);
		}


		// Fire and draft version of kickback
		if(NumFiredProjectiles < CurrentNumProjectilesInBurst && (FiredTime == 0 || Time::GetGameTimeSince(FiredTime) > CurrentTimeBetweenShotsInBurst))
		{
			FireProjectile();
			if (bIsLeftNext)
			{
				PivotBarrelLeft.SetRelativeLocation(InitialBarrelLeftLocalLocation + KickbackOffset);
				PivotBarrelRight.SetRelativeLocation(InitialBarrelRightLocalLocation);

			}
			else
			{
				PivotBarrelRight.SetRelativeLocation(InitialBarrelRightLocalLocation + KickbackOffset);
				PivotBarrelLeft.SetRelativeLocation(InitialBarrelLeftLocalLocation);

			}
		}
		else if (NumFiredProjectiles == CurrentNumProjectilesInBurst)
		{
			// Reset positions after burst has finished
			PivotBarrelRight.SetRelativeLocation(InitialBarrelRightLocalLocation);
			PivotBarrelLeft.SetRelativeLocation(InitialBarrelLeftLocalLocation);
		}
		
		// Let barrel rotation get to rest before deactivating
		if(NumFiredProjectiles >= CurrentNumProjectilesInBurst && BarrelRotationSpeed.Value < KINDA_SMALL_NUMBER)
		{
			Cooldown.Set(Settings.LaunchInterval - ActiveDuration + Math::RandRange(0, 0.5));
		}
	}

	private void TargetDirectly(float DeltaTime)
	{
		FVector TargetPlayerLoc = TargetComp.Target.ActorCenterLocation;	
			
		FVector PlayerDir = (TargetPlayerLoc - Owner.ActorCenterLocation).GetSafeNormal();
		FVector Dir;
		float Angle = 30.0;
		FVector RightVector = Turret.Mesh_Turret.GetRightVector();
		Dir = CurrentAimCenterDir.RotateTowards(RightVector * -1.0, Angle);
		//Dir = Dir.RotateTowards(PlayerDir, NumFiredProjectiles * Angle * 2.0 / float(CurrentNumProjectilesInBurst));
		Dir = Dir.RotateTowards(RightVector, NumFiredProjectiles * Angle * 2.0 / float(CurrentNumProjectilesInBurst));

		if (NumFiredProjectiles >= CurrentNumProjectilesInBurst)
			Dir = (TargetPlayerLoc - Owner.ActorCenterLocation).GetSafeNormal();

		// Ease rotation for holder
		FVector CurrentDir = Turret.Mesh_Holder.WorldRotation.Vector().GetSafeNormal();
		const float RotationSpeed = 10;
		float Delta = RotationSpeed * DeltaTime;
		CurrentDir = CurrentDir.SlerpTowards(Dir, Delta);

		Turret.Mesh_Holder.SetWorldRotation(FRotator::MakeFromZX(InitialUpDir, CurrentDir));

		// Ease rotation for gun
		FVector CurrentGunDir = Turret.Mesh_Turret.WorldRotation.Vector().GetSafeNormal();
		const float HolderRotationSpeed = 10;
		float HolderDelta = HolderRotationSpeed * DeltaTime;
		CurrentGunDir = CurrentGunDir.SlerpTowards(Dir, HolderDelta);
		RightVector = Turret.Mesh_Turret.GetRightVector();
		Turret.Mesh_Turret.SetWorldRotation(FRotator::MakeFromYX(RightVector, CurrentGunDir));
	}

	private void TargetPredictively(float DeltaTime)
	{
			FVector TargetPlayerLoc = TargetComp.Target.ActorCenterLocation;	
			if (!bHasSetCurrentTargetLoc)
				CurrentTargetLoc = TargetPlayerLoc;
			bHasSetCurrentTargetLoc = true;

			// Predict movement
			FVector TargetVelocity = Cast<AHazePlayerCharacter>(TargetComp.Target).GetRawLastFrameTranslationVelocity();
			TargetVelocity.Z = 0; // Prevents overcompensating while player is jumping
			float Distance = TargetPlayerLoc.Distance(Owner.ActorCenterLocation);
			TargetPlayerLoc += TargetVelocity.GetSafeNormal() * (Distance * (TargetVelocity.Size() / Settings.LaunchSpeed));
			
			const float LerpSpeed = 600.0;
			CurrentTargetLoc += (TargetPlayerLoc - CurrentTargetLoc).GetSafeNormal() * DeltaTime * LerpSpeed;
#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(CurrentTargetLoc, 10, LineColor = FLinearColor::Green);		
			Debug::DrawDebugSphere(TargetLoc, 10, LineColor = FLinearColor::Red);
		}			
#endif
			
			FVector Dir = (CurrentTargetLoc - Owner.ActorCenterLocation).GetSafeNormal();
			Turret.Mesh_Holder.SetWorldRotation(FRotator::MakeFromZX(InitialUpDir, Dir));

			FVector RightVector = Turret.Mesh_Holder.GetRightVector();
			Turret.Mesh_Turret.SetWorldRotation(FRotator::MakeFromYX(RightVector, Dir));
	}

	UFUNCTION(NotBlueprintCallable)
	private void FireProjectile()
	{
		UBasicAIProjectileLauncherComponent Weapon;
		if (bIsLeftNext)
			Weapon = WeaponLeft;
		else
			Weapon = WeaponRight;

		// Aim forward
		FVector AimDir = Weapon.ForwardVector;
		// FVector AimDir;
		// float Angle = 15.0;
		// AimDir = CurrentAimCenterDir.RotateTowards(FVector::LeftVector, Angle);
		// AimDir = AimDir.RotateTowards(FVector::RightVector, NumFiredProjectiles * Angle * 2.0 / float(CurrentNumProjectilesInBurst));

		// Add scatter
		FRotator Scatter; 
		Scatter.Yaw = Math::RandRange(-Settings.AttackScatterYaw, Settings.AttackScatterYaw);
		Scatter.Pitch = Math::RandRange(-Settings.AttackScatterPitch, Settings.AttackScatterPitch);
		AimDir = Scatter.RotateVector(AimDir);

		Weapon.Launch(AimDir * Settings.LaunchSpeed);

		NumFiredProjectiles++;
		FiredTime = Time::GetGameTimeSeconds();
		bIsLeftNext = !bIsLeftNext;

		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Weapon, NumFiredProjectiles, CurrentNumProjectilesInBurst));
	}
}
