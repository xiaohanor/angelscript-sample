class UIceFractalCameraCapability : UHazePlayerCapability
{
    UIceFractalDataComponent DataComp;
    UCameraUserComponent CameraUser;

    AIceFractalSpawner IceFractalSpawner;
    float NoInputDuration = 0.0;
	FRotator InputRotation;
	FHazeAcceleratedRotator AccInputRotation;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        DataComp = UIceFractalDataComponent::Get(Player);
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
        IceFractalSpawner = TListedActors<AIceFractalSpawner>().Single;
		check(IceFractalSpawner != nullptr);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if(!HasControl())
			return;

        FVector DirToSpawner = IceFractalSpawner.ActorLocation - Player.ViewLocation;
        CameraUser.SetDesiredRotation(DirToSpawner.Rotation(), this);

		UpdateInputDuration(DeltaTime);

		AccInputRotation.AccelerateTo(GetInputTargetRotation(), bIsInputting ? DataComp.Settings.CameraInputDuration : DataComp.Settings.CameraInputDuration * 2.0, DeltaTime);

		CameraUser.AddDesiredRotation(AccInputRotation.Value, this);
    }

	void UpdateInputDuration(float DeltaTime)
	{
		const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);;
		if (AxisInput.IsNearlyZero(0.001))
			NoInputDuration += DeltaTime;
		else
			NoInputDuration = 0.0;
	}

	bool GetbIsInputting() const property
	{
		return NoInputDuration < DataComp.Settings.CameraInputDelay;
	}

	FRotator GetInputTargetRotation()
	{
		if(bIsInputting)
		{
			const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
			InputRotation.Yaw = Math::Clamp(InputRotation.Yaw + AxisInput.X * DataComp.Settings.CameraInputSensitivity, -DataComp.Settings.CameraInputYawClamp, DataComp.Settings.CameraInputYawClamp);
			InputRotation.Pitch = Math::Clamp(InputRotation.Pitch + AxisInput.Y * DataComp.Settings.CameraInputSensitivity, -DataComp.Settings.CameraInputPitchClamp, DataComp.Settings.CameraInputPitchClamp);
		}
		else
		{
			InputRotation = FRotator::ZeroRotator;
		}

		return InputRotation;
	}
}