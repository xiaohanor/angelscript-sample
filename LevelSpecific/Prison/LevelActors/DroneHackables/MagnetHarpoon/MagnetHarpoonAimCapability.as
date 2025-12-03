class UMagnetHarpoonAimCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AMagnetHarpoon MagnetHarpoon;
	AHazePlayerCharacter Player;
	UCameraUserComponent CameraUserComp;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MagnetHarpoon = Cast<AMagnetHarpoon>(Owner);
		Player = Drone::GetSwarmDronePlayer();
		CameraUserComp = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!MagnetHarpoon.HijackTargetableComp.IsHijacked())
			return false;

		if(MagnetHarpoon.State != EMagnetHarpoonState::Aim)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!MagnetHarpoon.HijackTargetableComp.IsHijacked())
			return true;

		if(MagnetHarpoon.State != EMagnetHarpoonState::Aim)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (HasControl())
			MagnetHarpoon.SyncedAimRotator.SetValue(MagnetHarpoon.RotationRoot.RelativeRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!HasControl())
		{
			MagnetHarpoon.RotationRoot.SetRelativeRotation(MagnetHarpoon.SyncedAimRotator.GetValue());
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);

			FVector2D CameraInput = Player.GetCameraInput();
			FRotator DeltaRotation = CameraUserComp.CalculateBaseDeltaRotationFromSensitivity(
				CameraInput, DeltaTime, bUseTargetSensitivity = true
			);
			DeltaRotation.Yaw *= (MagnetHarpoon.AimSpeed / 100.0);
			DeltaRotation.Pitch *= (MagnetHarpoon.AimSpeed / 70.0);

			DeltaRotation.Yaw += MoveInput.X * MagnetHarpoon.AimSpeed * DeltaTime;
			DeltaRotation.Pitch += MoveInput.Y * MagnetHarpoon.AimSpeed * DeltaTime;

			FRotator CurRot = MagnetHarpoon.RotationRoot.RelativeRotation;
			CurRot.Yaw = Math::Clamp(CurRot.Yaw + DeltaRotation.Yaw, -MagnetHarpoon.LeftClamp, MagnetHarpoon.RightClamp);
			CurRot.Pitch = Math::Clamp(CurRot.Pitch + DeltaRotation.Pitch, MagnetHarpoon.MinPitch, MagnetHarpoon.MaxPitch);

			MagnetHarpoon.SyncedAimRotator.SetValue(CurRot);
		}

		MagnetHarpoon.BaseComp.SetRelativeRotation(FRotator(0, MagnetHarpoon.SyncedAimRotator.Value.Yaw, 0));
		MagnetHarpoon.RotationRoot.SetRelativeRotation(FRotator(MagnetHarpoon.SyncedAimRotator.Value.Pitch, MagnetHarpoon.BaseComp.RelativeRotation.Yaw, 0));
	}
};