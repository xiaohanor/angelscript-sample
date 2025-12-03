class USkylineTurretSweepAttackBehaviour : UBasicBehaviour
{
	default CapabilityTags.Add(n"Sweep");
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	ASkylineHighwayBossVehicleArenaCenter Center;

	UBasicAIProjectileLauncherComponent WeaponLeft;
	UBasicAIProjectileLauncherComponent WeaponRight;

	USceneComponent PivotBarrelLeft;
	USceneComponent PivotBarrelRight;
	FVector InitialBarrelLeftLocalLocation;
	FVector KickbackOffset;
	FVector InitialBarrelRightLocalLocation;

	UBasicAIHealthComponent HealthComp;

	USkylineTurretSettings Settings;

	float FiredTime = 0.0;
	int FiredProjectiles = 0;
	bool bIsLeftNext = false;

	bool AttackForwards;
	float AttackRange = 0;
	float AttackRangeMax = 5000;
	float AttackRangeMin = 4000;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		auto OwnerTurret = Cast<AAISkylineTurret>(Owner);
		WeaponLeft = OwnerTurret.Weapon_Left;
		WeaponRight = OwnerTurret.Weapon_Right;
		PivotBarrelLeft = OwnerTurret.Pivot_BarrelLeft;
		InitialBarrelLeftLocalLocation = PivotBarrelLeft.GetRelativeLocation();
		KickbackOffset = FVector(-1, 0, 0) * 25;
		PivotBarrelRight = OwnerTurret.Pivot_BarrelRight;
		InitialBarrelRightLocalLocation = PivotBarrelRight.GetRelativeLocation();

		Center = TListedActors<ASkylineHighwayBossVehicleArenaCenter>().Single;

		HealthComp = UBasicAIHealthComponent::Get(Owner);

		Settings = USkylineTurretSettings::GetSettings(Owner);

		AnimComp.bIsAiming = true;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(TargetComp.HasValidTarget())
			return;
		
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if(Player != nullptr)
		{
			TargetComp.SetTarget(Player.OtherPlayer);
			return;
		}

		TargetComp.SetTarget(Game::Mio);
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
		if (Owner.IsCapabilityTagBlocked(n"Attack"))
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
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		return false;
	}

	FHazeAcceleratedFloat BarrelRotationSpeed;
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		

		FiredProjectiles = 0;
		
		UBasicAIAnimationFeatureAdditiveShooting ShootingFeature = Cast<UBasicAIAnimationFeatureAdditiveShooting>(AnimComp.GetFeatureByClass(UBasicAIAnimationFeatureAdditiveShooting));
		if ((ShootingFeature != nullptr) && (ShootingFeature.SingleShot != nullptr))
			Owner.PlayAdditiveAnimation(FHazeAnimationDelegate(), ShootingFeature.SingleShot);

		USkylineTurretEffectHandler::Trigger_OnStartTelegraphing(Owner, FSkylineTurretTelegraphingParams(WeaponLeft, WeaponRight, Owner.ActorLocation, Settings.TelegraphDuration));
		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(WeaponLeft, Settings.TelegraphDuration));

		float BaseDistance = (Owner.ActorLocation - Center.ActorLocation).DotProduct(Owner.ActorForwardVector);
		AttackRangeMin = BaseDistance - 700;
		AttackRangeMax = BaseDistance + 600;
		AttackRange = AttackRangeMax;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		BarrelRotationSpeed.SnapTo(0);
		bHasStoppedTelegraphing = false;
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if(Player != nullptr)
			TargetComp.SetTarget(Player.OtherPlayer);
	}

	bool bHasStoppedTelegraphing = false;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Rotate barrels
		if(FiredProjectiles >= Settings.ProjectileAmount)
			BarrelRotationSpeed.AccelerateTo(0, Settings.RecoveryDuration, DeltaTime); // Stopping
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
			USkylineTurretEffectHandler::Trigger_OnStopTelegraphing(Owner);
		}


		// Fire and draft version of kickback
		if(FiredTime == 0 || Time::GetGameTimeSince(FiredTime) > 0.05)
		{
			FSkylineTurretProjectileData Data;

			if (bIsLeftNext) // Is it better to pass a param than use a member for crumb functions?
				Data.Weapon = WeaponLeft;
			else
				Data.Weapon = WeaponRight;
			bIsLeftNext = !bIsLeftNext;

			if(AttackForwards && AttackRange > AttackRangeMax)	
				AttackForwards = false;
			else if(!AttackForwards && AttackRange < AttackRangeMin)
				AttackForwards = true;

			FVector RightVector = Owner.AttachParentActor.ActorRightVector;
			float RangeOffset = 75;
			AttackRange += AttackForwards ? RangeOffset : -RangeOffset;
			FVector OffsetVector = bIsLeftNext ? RightVector : -RightVector;
			FVector SideOffset = OffsetVector * Math::RandRange(0, 150);
			FVector TargetLoc = Data.Weapon.LaunchLocation + Owner.AttachParentActor.ActorForwardVector * AttackRange + SideOffset;

			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
			Trace.UseLine();
			FHitResult Hit = Trace.QueryTraceSingle(TargetLoc + FVector::UpVector * 500, TargetLoc - FVector::UpVector * 500);
			if(Hit.bBlockingHit)
				TargetLoc = Hit.Location;

			Data.TargetLocation = TargetLoc;

			Data.Projectile = Data.Weapon.SpawnProjectile();
			Data.Projectile.Launcher = Data.Weapon.Wielder;
			Data.Projectile.LaunchingWeapon = this;	
			Data.Projectile.Prime();
			Data.Projectile.Owner.AttachRootComponentTo(Data.Weapon, NAME_None, EAttachLocation::KeepWorldPosition);
			Data.Weapon.OnPrimeProjectile.Broadcast(Data.Projectile);
			Data.Projectile.HazeOwner.AddActorVisualsBlock(this);

			FSkylineTurretProjectileOnTelegraphData TelegraphData;
			TelegraphData.TargetLocation = TargetLoc;
			USkylineTurretProjectileEffectHandler::Trigger_OnTelegraph(Data.Projectile.HazeOwner, TelegraphData);

			FireProjectile(Data);

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

		// Reset positions after burst has finished
		// PivotBarrelRight.SetRelativeLocation(InitialBarrelRightLocalLocation);
		// PivotBarrelLeft.SetRelativeLocation(InitialBarrelLeftLocalLocation);
		
		// Let barrel rotation get to rest before deactivating
		// if(FiredProjectiles >= Settings.ProjectileAmount && BarrelRotationSpeed.Value < KINDA_SMALL_NUMBER)
		// {
		// 	Cooldown.Set(Settings.AttackCooldown);
		// }
	}

	UFUNCTION(NotBlueprintCallable)
	private void FireProjectile(FSkylineTurretProjectileData Data)
	{
		UBasicAIProjectileComponent Projectile = Data.Projectile;
		
		Projectile.Launcher = Data.Weapon.Wielder;
		Projectile.LaunchingWeapon = this;	
		Projectile.Owner.DetachRootComponentFromParent(true);
		Data.Weapon.LastLaunchedProjectile = Projectile;
		Data.Weapon.OnLaunchProjectile.Broadcast(Projectile);

		float Gravity = 982 * 10;

		FVector LaunchVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(Data.Weapon.LaunchLocation, Data.TargetLocation, Gravity, 3000);
		Projectile.Launch(LaunchVelocity);
		Projectile.Gravity = Gravity;
		Projectile.HazeOwner.RemoveActorVisualsBlock(this);
		Projectile.TargetedLocation = Data.TargetLocation;

		FiredProjectiles++;
		FiredTime = Time::GetGameTimeSeconds();

		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Data.Weapon, FiredProjectiles, Settings.ProjectileAmount));
	}
}