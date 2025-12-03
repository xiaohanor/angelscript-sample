class UMeltdownGlitchShootingFireCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"GlitchShooting");

	default TickGroup = EHazeTickGroup::Movement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UMeltdownGlitchShootingUserComponent UserComp;
	UMeltdownGlitchShootingSettings Settings;
	UPlayerAimingComponent AimingComp;
	UPlayerMovementComponent MoveComp;
	UHazeActorLocalSpawnPoolComponent ProjectilePool;
	UMeltdownGlitchShootingCrosshair Crosshair;

	bool bCharging = false;
	float Timer = 0.0;
	float LastTapTime = 0.0;
	float LastImpulseTime;

	float FFTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UMeltdownGlitchShootingUserComponent::Get(Player);
		Settings = UMeltdownGlitchShootingSettings::GetSettings(Player);
		AimingComp = UPlayerAimingComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);

		UserComp.InitializeIndicators();
		ProjectilePool = HazeActorLocalSpawnPoolStatics::GetOrCreateSpawnPool(UserComp.ProjectileClass, Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (MoveComp.HasImpulse())
			LastImpulseTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!IsActioning(ActionNames::WeaponFire))
			return false;
		if (!MoveComp.IsOnAnyGround() && Time::GetGameTimeSince(LastImpulseTime) < 0.6)
			return false;
		if (Player.IsAnyCapabilityActive(n"Dash"))
			return false;
		if (DeactiveDuration < Settings.ChargeCooldown - Timer)
			return false;
		if (MoveComp.HasImpulse())
			return false;
		if (!UserComp.bGlitchShootingActive)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!UserComp.bGlitchShootingActive)
			return true;
		if (!IsActioning(ActionNames::WeaponFire) && ActiveDuration > Settings.ChargeDuration)
			return true;
		if (Player.IsAnyCapabilityActive(n"Dash"))
			return true;
		if (MoveComp.HasImpulse())
			return true;
		// if (Time::GetGameTimeSince(LastTapTime) > Settings.RequiredTapInterval && !IsActioning(ActionNames::WeaponFire ))
		// 	return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Crosshair = Cast<UMeltdownGlitchShootingCrosshair>(AimingComp.GetCrosshairWidget(UserComp));
		if (Crosshair != nullptr)
			Crosshair.BP_OnStartFiring();

		bCharging = true;
		Timer = 0.0;
		FFTimer = 0.0;
		LastTapTime = Time::GameTimeSeconds;

		UserComp.WeaponVisibility.Apply(true, this);
		UserComp.bIsShooting = true;
	}

	USceneComponent GetProjectileTarget(FVector& OutLocation)
	{
		FAimingResult AimTarget = AimingComp.GetAimingTarget(UserComp);

		FVector Target = AimTarget.AimOrigin + AimTarget.AimDirection * Settings.AimMaxTraceLength;
		if (AimTarget.AutoAimTarget != nullptr)
		{
			OutLocation = AimTarget.AutoAimTargetPoint;
			return AimTarget.AutoAimTarget;
		}
		else
		{
			auto Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming);
			Trace.IgnorePlayers();
			Trace.UseLine();

			FHitResult Hit = Trace.QueryTraceSingle(AimTarget.AimOrigin, Target);
			if (Hit.bBlockingHit)
			{
				OutLocation = Hit.ImpactPoint;
				return Hit.Component;
			}
		}

		OutLocation = Target;
		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Crosshair != nullptr)
			Crosshair.BP_OnStopFiring();
		Player.ClearCameraSettingsByInstigator(this);
		UserComp.WeaponVisibility.Clear(this);
		UserComp.bIsShooting = false;
	}

	void FinishCharging()
	{
		bCharging = false;

		// if(Settings.ProjectileType == EMeltdownGlitchProjectileType::Missile)
		// 	Player.PlayCameraShake(UserComp.ChargedShake, this);

		Player.PlayForceFeedback(UserComp.ChargedForceFeedback, false, false, this);
	}

	void FireProjectiles()
	{
		
		for (int i = 0; i < Settings.ProjectileCount; ++i)
		{
			TSubclassOf<AMeltdownGlitchShootingProjectile> ProjectileClass = UserComp.ProjectileClass;
			FVector Offset;

			if (Settings.ProjectileType == EMeltdownGlitchProjectileType::Rocket)
			{
				ProjectileClass = UserComp.ProjectileClass_Rocket;
			}
			else if (Settings.ProjectileType == EMeltdownGlitchProjectileType::Missile)
			{
				ProjectileClass = UserComp.ProjectileClass_Missile;
			}
			else
			{
				if (Settings.ProjectileCount >= 2)
				{
					if (Settings.ProjectileCount % 2 == 0)
						Offset += Player.ActorRightVector * (Math::FloorToFloat(i / 2.0) + 0.5) * 150.0;
					else if (i > 0)
						Offset += Player.ActorRightVector * (Math::CeilToFloat(i / 2.0)) * 150.0;
					if (i % 2 == 1)
						Offset *= -1.0;
				}
			}

			auto Projectile = Cast<AMeltdownGlitchShootingProjectile>(ProjectilePool.Spawn(FHazeActorSpawnParameters()));
			Projectile.Speed = Settings.ProjectileInitialSpeed;
			Projectile.Acceleration = Settings.ProjectileAcceleration;
			Projectile.MaxSpeed = Settings.ProjectileMaxSpeed;
			Projectile.OwningPlayer = Player;
			Projectile.Damage = Settings.ProjectileDamage;
			Projectile.AimTargetComponent = GetProjectileTarget(Projectile.AimTargetLocation);
			Projectile.ProjectileIndex = i;
			Projectile.ProjectileType = Settings.ProjectileType;
			Projectile.ProjectilePool = ProjectilePool;
			Projectile.Initialize();
			Projectile.AttachToComponent(Player.Mesh, Settings.ProjectileSpawnSocket);
			Projectile.SetActorRelativeLocation(Settings.ProjectileSpawnOffset);
			Projectile.ActorLocation += Offset;
			Projectile.ShootOffset = Offset;

			FVector Forward = ((Projectile.AimTargetLocation + Offset) - Projectile.ActorLocation).GetSafeNormal();
			if (Settings.FiringSpreadConeAngle > 0)
			{
				float HalfConeAngleRad = Math::DegreesToRadians(Settings.FiringSpreadConeAngle) * 0.5;
				Forward = Math::VRandCone(Forward, HalfConeAngleRad);
			}

			Projectile.SetActorRotation(FRotator::MakeFromX(Forward));

			Projectile.ShootDirection = Forward;
			Projectile.Fire();

			FMeltdownGlitchProjectileFireEffectParams EffectParams;
			EffectParams.FireLocation = Projectile.ActorLocation;
			EffectParams.FireDirection = Forward;
			UMeltdownGlitchShootingEffectHandler::Trigger_OnProjectileFired(Player, EffectParams);

		}

		auto FlyingComp = UMeltdownBossFlyingComponent::Get(Player);
		if (FlyingComp != nullptr && FlyingComp.bIsFlying)
		{
			FlyingComp.KnockbackImpulse += Settings.FlyingKnockbackImpulse;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (WasActionStarted(ActionNames::WeaponFire))
			LastTapTime = Time::GameTimeSeconds;

		Timer += DeltaTime;

		if (bCharging)
		{
			if (Timer >= Settings.ChargeDuration)
			{
				FinishCharging();
				FireProjectiles();

				Timer -= Settings.ChargeDuration;
			}
		}
		else
		{
			if (Timer >= Settings.FireInterval)
			{
				// if(Settings.ProjectileType == EMeltdownGlitchProjectileType::Missile)
				// 	Player.PlayCameraShake(UserComp.FireShake, this);
				

				FireProjectiles();

				Timer -= Settings.FireInterval;
			}

			FFTimer += DeltaTime;
			if (FFTimer >= 0.3)
			{
				Player.PlayForceFeedback(UserComp.FireForceFeedback, false, false, this);
				Player.PlayCameraShake(UserComp.FireShake,this, 0.3);
				FFTimer = 0.0;
			}

			Player.SetFrameForceFeedback(0.05, 0.05, 0.0, 0.0);
		}

		if (Player.Mesh.CanRequestOverrideFeature())
			Player.Mesh.RequestOverrideFeature( n"GlitchWeaponStrafe", this);
	}
};