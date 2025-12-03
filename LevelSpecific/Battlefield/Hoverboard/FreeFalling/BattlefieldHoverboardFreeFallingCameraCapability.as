class UBattlefieldHoverboardFreeFallingCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CameraTags::Camera);

	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::StickInput);

    default DebugCategory = n"Hoverboard";

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 0;

	UBattlefieldHoverboardFreeFallingComponent FreeFallComp;
	UPlayerMovementComponent MoveComp;
	UCameraUserComponent CameraUser;

	FHazeAcceleratedRotator AccCameraRotation;
	FHazeAcceleratedRotator AccInputCameraRotation;

	FRotator StartViewRotation;

	UBattlefieldHoverboardCameraControlSettings CameraControlSettings;

	const float CameraTargetPitch = 85.0;
	const float CameraRotationDuration = 4.5;
	const float CameraRotateBackDuration = 3.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FreeFallComp = UBattlefieldHoverboardFreeFallingComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);

		CameraUser = UCameraUserComponent::Get(Player);

		CameraControlSettings = UBattlefieldHoverboardCameraControlSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl())
			return false;

		if(!FreeFallComp.bIsFreeFalling)
			return false;

		if(!CameraUser.CanControlCamera())
			return false;

		if(Player.HasActivePointOfInterest(UHazePointOfInterestBase))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CameraUser.CanControlCamera())
			return true;

		if(Player.HasActivePointOfInterest(UHazePointOfInterestBase))
			return true;
		
		if(!FreeFallComp.bIsFreeFalling)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccCameraRotation.SnapTo(CameraUser.GetViewRotation());
		StartViewRotation = CameraUser.ViewRotation;

		if (FreeFallComp.bSnapCamera)
		{
			FRotator CameraRotationTarget = Player.ActorRotation;
			CameraRotationTarget.Pitch = -70;
			AccCameraRotation.SnapTo(CameraRotationTarget);
			Player.SnapCameraBehindPlayerWithCustomOffset(CameraRotationTarget);
			Player.ApplyBlendToCurrentView(0.0);
		}
		else	
		{
			if (FreeFallComp.bIsComingFromCutscene)
				Player.ApplyBlendToCurrentView(1.5);
			else
				Player.ApplyBlendToCurrentView(1.0);
		}

		auto HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		HoverboardComp.SetCameraWantedRotationToWantedRotation();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FHazeCameraImpulse CamImpulse;
		CamImpulse.WorldSpaceImpulse = FVector(0.0, 0.0, -1575.0);
		CamImpulse.ExpirationForce = 15.5;
		CamImpulse.Dampening = 1.0;
		Player.ApplyCameraImpulse(CamImpulse, this);
		Player.ApplyBlendToCurrentView(1.0);
		FreeFallComp.bSnapCamera = false;
		FreeFallComp.bIsComingFromCutscene = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(CameraUser.CanApplyUserInput())
		{
			const float CameraDeltaTime = Time::CameraDeltaSeconds;

			if(!FreeFallComp.bIsApproachingGround)
			{
				FRotator CameraRotationTarget = Player.ActorRotation;
				CameraRotationTarget.Pitch = -CameraTargetPitch;
				AccCameraRotation.AccelerateTo(CameraRotationTarget, CameraRotationDuration, CameraDeltaTime);
			}
			else
			{
				FRotator CameraRotationTarget = Player.ActorRotation;
				CameraRotationTarget.Pitch = 0;
				AccCameraRotation.AccelerateTo(CameraRotationTarget, CameraRotationDuration, CameraDeltaTime);
			}

			FVector2D CameraInputRaw = Player.GetCameraInput();
			FRotator InputRotation;
			InputRotation.Pitch += CameraControlSettings.InputRotationMax.Pitch * CameraInputRaw.Y;
			InputRotation.Yaw += CameraControlSettings.InputRotationMax.Yaw * CameraInputRaw.X;
			AccInputCameraRotation.AccelerateTo(InputRotation, CameraControlSettings.InputRotationDuration, CameraDeltaTime);

			FRotator CameraRotation = AccCameraRotation.Value + AccInputCameraRotation.Value;
		
			FRotator DeltaRotation = CameraRotation - Player.ViewRotation;

			CameraUser.AddUserInputDeltaRotation(DeltaRotation, this);
		}
	}
};