struct FIslandTurretronAttackParams
{
	float TimeBetweenShotsInBurst = 0.0;
	int NumShotsInBurst = 0;
}

class UIslandTurretronAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

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
	int FiredProjectiles = 0;
	bool bIsLeftNext = false;
	FVector TargetLoc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
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

		AnimComp.bIsAiming = true;
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
		if (Super::ShouldActivate() == false)
			return false;
		if (!WantsToAttack())
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.GentlemanCost))
			return false;

 		//Random time offset for nicer audio
		Params.TimeBetweenShotsInBurst = Settings.TimeBetweenBurstProjectiles * Math::RandRange(0.9, 1.1);
		Params.NumShotsInBurst = Settings.ProjectileAmount + Math::RandRange(-Settings.ProjectileAmountDeviationRange, Settings.ProjectileAmountDeviationRange);
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
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

		FiredProjectiles = 0;
		CurrentTimeBetweenShotsInBurst = Params.TimeBetweenShotsInBurst;
		CurrentNumProjectilesInBurst = Params.NumShotsInBurst;

		UBasicAIAnimationFeatureAdditiveShooting ShootingFeature = Cast<UBasicAIAnimationFeatureAdditiveShooting>(AnimComp.GetFeatureByClass(UBasicAIAnimationFeatureAdditiveShooting));
		if ((ShootingFeature != nullptr) && (ShootingFeature.SingleShot != nullptr))
			Owner.PlayAdditiveAnimation(FHazeAnimationDelegate(), ShootingFeature.SingleShot);

		GentCostComp.ClaimToken(this, Settings.GentlemanCost);
		UIslandTurretronEffectHandler::Trigger_OnStartTelegraphing(Owner, FIslandTurretronTelegraphingParams(WeaponLeft, WeaponRight, Owner.ActorLocation));
		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(WeaponLeft, Settings.TelegraphDuration));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this, Settings.AttackTokenCooldown, Settings.AttackTokenPersonalCooldown);
		bHasStoppedTelegraphing = false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (this.IsActive())
			return;

		// Rotate barrels
		if (FiredProjectiles >= CurrentNumProjectilesInBurst && BarrelRotationSpeed.Value > KINDA_SMALL_NUMBER)
		{
			BarrelRotationSpeed.AccelerateTo(0, Settings.TelegraphDuration, DeltaTime); // Stopping

			PivotBarrelLeft.AddLocalRotation(FRotator(0,0, -BarrelRotationSpeed.Value * DeltaTime));
			PivotBarrelRight.AddLocalRotation(FRotator(0,0, BarrelRotationSpeed.Value * DeltaTime));
		}		
	}

	bool bHasStoppedTelegraphing = false;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Rotate barrels
		if (FiredProjectiles < CurrentNumProjectilesInBurst)
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
			StumbleClosebyPlayer(); // Stumble on first fired projectile.
		}


		// Fire and draft version of kickback
		if(FiredProjectiles < CurrentNumProjectilesInBurst && (FiredTime == 0 || Time::GetGameTimeSince(FiredTime) > CurrentTimeBetweenShotsInBurst))
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
		else if (FiredProjectiles == CurrentNumProjectilesInBurst)
		{
			// Reset positions after burst has finished
			PivotBarrelRight.SetRelativeLocation(InitialBarrelRightLocalLocation);
			PivotBarrelLeft.SetRelativeLocation(InitialBarrelLeftLocalLocation);
		}
		
		// Let barrel rotation get to rest before deactivating
		if(FiredProjectiles >= CurrentNumProjectilesInBurst)
		{
			float Duration = Settings.LaunchInterval - ActiveDuration + Math::RandRange(0, 0.25);
			Cooldown.Set(Duration);
		}
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

		// Add scatter
		FRotator Scatter; 
		Scatter.Yaw = Math::RandRange(-Settings.AttackScatterYaw, Settings.AttackScatterYaw);
		Scatter.Pitch = Math::RandRange(-Settings.AttackScatterPitch, Settings.AttackScatterPitch);
		AimDir = Scatter.RotateVector(AimDir);

		Weapon.Launch(AimDir * Settings.LaunchSpeed);

		FiredProjectiles++;
		FiredTime = Time::GetGameTimeSeconds();
		bIsLeftNext = !bIsLeftNext;

		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Weapon, FiredProjectiles, CurrentNumProjectilesInBurst));
	}

	private TPerPlayer<bool> HasHitPlayers;
	// Quick and dirty fix. This is for handling the case when player is hiding between the barrels. This is especially important in sidescroller.
	private void StumbleClosebyPlayer()
	{		
		for (AHazePlayerCharacter Player : Game::Players)
		{
			HasHitPlayers[Player] = false; // reset bool
			
			// Deal damage and apply stumble
			if (IsPlayerCloseToMuzzles(Player))
			{
				HasHitPlayers[Player] = true;
				Player.DealTypedDamage(Owner, 0.1, EDamageEffectType::ProjectilesSmall, EDeathEffectType::ProjectilesSmall);

				FVector StumbleDir = (Player.ActorLocation - Owner.ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector);
				FStumble Stumble;
				Stumble.Duration = 0.3; // Settings.StumbleDuration
				Stumble.Move = StumbleDir * 200; // Settings.StumbleDuration				
				Player.ApplyStumble(Stumble);
				Player.SetActorRotation((-Stumble.Move).ToOrientationQuat());
			}
		}
	}

	private bool IsPlayerCloseToMuzzles(AHazePlayerCharacter Player)
	{
		float Dist = 250;
		const float DistSquared = Dist * Dist;
		FVector CenterWeaponLocation = (WeaponLeft.WorldLocation + WeaponRight.WorldLocation) * 0.5;
		FVector AimDir = WeaponLeft.ForwardVector;

		if (CenterWeaponLocation.DistSquared(Player.ActorCenterLocation) < DistSquared)
		{
			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
			Trace.UseLine();
			Trace.IgnoreActor(Player.GetOtherPlayer());			

			FHitResult Hit = Trace.QueryTraceSingle(CenterWeaponLocation, CenterWeaponLocation + AimDir * Dist);
			AHazePlayerCharacter HitPlayer = Cast<AHazePlayerCharacter>(Hit.Actor);
			if (HitPlayer == Player)
				return true;
		}

		return false;
	}


}

