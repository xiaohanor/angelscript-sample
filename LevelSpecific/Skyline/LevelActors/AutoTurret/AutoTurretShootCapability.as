class UAutoTurretShootCapability : UHazeCapability
{
	default CapabilityTags.Add(n"AutoTurretShoot");

	AAutoTurret AutoTurret;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AutoTurret = Cast<AAutoTurret>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!CanShoot())
			return false;

		if(DeactiveDuration <= AutoTurret.FireRate)
			return false;

		return true;	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	//	PrintToScreen("Shoot", 1.0);
		AutoTurret.SpawnBullet();
	}

	bool CanShoot() const
	{
		if(AutoTurret.CurrentTarget == nullptr)
			return false;

		FVector AimDirection = (AutoTurret.CurrentTarget.ActorCenterLocation - AutoTurret.Pivot.WorldLocation).GetSafeNormal();

		float ToTargetDot = AutoTurret.Pivot.ForwardVector.DotProduct(AimDirection);

		if (ToTargetDot > 0.9)
		{
			return true;
		}

		return false;

	}

}