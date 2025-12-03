class UBattlefieldTankTurretFireCapability : UHazeCapability
{
	default CapabilityTags.Add(n"BattlefieldTankTurretFireCapability");
	default CapabilityTags.Add(n"BattlefieldTankTurret");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ABattlefieldTankTurret TankTurret;

	FHazeAcceleratedQuat AccelQuat;

	float TurretOffset;
	float TurretOffsetAmount = 500.0;

	FVector StartRelative;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TankTurret = Cast<ABattlefieldTankTurret>(Owner);
		StartRelative = TankTurret.BarrelKickbackRoot.RelativeLocation;
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
		TankTurret.ProjectileComponent1.ActivateAutoFire(1.2);
		TankTurret.ProjectileComponent2.ActivateAutoFire(1.2);
		UBattlefieldTankTurretEffectHandler::Trigger_OnTurretStartShoot(TankTurret);
		TankTurret.ProjectileComponent1.OnBattlefieldProjectileFiredProjectile.AddUFunction(this, n"OnBattlefieldProjectileFiredProjectile");
	}

	UFUNCTION()
	private void OnBattlefieldProjectileFiredProjectile()
	{
		TurretOffset = TurretOffsetAmount;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TankTurret.ProjectileComponent1.DeactivateAutoFire();
		TankTurret.ProjectileComponent2.DeactivateAutoFire();
		UBattlefieldTankTurretEffectHandler::Trigger_OnTurretStopShoot(TankTurret);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TurretOffset = Math::FInterpTo(TurretOffset, 0.0, DeltaTime, 1.0);
		TankTurret.BarrelKickbackRoot.RelativeLocation = StartRelative + FVector(TurretOffset, 0.0, 0.0);
	}
}