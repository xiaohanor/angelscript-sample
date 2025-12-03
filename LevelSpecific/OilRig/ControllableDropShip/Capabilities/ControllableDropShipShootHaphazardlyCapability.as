class UControllableDropShipShootHaphazardlyCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"ShootAtPlayers");
	default CapabilityTags.Add(n"EnemyControlled");

	default TickGroup = EHazeTickGroup::Gameplay;

	AControllableDropShip DropShip;

	int MinShotsPerBurst = 12;
	int MaxShotsPerBurst = 24;
	int ShotsPerBurst = 10;
	int CurrentShotAmount = 0;
	FVector2D BurstCooldownRange = FVector2D(0.15, 0.25);
	float BurstCooldown = 0.1;
	float CurrentBurstCooldown = 0.0;
	float ShootInterval = 0.04;
	float CurrentShootTime = 0.0;

	bool bShootingStarted = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DropShip = Cast<AControllableDropShip>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!DropShip.bShootingHaphazardly)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!DropShip.bShootingHaphazardly)
			return true;

		if (DropShip.ShootSpline != nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bShootingStarted = false;
		CurrentBurstCooldown = 0.0;
		CurrentShotAmount = 0;
		CurrentShootTime = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DropShip.StopShootingHapzardly();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bShootingStarted && ActiveDuration >= 0.5)
		{
			bShootingStarted = true;
			DropShip.StartShootingHaphazardly();
		}

		if (bShootingStarted)
		{
			if (CurrentBurstCooldown > 0)
				CurrentBurstCooldown -= DeltaTime;
			else
			{
				CurrentShootTime += DeltaTime;
				if (CurrentShootTime >= ShootInterval)
				{
					CurrentShootTime = 0.0;
					FVector TurretLoc = DropShip.Turret.SkelMeshComp.GetSocketLocation(n"TurretGunBase");
					FVector TurretDir = DropShip.Turret.SkelMeshComp.GetSocketRotation(n"TurretGunBase").ForwardVector;
					DropShip.Shoot(TurretLoc + (TurretDir * 20000.0), bLocal = true);
					CurrentShotAmount++;
					if (CurrentShotAmount >= ShotsPerBurst)
					{
						CurrentBurstCooldown = Math::RandRange(BurstCooldownRange.X, BurstCooldownRange.Y);
						CurrentShotAmount = 0;
						ShotsPerBurst = Math::RandRange(MinShotsPerBurst, MaxShotsPerBurst);
					}
				}
			}
		}
	}
}