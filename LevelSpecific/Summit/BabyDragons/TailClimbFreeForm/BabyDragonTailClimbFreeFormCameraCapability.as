class UBabyDragonTailClimbFreeFormCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(BabyDragon::BabyDragon);
	default CapabilityTags.Add(n"TailClimb");
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(CapabilityTags::Camera);

	default BlockExclusionTags.Add(n"TailClimb");

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 1;

	UPlayerTailBabyDragonComponent DragonComp;
	UCameraUserComponent CameraUser;

	FHazeAcceleratedRotator AccCameraRotation;
	FHazeAcceleratedRotator AccInputCameraRotation;

	float NoCameraInputTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailBabyDragonComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!CameraUser.CanControlCamera())
			return false;

		if(!DragonComp.bUseClimbingCamera)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CameraUser.CanControlCamera())
			return true;

		if(!DragonComp.bUseClimbingCamera)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccCameraRotation.SnapTo(CameraUser.ViewRotation, CameraUser.ViewAngularVelocity);
		AccInputCameraRotation.SnapTo(FRotator::ZeroRotator);
		NoCameraInputTimer = 0.0;
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

		if(CameraUser.CanApplyUserInput())
		{
			const float CameraDeltaTime = Time::CameraDeltaSeconds;


			FRotator TargetCameraRotation = FRotator::MakeFromX(-DragonComp.AttachNormal);
			TargetCameraRotation += BabyDragonTailClimbSettings::CameraTargetOffsetRotation;
			AccCameraRotation.AccelerateTo(TargetCameraRotation, 2.0, CameraDeltaTime);

			UpdateInputRotation(CameraDeltaTime);

			FRotator CameraRotation = AccCameraRotation.Value + AccInputCameraRotation.Value;

			FRotator DeltaRotation = CameraRotation - CameraUser.GetActiveCameraRotation();

			CameraUser.AddUserInputDeltaRotation(DeltaRotation, this);
		}
	}

	private void UpdateInputRotation(float DeltaTime)
	{
		FVector2D CameraInputRaw = Player.GetCameraInput();
		FRotator TargetInputRotation = FRotator::ZeroRotator;
		float RotationDuration;
		
		if(CameraInputRaw.IsNearlyZero())
		{
			NoCameraInputTimer += DeltaTime;
			if(NoCameraInputTimer < BabyDragonTailClimbSettings::CameraStayDurationAfterInput)
			{
				AccInputCameraRotation.Velocity = FRotator::ZeroRotator;
				return;
			}

			RotationDuration = BabyDragonTailClimbSettings::CameraNoInputRotateBackDuration;
		}
		else
		{
			NoCameraInputTimer = 0.0;
			TargetInputRotation.Pitch += BabyDragonTailClimbSettings::MaxCameraInputRotation.Pitch * CameraInputRaw.Y;
			TargetInputRotation.Yaw += BabyDragonTailClimbSettings::MaxCameraInputRotation.Yaw * CameraInputRaw.X;
			RotationDuration = BabyDragonTailClimbSettings::CameraInputRotateDuration;
		}
		AccInputCameraRotation.AccelerateTo(TargetInputRotation, RotationDuration, DeltaTime);
	}
};