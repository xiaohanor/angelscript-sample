class UBattlefieldTankTurretTargetingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"BattlefieldTankTurretTargetingCapability");
	default CapabilityTags.Add(n"BattlefieldTankTurret");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ABattlefieldTankTurret TankTurret;

	FHazeAcceleratedQuat AccelQuat;

	float ZOffset;

	FHazeAcceleratedFloat ZTargetAccelerateOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TankTurret = Cast<ABattlefieldTankTurret>(Owner);
		TankTurret.ProjectileComponent1.OnBattlefieldProjectileStartFire.AddUFunction(this, n"OnBattlefieldProjectileStartFire");
		ZTargetAccelerateOffset.SnapTo(800.0);
		// TankTurret.ProjectileComponent2.OnBattlefieldProjectileEndFire.AddUFunction(this, n"OnBattlefieldProjectileStartFire");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (TankTurret.GetPlayersInRange().Num() == 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (TankTurret.GetPlayersInRange().Num() == 0)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccelQuat.SnapTo(TankTurret.Turret.WorldRotation.Quaternion());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AHazePlayerCharacter ClosestPlayer = Game::Mio.GetDistanceTo(TankTurret) < Game::Zoe.GetDistanceTo(TankTurret) ? Game::Mio : Game::Zoe;
		FVector TargetLoc = ClosestPlayer.ActorLocation + (FVector::UpVector * ZTargetAccelerateOffset.Value);

		ZTargetAccelerateOffset.AccelerateTo(0.0, 4.5, DeltaTime);

		FVector Direction = (TargetLoc - TankTurret.Turret.WorldLocation).GetSafeNormal();

		FQuat TargetQuat = Direction.ToOrientationQuat();
		AccelQuat.AccelerateTo(TargetQuat, 0.1, DeltaTime);

		FRotator YawRot = AccelQuat.Value.Rotator();
		YawRot.Pitch = 0.0;
		YawRot.Roll = 0.0;

		FRotator PitchRot = AccelQuat.Value.Rotator();
		PitchRot.Yaw = YawRot.Yaw;
		PitchRot.Roll = 0.0;

		TankTurret.Turret.WorldRotation = YawRot;
		TankTurret.BarrelRotationRoot.WorldRotation = PitchRot;
	}

	UFUNCTION()
	private void OnBattlefieldProjectileStartFire()
	{
		ZOffset = 1200.0;
	}
}