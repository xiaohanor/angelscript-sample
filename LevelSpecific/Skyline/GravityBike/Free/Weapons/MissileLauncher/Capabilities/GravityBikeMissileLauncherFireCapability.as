class UGravityBikeMissileLauncherFireCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"GravityBikeFreeWeaponFire");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UGravityBikeWeaponUserComponent WeaponComp;
	UGravityBikeMissileLauncherComponent MissileLauncherComp;
	AGravityBikeMissileLauncher MissileLauncher;

	uint FiredMissiles = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeaponComp = UGravityBikeWeaponUserComponent::Get(Player);
		MissileLauncherComp = UGravityBikeMissileLauncherComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Player.IsUsingGamepad())
		{
			if (!IsActioning(GravityBikeWeapon::FireAction))
				return false;
		}
		else
		{
			// Left click must be fire
			if(!IsActioning(ActionNames::PrimaryLevelAbility))
				return false;
		}

		if (!MissileLauncherComp.IsEquipped())
			return false;

		if (!WeaponComp.HasChargeFor(MissileLauncherComp.MissileLauncher.GetChargePerShot()))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Player.IsUsingGamepad())
		{
			if (!IsActioning(GravityBikeWeapon::FireAction))
				return true;
		}
		else
		{
			// Left click must be fire
			if(!IsActioning(ActionNames::PrimaryLevelAbility))
				return true;
		}

		if (!MissileLauncherComp.IsEquipped())
			return true;

		if (!WeaponComp.HasChargeFor(MissileLauncherComp.MissileLauncher.GetChargePerShot()))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MissileLauncher = MissileLauncherComp.MissileLauncher;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		WeaponComp.UpdateIsFired();

		if(HasControl())
		{
			if (Time::GameTimeSeconds < MissileLauncherComp.TimeLastFired + MissileLauncher.FireInterval)
				return;

			FireWeapon();
		}
	}
	
	void FireWeapon()
	{
		check(HasControl());

		auto GravityBike = UGravityBikeFreeDriverComponent::Get(Player).GetGravityBike();

		MissileLauncherComp.bUseLeftMuzzle = !MissileLauncherComp.bUseLeftMuzzle;

		auto MuzzleComp = MissileLauncherComp.GetCurrentMuzzle();

		FVector Direction = MuzzleComp.WorldTransform.Rotation.ForwardVector;

		if(!IsJumpingOverBossCore())
		{
			float VerticalDot = Direction.DotProduct(FVector::UpVector);

			if (VerticalDot < 0.0)
			{
				// If direction is facing down, clamp it to be flat
				Direction = Direction.VectorPlaneProject(FVector::UpVector);
				Direction.Normalize();
			}
		}

		CrumbFireWeapon(
			MuzzleComp.WorldLocation,
			Direction,
			GravityBike.ActorVelocity,
			MissileLauncherComp.AimTarget
		);
	}

	UFUNCTION(CrumbFunction)
	void CrumbFireWeapon(FVector Location, FVector Direction, FVector Velocity, FGravityBikeWeaponTargetData AimTarget)
	{
		// Spawn and initialize missile
		FHazeActorSpawnParameters Params;
		Params.Location = Location;
		Params.Rotation = Direction.ToOrientationRotator();
		Params.Spawner = this;

		auto NewMissile = Cast<AGravityBikeMissileLauncherProjectile>(MissileLauncherComp.MissileSpawnPool.Spawn(Params));
		NewMissile.Initialize(Player, Velocity, AimTarget, Direction);

		NewMissile.SetActorControlSide(Player);
		
		FiredMissiles++;
		NewMissile.MakeNetworked(this, FiredMissiles);

		// Muzzle flash
		Niagara::SpawnOneShotNiagaraSystemAttached(MissileLauncher.MuzzleFlash, MissileLauncherComp.GetCurrentMuzzle());

		// Event on bike
		auto GravityBike = UGravityBikeFreeDriverComponent::Get(Player).GetGravityBike();
		UGravityBikeFreeEventHandler::Trigger_OnWeaponFire(GravityBike);

		// Store fired time
		MissileLauncherComp.TimeLastFired = Time::GameTimeSeconds;

		// Reduce weapon charge
		WeaponComp.DecreaseCharge(1.0 / MissileLauncher.ShotsPerMaxCharge);

		// Force Feedback
		FHazeFrameForceFeedback ForceFeedback;
		ForceFeedback.LeftMotor = 0.1;
		ForceFeedback.RightMotor = 0.1;
		ForceFeedback.LeftTrigger = 0.1;
		ForceFeedback.RightTrigger = 0.1;
		Player.SetFrameForceFeedback(ForceFeedback, 0.09);
	}

	bool IsJumpingOverBossCore() const
	{
		auto GravityBike = GravityBikeFree::GetGravityBike(Player);
		if(GravityBike == nullptr)
			return false;

		auto HalfPipeComp = UGravityBikeFreeHalfPipeComponent::Get(GravityBike);
		if(HalfPipeComp == nullptr)
			return false;

		return HalfPipeComp.bIsJumping;
	}
}