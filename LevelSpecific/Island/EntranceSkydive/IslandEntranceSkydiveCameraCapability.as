class UIslandEntranceSkydiveCameraCapability : UHazePlayerCapability
{
	// FYI: This is copied from PlayerSkydiveCameraCapability

	default CapabilityTags.Add(CapabilityTags::Camera);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 50;

	UIslandEntranceSkydiveComponent SkydiveComp;
	UPlayerMovementComponent MoveComp;
	UCameraUserComponent CameraUserComp;
	UCameraComponent CameraComp;

	FHazeAcceleratedRotator AcceleratedTargetRotation;
	FHazeAcceleratedFloat AcceleratedIdealDistance;
	FHazeAcceleratedFloat AcceleratedFOV;
	FHazeAcceleratedFloat AcceleratedSpeedEffect;
	FHazeAcceleratedFloat AcceleratedPanningSpeed;
	FHazeAcceleratedFloat AcceleratedCamShake;

	float DefaultIdealDistance;
	float DefaultFOV;

	UCameraShakeBase CamShakeInstance;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SkydiveComp = UIslandEntranceSkydiveComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);
		CameraComp = UCameraComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SkydiveComp.IsSkydiving())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SkydiveComp.IsSkydiving())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UCameraSettings::GetSettings(Player).PivotLagAccelerationDuration.Apply(FVector(0.25, 0.25, 0.25), this, 1);

		DefaultIdealDistance = UCameraSettings::GetSettings(Player).IdealDistance.GetValue();
		DefaultFOV = UCameraSettings::GetSettings(Player).FOV.GetValue();

		AcceleratedTargetRotation.SnapTo(GetTargetDesiredRotation());
		AcceleratedIdealDistance.SnapTo(GetTargetIdealDistance());
		AcceleratedSpeedEffect.SnapTo(GetTargetShimmer());
		AcceleratedPanningSpeed.SnapTo(GetTargetPanningSpeed());
		AcceleratedFOV.SnapTo(GetTargetFOV());
		AcceleratedCamShake.SnapTo(GetTargetCamShakeAlpha());

		// if(SkydiveComp.CameraShake != nullptr)
		// 	CamShakeInstance = Player.PlayCameraShake(SkydiveComp.CameraShake, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UCameraSettings::GetSettings(Player).IdealDistance.Clear(this, 2);
		UCameraSettings::GetSettings(Player).FOV.Clear(this, 2);
		UCameraSettings::GetSettings(Player).PivotLagAccelerationDuration.Clear(this, 2);
		SpeedEffect::ClearSpeedEffect(Player, this);

		Player.StopCameraShakeByInstigator(this);

		// if(MoveComp.HasCustomMovementStatus(n"Swimming"))
		// {
		// 	if(SkydiveComp.ForceFeedback_WaterLanding != nullptr)
		// 		Player.PlayForceFeedback(SkydiveComp.ForceFeedback_WaterLanding, false, true, this);
			
		// 	if(SkydiveComp.CamShake_WaterLanding != nullptr)
		// 		Player.PlayCameraShake(SkydiveComp.CamShake_WaterLanding, this);
		// }	
		// else if(MoveComp.IsOnWalkableGround())
		// {
		// 	if(SkydiveComp.ForceFeedback_GroundedLanding != nullptr)
		// 		Player.PlayForceFeedback(SkydiveComp.ForceFeedback_GroundedLanding, false, true, this);
		
		// 	if(SkydiveComp.ForceFeedback_GroundedLanding != nullptr)
		// 		Player.PlayCameraShake(SkydiveComp.CamShake_GroundedLanding, this);
		// }
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateDesiredRotation(DeltaTime);
		UpdateSpeedEffect(DeltaTime);
		UpdateIdealDistance(DeltaTime);
		UpdateFOV(DeltaTime);
		UpdateCameraShakeScale(DeltaTime);
	}

	void UpdateFOV(float DeltaTime)
	{
		float TargetFOV = GetTargetFOV();
		AcceleratedFOV.AccelerateTo(TargetFOV, 2, DeltaTime);

		UCameraSettings::GetSettings(Player).FOV.Apply(AcceleratedFOV.Value, this);
	}

	void UpdateCameraShakeScale(float DeltaTime)
	{
		if(CamShakeInstance == nullptr)
			return;

		float CamShakeScaleAlpha = GetTargetCamShakeAlpha();
		float CurrentShakeScale = AcceleratedCamShake.AccelerateTo(CamShakeScaleAlpha, 4.5, DeltaTime);
		
		CamShakeInstance.ShakeScale = CurrentShakeScale;
	}

	void UpdateDesiredRotation(float DeltaTime)
	{
		if(Player.IsAnyCapabilityActive(CameraTags::CameraPointOfInterest))
			return;

		FRotator TargetRotation = GetTargetDesiredRotation();

		AcceleratedTargetRotation.Value = CameraUserComp.DesiredRotation;
		AcceleratedTargetRotation.AccelerateTo(TargetRotation, 4.5, DeltaTime);
		CameraUserComp.SetDesiredRotation(AcceleratedTargetRotation.Value, this);
	}

	void UpdateSpeedEffect(float DeltaTime)
	{
		float TargetShimmer = GetTargetShimmer();
		float TargetPanningSpeed = GetTargetPanningSpeed();

		if(SkydiveComp.IsSpeedEffectBlocked())
		{
			TargetShimmer = 0;
		}

		AcceleratedSpeedEffect.AccelerateTo(TargetShimmer, 4 , DeltaTime);
		AcceleratedPanningSpeed.AccelerateTo(TargetPanningSpeed, 4, DeltaTime);

		SpeedEffect::RequestSpeedEffect(Player, AcceleratedSpeedEffect.Value, this, EInstigatePriority::Normal, AcceleratedPanningSpeed.Value);
	}

	void UpdateIdealDistance(float DeltaTime)
	{
		float TargetDistance = GetTargetIdealDistance();

		float NewDistance = AcceleratedIdealDistance.AccelerateTo(TargetDistance, 4.5, DeltaTime);
		UCameraSettings::GetSettings(Player).IdealDistance.Apply(NewDistance, this);
	}

	float GetTargetIdealDistance() const
	{
		return Math::GetMappedRangeValueClamped(FVector2D(0, MoveComp.GetTerminalVelocity()),FVector2D(DefaultIdealDistance, SkydiveComp.Settings.IdealDistance), MoveComp.VerticalVelocity.Size());
	}

	float GetTargetShimmer() const
	{
		float TargetShimmer = Math::Abs(MoveComp.Velocity.Z) / (MoveComp.GetTerminalVelocity());
		TargetShimmer = Math::Clamp(TargetShimmer, 0, 1);
		TargetShimmer *= SkydiveComp.Settings.SpeedShimmerMultiplier;
		return TargetShimmer;
	}

	float GetTargetPanningSpeed() const
	{
		float TargetPanningSpeed = Math::Abs(MoveComp.Velocity.Z) / (MoveComp.GetTerminalVelocity());
		TargetPanningSpeed = Math::Clamp(TargetPanningSpeed, 0, 1);
		TargetPanningSpeed *= SkydiveComp.Settings.SpeedEffectPanningMultiplier;
		return TargetPanningSpeed;
	}

	FRotator GetTargetDesiredRotation() const
	{
		FVector TargetDirection = Owner.ActorForwardVector;

		FVector Axis = MoveComp.WorldUp.CrossProduct(TargetDirection).GetSafeNormal();
		float Angle = Math::DegreesToRadians(SkydiveComp.Settings.CameraPitchDegrees);
		FQuat RotationQuat = FQuat(Axis, Angle);

		TargetDirection = RotationQuat * TargetDirection;
		FRotator TargetRotation = FRotator::MakeFromX(TargetDirection);
		return TargetRotation;
	}

	float GetTargetCamShakeAlpha() const
	{
		float CamShakeScaleAlpha = Math::Abs(MoveComp.VerticalVelocity.Size() / MoveComp.GetTerminalVelocity());
		CamShakeScaleAlpha = Math::Clamp(CamShakeScaleAlpha, 0, 1);
		return CamShakeScaleAlpha;
	}

	float GetTargetFOV() const
	{
		return Math::GetMappedRangeValueClamped(FVector2D(0.0, MoveComp.GetTerminalVelocity()), FVector2D(DefaultFOV, SkydiveComp.Settings.FOV), MoveComp.VerticalVelocity.Size());
	}
}