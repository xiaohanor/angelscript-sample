class UControllableDropShipPlayerTurretCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AControllableDropShip DropShip;
	UCameraUserComponent CameraUser;

	float TargetTurretYaw = 0.0;;
	float TargetTurretPitch = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DropShip = Cast<AControllableDropShip>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!DropShip.bTurretControlledByPlayer)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!DropShip.bTurretControlledByPlayer)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetTurretYaw = DropShip.TurretYaw;
		TargetTurretPitch = DropShip.TurretPitch;
		CameraUser = UCameraUserComponent::Get(DropShip.PassengerAimComp.Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (DropShip.SyncedTurretRotation.HasControl())
		{
			float MinYaw = -ControllableDropShip::TurretMaxYaw;
			float MaxYaw = ControllableDropShip::TurretMaxYaw;

			float YawTurnRate = ControllableDropShip::TurretTurnRate / 172.0;
			float PitchTurnRate = ControllableDropShip::TurretTurnRate / 172.0;

			FRotator BaseDeltaRotation = CameraUser.CalculateBaseDeltaRotationFromSensitivity(
				DropShip.PassengerInput, DeltaTime, bUseTargetSensitivity = true
			);

			TargetTurretYaw = Math::Clamp(TargetTurretYaw + (BaseDeltaRotation.Yaw * YawTurnRate), MinYaw, MaxYaw);
			DropShip.TurretYaw = Math::FInterpTo(DropShip.TurretYaw, TargetTurretYaw, DeltaTime, 10.0);

			if (DropShip.bTighteningTurretClamp)
				DropShip.CurrentTurretPitchClamp = Math::FInterpConstantTo(DropShip.CurrentTurretPitchClamp, ControllableDropShip::TurretMinPitch, DeltaTime, 15.0);

			TargetTurretPitch = Math::Clamp(TargetTurretPitch + (BaseDeltaRotation.Pitch * PitchTurnRate), DropShip.CurrentTurretPitchClamp, ControllableDropShip::TurretMaxPitch);
			DropShip.TurretPitch = Math::FInterpTo(DropShip.TurretPitch, TargetTurretPitch, DeltaTime, 5.0);
			DropShip.SyncedTurretRotation.Value = FRotator(DropShip.TurretPitch, DropShip.TurretYaw, 0.0);
		}
		else
		{
			DropShip.TurretYaw = DropShip.SyncedTurretRotation.Value.Yaw;
			DropShip.TurretPitch = DropShip.SyncedTurretRotation.Value.Pitch;
		}

		DropShip.Turret.TurretLight.SetRelativeRotation(FRotator(-1.0, 1.0, 0.0));

		DropShip.TurretBase.SetRelativeRotation(FRotator(0.0, DropShip.TurretYaw, 0.0));
		DropShip.Turret.AimBSValues.Y = DropShip.TurretPitch;
	}
}