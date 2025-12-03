// Handle transition from a non-controlled camera to controlled camera so 
// we don't get weird behavior during blend
class UCameraNonControlledTransitionCapability : UHazeCapability
{

	default CapabilityTags.Add(n"PlayerDefault");
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::CameraNonControlled);
	default CapabilityTags.Add(CameraTags::CameraNonControlledTransition);

	default TickGroup = EHazeTickGroup::BeforeMovement;
    default DebugCategory = CameraTags::Camera;

	FHazeAcceleratedFloat SensitivityFactor;
	bool bHadControl = false;
	float BlendOutTime = 0;
	float BlendOutTimeRemaining = 0;

	UCameraUserComponent User;
	AHazePlayerCharacter PlayerUser;
	UHazeCameraComponent NonControlledCamera;
	UCameraSettings CameraSettings;
	
	// Removing the POI camera for now.
	// It's causing problems going in and out of spline cameras.
	//UHazeCameraComponent POICamera;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		User = UCameraUserComponent::Get(Owner);
		PlayerUser = Cast<AHazePlayerCharacter>(Owner);
		CameraSettings = UCameraSettings::GetSettings(PlayerUser);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// This modifies input, so must only be active on control side
		if (!User.HasControl())
			return false;

		// Activate when blending to a camera not controlled by input
		UHazeCameraComponent CurCam = User.GetActiveCamera();
		if (CurCam == nullptr)
			return false;
		if (CurCam.IsControlledByInput())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!User.HasControl())
			return true;

		// Deactivate once last non-controlled camera has finished blending out
		if (NonControlledCamera == nullptr)
			return true;
		// UHazeCameraComponent CurCam = User.GetActiveCamera();
		// if (CurCam == nullptr)
		// 	return true;
		// if (CurCam.IsControlledByInput())
		// 	return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		NonControlledCamera = User.GetActiveCamera();
		SensitivityFactor.SnapTo(0.0);
		bHadControl = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerUser.ClearCameraSettingsByInstigator(this);
		NonControlledCamera = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float OriginalDeltaTime)
	{
		const float DeltaTime = Time::GetCameraDeltaSeconds();

		UHazeCameraComponent CurCam = User.GetActiveCamera();
		float RemainingBlendTime = User.ActiveCameraRemainingBlendTime;

		if (CurCam.IsControlledByInput())
		{
			if(!bHadControl)
			{
				BlendOutTime = Math::Max(RemainingBlendTime, 0.5);
				BlendOutTimeRemaining = BlendOutTime;
				bHadControl = true;
			}

			// Blending in controlled camera, increase sensitivity factor
			BlendOutTimeRemaining -= DeltaTime;
			float Alpha = RemainingBlendTime / BlendOutTime;
			Alpha = Math::Max(BlendOutTimeRemaining / BlendOutTime, Alpha);
			SensitivityFactor.AccelerateTo(GetAngleAdjustedSensitivityFactor(Alpha), 0.5, DeltaTime);

			if(Alpha < KINDA_SMALL_NUMBER)
				NonControlledCamera = nullptr;
		}
		else
		{
			bHadControl = false;
			NonControlledCamera	= CurCam;
			SensitivityFactor.AccelerateTo(0.0, Math::Max(0.5, RemainingBlendTime), DeltaTime);
		}

		CameraSettings.SensitivityFactor.Apply(SensitivityFactor.Value, this, 0, EHazeCameraPriority::High, 100);
	}	

	float GetAngleAdjustedSensitivityFactor(float RemainingTime)
	{
		// Soft clamp by reducing sensitivity when far from the non-controlled camera's yaw
		FRotator LocalNonControlledRot = User.WorldToLocalRotation(User.GetViewRotation());
		FRotator LocalDesiredRot = User.WorldToLocalRotation(User.GetDesiredRotation());
		float Diff = Math::Abs(FRotator::NormalizeAxis(LocalNonControlledRot.Yaw - LocalDesiredRot.Yaw));
		float Damping = Math::GetMappedRangeValueClamped(FVector2D(0.0, 45.0), FVector2D(0.0, 1.0), Diff);
		Damping *= Math::GetMappedRangeValueClamped(FVector2D(0.0, 0.5), FVector2D(0.0, 1.0), RemainingTime);
		return 1.0 - Damping;
	}

	// void ApplyPointOfInterest(UHazeCameraComponent Camera)
	// {
	// 	POICamera = Camera;
		
	// 	auto POI = PlayerUser.CreatePointOfInterest();
	// 	POI.FocusTarget.FocusComponent(Camera);
	// 	POI.Settings.bMatchFocusDirection = true;
	// 	POI.Settings.TurnScaling.Pitch = 0.0; // Only follow yaw
	// 	POI.Apply(this, Math::Max(0.5, PlayerUser.GetRemainingBlendTime(Camera)));
	// }
}

