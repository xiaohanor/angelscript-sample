class UControllableDropShipShootAtSplineCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"ShootAtPlayers");
	default CapabilityTags.Add(n"EnemyControlled");

	default TickGroup = EHazeTickGroup::Gameplay;

	AControllableDropShip DropShip;

	float ShootInterval = 0.04;
	float CurrentShootTime = 0.0;
	float ShootSplineSpeed = 2200.0;
	float CurrentSplineDistance = 0.0;

	UHazeSplineComponent ShootSpline;

	bool bAligning = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DropShip = Cast<AControllableDropShip>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DropShip.ShootSpline == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DropShip.ShootSpline == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bAligning = true;
		ShootSpline = DropShip.ShootSpline.Spline;
		CurrentSplineDistance = 0.0;

		DropShip.StopShootingHapzardly();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DropShip.OnShootSplineFinished.Broadcast();

		DropShip.StopShootingAtPlayers();

		DropShip.SetHapzardShootingAllowed(true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ShootSpline != nullptr)
		{
			float CurrentYaw = DropShip.TurretBase.WorldRotation.Yaw;
			float CurrentPitch = DropShip.Turret.AimBSValues.Y;

			if (bAligning)
			{
				FVector TargetShootLoc = ShootSpline.GetWorldLocationAtSplineDistance(0.0);
				FVector DirToShootSpline = (TargetShootLoc - DropShip.Turret.SkelMeshComp.GetSocketLocation(n"TurretGunBase")).GetSafeNormal();

				float Yaw = Math::FInterpTo(CurrentYaw, DirToShootSpline.Rotation().Yaw, DeltaTime, 5.0);
				float Pitch = Math::FInterpTo(CurrentPitch, DirToShootSpline.Rotation().Pitch, DeltaTime, 5.0);

				FRotator YawRot = DropShip.TurretBase.WorldRotation;
				YawRot.Yaw = Yaw;
				DropShip.TurretBase.SetWorldRotation(YawRot);

				FRotator PitchRot = DropShip.Turret.SkelMeshComp.GetSocketRotation(n"TurretGunBase");
				PitchRot.Pitch = Pitch;
				DropShip.Turret.AimBSValues.Y = PitchRot.Pitch;

				if (Math::IsNearlyEqual(Yaw, DirToShootSpline.Rotation().Yaw, 3.0) && Math::IsNearlyEqual(Pitch, DirToShootSpline.Rotation().Pitch, 3.0))
					Aligned();
			}
			else
			{
				CurrentSplineDistance += ShootSplineSpeed * DeltaTime;
				FVector TargetShootLoc = ShootSpline.GetWorldLocationAtSplineDistance(CurrentSplineDistance);
				FVector DirToShootSpline = (TargetShootLoc - DropShip.Turret.SkelMeshComp.GetSocketLocation(n"TurretGunBase")).GetSafeNormal();

				DropShip.TurretBase.SetWorldRotation(FRotator(DropShip.TurretBase.WorldRotation.Pitch, DirToShootSpline.Rotation().Yaw, DropShip.TurretBase.WorldRotation.Roll));
				FRotator PitchRot = DropShip.Turret.SkelMeshComp.GetSocketRotation(n"TurretGunBase");
				PitchRot.Pitch = DirToShootSpline.Rotation().Pitch;
				DropShip.Turret.AimBSValues.Y = PitchRot.Pitch;

				CurrentShootTime += DeltaTime;
				if (CurrentShootTime >= ShootInterval)
				{
					CurrentShootTime = 0.0;
					FVector TurretLoc = DropShip.Turret.SkelMeshComp.GetSocketLocation(n"TurretGunBase");
					FVector TurretDir = DropShip.Turret.SkelMeshComp.GetSocketRotation(n"TurretGunBase").ForwardVector;
					DropShip.Shoot(TurretLoc + (TurretDir * 20000.0), bLocal = true);
				}

				if (CurrentSplineDistance >= ShootSpline.SplineLength)
				{
					ShootSpline = nullptr;
					DropShip.ShootSpline = nullptr;
				}
			}
		}
	}

	void Aligned()
	{
		bAligning = false;
		DropShip.StartShootingAtPlayers();
	}
}