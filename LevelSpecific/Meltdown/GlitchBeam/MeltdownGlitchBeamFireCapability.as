class UMeltdownGlitchBeamFireCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"GlitchShooting");

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 250;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AMeltdownGlitchBeam Beam;
	UMeltdownGlitchShootingUserComponent ShootingComp;
	UMeltdownGlitchBeamUserComponent BeamComp;
	UPlayerAimingComponent AimingComp;
	UPlayerMovementComponent MoveComp;
	UMeltdownSkydiveComponent SkydiveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ShootingComp = UMeltdownGlitchShootingUserComponent::Get(Player);
		BeamComp = UMeltdownGlitchBeamUserComponent::Get(Player);
		AimingComp = UPlayerAimingComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		SkydiveComp = UMeltdownSkydiveComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!ShootingComp.bGlitchShootingActive)
			return false;
		if (!IsActioning(ActionNames::WeaponFire))
			return false;
		if (!MoveComp.IsOnWalkableGround() && !SkydiveComp.IsSkydiving())
			return false;
		if (Player.IsAnyCapabilityActive(n"Dash"))
			return false;
		if (!AimingComp.IsAiming(ShootingComp))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!ShootingComp.bGlitchShootingActive)
			return true;
		if (!IsActioning(ActionNames::WeaponFire))
			return true;
		if (!MoveComp.IsOnWalkableGround() && !SkydiveComp.IsSkydiving())
			return true;
		if (Player.IsAnyCapabilityActive(n"Dash"))
			return true;
		if (!AimingComp.IsAiming(ShootingComp))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Beam = SpawnActor(BeamComp.BeamClass);
		Beam.OwningPlayer = Player;
		Beam.StartBeam();

		Player.EnableStrafe(this);
		Player.ApplyStrafeSpeedScale(this, 0.5);
		AimingComp.ApplyAimingSensitivity(this);

		Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		Player.BlockCapabilities(PlayerMovementTags::Dash, this);

		Player.PlayForceFeedback(BeamComp.FireForceFeedback, true, true, this);

		auto CamSettings = UCameraSettings::GetSettings(Player);
		// CamSettings.SensitivityFactor.Apply(0.5, this, 0, EHazeCameraPriority::MAX);
		// CamSettings.IdealDistance.ApplyAsAdditive(-500, this, 1.0, EHazeCameraPriority::MAX);
		// CamSettings.PivotOffset.ApplyAsAdditive(FVector(0.0, 100.0, 0.0), this, 1.0, EHazeCameraPriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Beam.StopBeam();

		Player.DisableStrafe(this);
		Player.ClearStrafeSpeedScale(this);
		AimingComp.ClearAimingSensitivity(this);

		Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
		Player.UnblockCapabilities(PlayerMovementTags::Dash, this);

		Player.StopForceFeedback(this);

		auto CamSettings = UCameraSettings::GetSettings(Player);
		CamSettings.SensitivityFactor.Clear(this, 0.0);
		CamSettings.IdealDistance.Clear(this, 2.0);
		CamSettings.PivotOffset.Clear(this, 2.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Source = Player.Mesh.GetSocketLocation(n"RightHand");
		FVector Direction;

		if (!SkydiveComp.IsSkydiving())
		{
			FAimingResult AimTarget = AimingComp.GetAimingTarget(ShootingComp);

			if (AimTarget.AutoAimTarget != nullptr)
			{
				FVector Target = AimTarget.AutoAimTargetPoint;
				Direction = (Target - Source).GetSafeNormal();
			}
			else
			{
				FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming);
				Trace.UseLine();

				FHitResult Hit = Trace.QueryTraceSingle(AimTarget.AimOrigin, AimTarget.AimOrigin + AimTarget.AimDirection * 10000.0);
				if (Hit.bBlockingHit)
					Direction = (Hit.ImpactPoint - Source).GetSafeNormal();
				else
					Direction = AimTarget.AimDirection;
			}
		}
		else
		{
			Direction = (Player.ActorLocation - Player.ViewLocation).GetSafeNormal();
			Direction = Math::Lerp(Direction, FVector::DownVector, 0.5);
			Direction = Direction.GetSafeNormal();
		}

		Beam.UpdateBeam(Source, Direction);
		ShootingComp.AimDirection = Direction;

		Player.Mesh.RequestOverrideFeature(n"GlitchWeaponStrafe", this);
	}
};