class UMeltdownGlitchSwordAttackCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default TickGroup = EHazeTickGroup::Movement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UMeltdownGlitchSwordUserComponent SwordComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerAimingComponent AimingComp;
	UMeltdownGlitchShootingUserComponent ShootingComp;
	UHazeActorLocalSpawnPoolComponent ProjectilePool;
	UMeltdownGlitchShootingCrosshair Crosshair;

	int ComboIndex = 0;

	float AttackLength = 0.0;
	float AttackStartTime = 0.0;
	float HitPoint;
	float ComboWindowStart;
	bool bHasHit = false;

	float LastImpulseTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwordComp = UMeltdownGlitchSwordUserComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		AimingComp = UPlayerAimingComponent::Get(Player);
		ShootingComp = UMeltdownGlitchShootingUserComponent::Get(Player);
		ProjectilePool = HazeActorLocalSpawnPoolStatics::GetOrCreateSpawnPool(SwordComp.ProjectileClass, Player);
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
		if (!ShootingComp.bGlitchShootingActive)
			return false;
		if (Player.IsAnyCapabilityActive(n"Dash"))
			return false;
		if (MoveComp.HasImpulse())
			return false;
		if (!MoveComp.IsOnAnyGround() && Time::GetGameTimeSince(LastImpulseTime) < 0.6)
			return false;
		if (IsActioning(ActionNames::PrimaryLevelAbility))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Time::GetGameTimeSince(AttackStartTime) >= AttackLength)
			return true;
		if (!IsActioning(ActionNames::PrimaryLevelAbility) && ActiveDuration >= ComboWindowStart)
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
		Crosshair = Cast<UMeltdownGlitchShootingCrosshair>(AimingComp.GetCrosshairWidget(n"MeltdownGlitchSword"));
		ComboIndex = -1;

		if (HasControl())
			CrumbStartNextAttack();

		auto CamSettings = UCameraSettings::GetSettings(Player);
		// CamSettings.IdealDistance.ApplyAsAdditive(-500, this, 1.0, EHazeCameraPriority::MAX);
		// CamSettings.PivotOffset.ApplyAsAdditive(FVector(0.0, 100.0, 0.0), this, 1.0, EHazeCameraPriority::High);

		Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		Player.BlockCapabilities(PlayerMovementTags::Dash, this);

		Player.EnableStrafe(this);
		Player.ApplyStrafeSpeedScale(this, 0.5);
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartNextAttack()
	{
		AimingComp.ApplyAimingSensitivity(this);

		HitPoint = 0.2;
		ComboWindowStart = 0.35;
		AttackLength = 0.6;
		AttackStartTime = Time::GameTimeSeconds;
		bHasHit = false;
		ShootingComp.WeaponVisibility.Apply(true, this);

		SwordComp.LastSwordAttackFrame = GFrameNumber;
		if (SwordComp.LastSwordAttackDirection == EGlitchSwordAttackType::Left)
			SwordComp.LastSwordAttackDirection = EGlitchSwordAttackType::Right;
		else
			SwordComp.LastSwordAttackDirection = EGlitchSwordAttackType::Left;

		UMeltdownGlitchShootingEffectHandler::Trigger_OnSwordAttackStarted(Player, FMeltdownGlitchSwordSwingEffectParams(SwordComp.LastSwordAttackDirection));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Crosshair != nullptr)
			Crosshair.BP_OnStopFiring();
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

	void Fire()
	{
		FAimingResult Aim = AimingComp.GetAimingTarget(n"MeltdownGlitchSword");

		FVector ShootDirection = Math::VRandCone(Aim.AimDirection, Math::DegreesToRadians(5.0));
		if (ShootDirection.Z < 0)
			ShootDirection.Z = 0;
		ShootDirection = ShootDirection.GetSafeNormal();

		FVector SidewaysDirection = SwordComp.Sword.ActorUpVector;

		FHazeActorSpawnParameters SpawnParams;
		SpawnParams.Location = SwordComp.Sword.ActorLocation + SwordComp.Sword.ActorForwardVector * 80.0;
		SpawnParams.Rotation = FRotator::MakeFromXY(ShootDirection, SidewaysDirection);

		auto Projectile = Cast<AMeltdownGlitchSwordProjectile>(ProjectilePool.Spawn(SpawnParams));
		Projectile.OwningPlayer = Player; 
		Projectile.ProjectilePool = ProjectilePool;
		Projectile.Fire();

		FMeltdownGlitchProjectileFireEffectParams EffectParams;
		EffectParams.FireLocation = Projectile.ActorLocation;
		EffectParams.FireDirection = ShootDirection;
		UMeltdownGlitchShootingEffectHandler::Trigger_OnProjectileFired(Player, EffectParams);

		Player.PlayForceFeedback(SwordComp.FireForceFeedback, false, false, this);
		Player.PlayCameraShake(SwordComp.SwordShake,this, 0.5);

		if (Crosshair != nullptr)
			Crosshair.BP_OnStartFiring();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float TimeIntoAttack = Time::GetGameTimeSince(AttackStartTime);

		if (!bHasHit)
		{
			if (TimeIntoAttack >= HitPoint)
			{
				Fire();
				bHasHit = true;
			}
		}
		else
		{
			if (TimeIntoAttack >= ComboWindowStart)
			{
				if (HasControl())
				{
					if (IsActioning(ActionNames::PrimaryLevelAbility))
						CrumbStartNextAttack();
				}
			}
		}
		
		// if (MoveComp.PrepareMove(Movement))
		// {
		// 	MoveComp.ApplyMove(Movement);
		// }

		if (Player.Mesh.CanRequestOverrideFeature())
			Player.Mesh.RequestOverrideFeature(n"GlitchWeaponStrafe", this);
	}
};