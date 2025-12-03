class UTiltingWorldZoeCameraCapability : UHazePlayerCapability
{
    UTiltingWorldZoeComponent PlayerComp;
    UTiltingWorldMioComponent MioComp;
    UCameraUserComponent CameraUser;

    FHazeAcceleratedRotator AccCameraRotationOffset;
	float NoInputDuration = 0.0;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PlayerComp = UTiltingWorldZoeComponent::GetOrCreate(Player);
        MioComp = UTiltingWorldMioComponent::Get(Game::GetMio());
        CameraUser = UCameraUserComponent::Get(Player);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
        Player.ApplyCameraSettings(MioComp.Settings.CameraSettings, 0.5, this, SubPriority = 60);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
        Player.ClearCameraSettingsByInstigator(this);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if(!HasControl())
            return;

		if(MioComp.Settings.bDisableCamera)
		{
        	CameraUser.SetYawAxis(MioComp.SmoothWorldRotation.UpVector, this);
        	CameraUser.SetDesiredRotation(FRotator::MakeFromXZ(FVector::ForwardVector, MioComp.SmoothWorldRotation.UpVector), this);
			return;
		}

        UpdateInputDuration(DeltaTime);

        CameraUser.SetYawAxis(MioComp.SmoothWorldRotation.UpVector, this);

        FRotator TargetRotation = GetInputTargetRotation();

        AccCameraRotationOffset.AccelerateTo(TargetRotation, 1.0 / MioComp.Settings.CameraRotateAcceleration, DeltaTime);

        FRotator WorldRotation = FRotator::MakeFromZX(MioComp.SmoothWorldRotation.UpVector, FVector::ForwardVector);

        CameraUser.SetDesiredRotation(AccCameraRotationOffset.Value.Compose(WorldRotation), this);
    }

    void UpdateInputDuration(float DeltaTime)
	{
		const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);;
		if (AxisInput.IsNearlyZero(0.001))
			NoInputDuration += DeltaTime;
		else
			NoInputDuration = 0.0;
	}

	bool GetbShouldReset() const property
	{
        switch(MioComp.Settings.ResetCameraType)
        {
             case ETiltingWorldCameraResetType::None:
                return false;

            case ETiltingWorldCameraResetType::Delay:
                return NoInputDuration > MioComp.Settings.CameraResetDelay;

            case ETiltingWorldCameraResetType::Instant:
                return GetAttributeVector2D(AttributeVectorNames::CameraDirection).SizeSquared() < KINDA_SMALL_NUMBER;
        }
	}

    FRotator GetInputTargetRotation()
	{
        FRotator TargetRotation = AccCameraRotationOffset.Value;

		if(bShouldReset)
		{
			TargetRotation = FRotator::ZeroRotator;
		}
		else
        {
			const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
			TargetRotation.Yaw = Math::Clamp(TargetRotation.Yaw + AxisInput.X * MioComp.Settings.CameraRotateSpeed, -MioComp.Settings.CameraClampAngle, MioComp.Settings.CameraClampAngle);
			TargetRotation.Pitch = Math::Clamp(TargetRotation.Pitch + AxisInput.Y * MioComp.Settings.CameraRotateSpeed, -MioComp.Settings.CameraClampAngle, MioComp.Settings.CameraClampAngle);
		}

		return TargetRotation;
	}
}