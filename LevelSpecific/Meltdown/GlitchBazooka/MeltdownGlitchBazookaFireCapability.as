class UMeltdownGlitchBazookaFireCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default TickGroup = EHazeTickGroup::Movement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UMeltdownGlitchBazookaUserComponent BazookaComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerAimingComponent AimingComp;
	UMeltdownGlitchShootingUserComponent ShootingComp;
	UMeltdownGlitchShootingCrosshair Crosshair;

	UHazeActorLocalSpawnPoolComponent ProjectilePool;

	const float FireInterval = 0.5;
	float LastFireTime = 0.0;

	float LastImpulseTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BazookaComp = UMeltdownGlitchBazookaUserComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		AimingComp = UPlayerAimingComponent::Get(Player);
		ShootingComp = UMeltdownGlitchShootingUserComponent::Get(Player);
		ProjectilePool = HazeActorLocalSpawnPoolStatics::GetOrCreateSpawnPool(BazookaComp.ProjectileClass, Player);
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
		if (!MoveComp.IsOnAnyGround() && Time::GetGameTimeSince(LastImpulseTime) < 0.6)
			return false;
		if (!ShootingComp.bGlitchShootingActive)
			return false;
		if (Player.IsAnyCapabilityActive(n"Dash"))
			return false;
		if (MoveComp.HasImpulse())
			return false;
		if (IsActioning(ActionNames::PrimaryLevelAbility))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsActioning(ActionNames::PrimaryLevelAbility) && ActiveDuration >= FireInterval)
			return true;
		if (Player.IsAnyCapabilityActive(n"Dash"))
			return true;
		if (!ShootingComp.bGlitchShootingActive)
			return true;
		if (MoveComp.HasImpulse())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto CamSettings = UCameraSettings::GetSettings(Player);
		// CamSettings.IdealDistance.ApplyAsAdditive(-500, this, 1.0, EHazeCameraPriority::MAX);
		// CamSettings.PivotOffset.ApplyAsAdditive(FVector(0.0, 100.0, 0.0), this, 1.0, EHazeCameraPriority::High);

		Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		Player.BlockCapabilities(PlayerMovementTags::Dash, this);

		Player.EnableStrafe(this);
		Player.ApplyStrafeSpeedScale(this, 0.5);

		AimingComp.ApplyAimingSensitivity(this);
		ShootingComp.WeaponVisibility.Apply(true, this);
		Crosshair = Cast<UMeltdownGlitchShootingCrosshair>(AimingComp.GetCrosshairWidget(n"MeltdownGlitchBazooka"));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DisableStrafe(this);
		Player.ClearStrafeSpeedScale(this);
		AimingComp.ClearAimingSensitivity(this);
		Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
		Player.UnblockCapabilities(PlayerMovementTags::Dash, this);

		auto CamSettings = UCameraSettings::GetSettings(Player);
		CamSettings.IdealDistance.Clear(this, 2.0);
		CamSettings.PivotOffset.Clear(this, 2.0);
		ShootingComp.WeaponVisibility.Clear(this);
	}

	void Fire(FVector Source, FVector Direction)
	{
		if (Crosshair != nullptr)
			Crosshair.BP_OnStartFiring();
		LastFireTime = Time::GameTimeSeconds;
		

		FHazeActorSpawnParameters SpawnParams;
		SpawnParams.Location = Source;
		SpawnParams.Rotation = FRotator::MakeFromX(Direction);

		auto Projectile = Cast<AMeltdownGlitchBazookaProjectile>(
			ProjectilePool.Spawn(SpawnParams)
		);
		Projectile.OwningPlayer = Player; 
		Projectile.SpawnPool = ProjectilePool;
		Projectile.Fire();

		Player.PlayForceFeedback(BazookaComp.BazookaForceFeedback, false, false, this);
		Player.PlayCameraShake(BazookaComp.BazookaShake,this);

		UMeltdownGlitchBazookaGunEventHandler::Trigger_Onfired(BazookaComp.Bazooka);

		FMeltdownGlitchProjectileFireEffectParams EffectParams;
		EffectParams.FireLocation = Projectile.ActorLocation;
		EffectParams.FireDirection = Direction;
		UMeltdownGlitchShootingEffectHandler::Trigger_OnProjectileFired(Player, EffectParams);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!IsValid(BazookaComp.Bazooka))
			return;

		FAimingResult AimTarget = AimingComp.GetAimingTarget(n"MeltdownGlitchBazooka");

		FVector Source = BazookaComp.Bazooka.MuzzleLocation.WorldLocation;
		FVector Direction;

		if (AimTarget.AutoAimTarget != nullptr)
		{
			FVector Target = AimTarget.AutoAimTargetPoint;

			auto ResponseComp = UMeltdownGlitchShootingResponseComponent::Get(AimTarget.AutoAimTarget.Owner);
			if (ResponseComp != nullptr && ResponseComp.bShouldLeadTargetByActorVelocity)
			{
				float TimeToTarget = Trajectory::GetTimeToReachTarget(
					Target.Distance(Source), 1000.0, 60000.0
				);
				Target += AimTarget.AutoAimTarget.Owner.ActorVelocity * TimeToTarget;
			}

			Direction = (Target - Source).GetSafeNormal();
		}
		else
		{
			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming);
			Trace.UseLine();

			FHitResult Hit = Trace.QueryTraceSingle(AimTarget.AimOrigin, AimTarget.AimOrigin + AimTarget.AimDirection * 10000.0);
			if (Hit.bBlockingHit)
			{
				Direction = (Hit.ImpactPoint - Source).GetSafeNormal();
				// Debug::DrawDebugLine(Source, Hit.ImpactPoint);
			}
			else
			{
				Direction = AimTarget.AimDirection;
			}
		}

		float TimeSinceFire = Time::GetGameTimeSince(LastFireTime);
		if (TimeSinceFire >= FireInterval)
		{
			Fire(Source, Direction);
		}

		BazookaComp.Bazooka.ActorRotation = FRotator::MakeFromX(Direction);

		if (Player.Mesh.CanRequestOverrideFeature())
			Player.Mesh.RequestOverrideFeature(n"GlitchWeaponStrafe", this);
	}
};