class UPlayerSkyDiveCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(PlayerSkydiveTags::SkydiveCamera);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 50;

	UPlayerAirMotionComponent AirMotionComp;
	UPlayerSkydiveComponent SkydiveComp;
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
		AirMotionComp = UPlayerAirMotionComponent::Get(Player);
		SkydiveComp = UPlayerSkydiveComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);
		CameraComp = UCameraComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SkydiveComp.IsSkydiveActive())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SkydiveComp.IsSkydiveActive())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UCameraSettings::GetSettings(Player).PivotLagAccelerationDuration.Apply(FVector(0.25, 0.25, 0.25), this, 1);

		DefaultIdealDistance = UCameraSettings::GetSettings(Player).IdealDistance.GetValue();
		DefaultFOV = UCameraSettings::GetSettings(Player).FOV.GetValue();

		AcceleratedTargetRotation.SnapTo(CameraComp.WorldRotation);
		AcceleratedIdealDistance.SnapTo(DefaultIdealDistance);
		AcceleratedSpeedEffect.SnapTo(0);
		AcceleratedPanningSpeed.SnapTo(0);
		AcceleratedFOV.SnapTo(DefaultFOV);
		AcceleratedCamShake.SnapTo(0);

		if(SkydiveComp.CameraShake != nullptr)
			CamShakeInstance = Player.PlayCameraShake(SkydiveComp.CameraShake, this);

		//Fetch springarmsettings and cache current pivot offset as default?
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UCameraSettings::GetSettings(Player).IdealDistance.Clear(this, 2);
		UCameraSettings::GetSettings(Player).FOV.Clear(this, 2);
		UCameraSettings::GetSettings(Player).PivotLagAccelerationDuration.Clear(this, 2);
		SpeedEffect::ClearSpeedEffect(Player, this);

		Player.StopCameraShakeByInstigator(this);

		if(MoveComp.HasCustomMovementStatus(n"Swimming"))
		{
			if(SkydiveComp.ForceFeedback_WaterLanding != nullptr)
				Player.PlayForceFeedback(SkydiveComp.ForceFeedback_WaterLanding, false, true, this);
			
			if(SkydiveComp.CamShake_WaterLanding != nullptr)
				Player.PlayCameraShake(SkydiveComp.CamShake_WaterLanding, this);
		}	
		else if(MoveComp.IsOnWalkableGround())
		{
			if(SkydiveComp.ForceFeedback_GroundedLanding != nullptr)
				Player.PlayForceFeedback(SkydiveComp.ForceFeedback_GroundedLanding, false, true, this);
		
			if(SkydiveComp.CamShake_GroundedLanding != nullptr)
				Player.PlayCameraShake(SkydiveComp.CamShake_GroundedLanding, this);
		}
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
		float TargetFOV = Math::GetMappedRangeValueClamped(FVector2D(0.0, MoveComp.GetTerminalVelocity()), FVector2D(DefaultFOV, SkydiveComp.Settings.FOV), MoveComp.VerticalVelocity.Size());
		AcceleratedFOV.AccelerateTo(TargetFOV, 2, DeltaTime);

		UCameraSettings::GetSettings(Player).FOV.Apply(AcceleratedFOV.Value, this);
	}

	void UpdateCameraShakeScale(float DeltaTime)
	{
		if(CamShakeInstance == nullptr)
			return;

		float CamShakeScaleAlpha = Math::Abs(MoveComp.VerticalVelocity.Size() / SkydiveComp.Settings.TerminalVelocity);
		CamShakeScaleAlpha = Math::Clamp(CamShakeScaleAlpha, 0, 1);

		float CurrentShakeScale = AcceleratedCamShake.AccelerateTo(CamShakeScaleAlpha, 4.5, DeltaTime);
		
		CamShakeInstance.ShakeScale = CurrentShakeScale;

		// PrintToScreen("ShakeScale: " + CurrentShakeScale, Color = FLinearColor::DPink);
	}

	void UpdateDesiredRotation(float DeltaTime)
	{
		if(Player.IsAnyCapabilityActive(CameraTags::CameraPointOfInterest))
			return;

		FVector TargetDirection = Owner.ActorForwardVector;

		FVector Axis = MoveComp.WorldUp.CrossProduct(TargetDirection).GetSafeNormal();
		float Angle = Math::DegreesToRadians(SkydiveComp.Settings.CameraPitchDegrees);
		FQuat RotationQuat = FQuat(Axis, Angle);

		TargetDirection = RotationQuat * TargetDirection;
		FRotator TargetRotation = FRotator::MakeFromX(TargetDirection);

		AcceleratedTargetRotation.Value = CameraUserComp.DesiredRotation;
		AcceleratedTargetRotation.AccelerateTo(TargetRotation, 4.5, DeltaTime);
		CameraUserComp.SetDesiredRotation(AcceleratedTargetRotation.Value, this);
	}

	void UpdateSpeedEffect(float DeltaTime)
	{
		float TargetShimmer = Math::Abs(MoveComp.Velocity.Z) / (SkydiveComp.Settings.TerminalVelocity);
		TargetShimmer = Math::Clamp(TargetShimmer, 0, 1);
		TargetShimmer *= SkydiveComp.Settings.SpeedShimmerMultiplier;

		float TargetPanningSpeed = Math::Abs(MoveComp.Velocity.Z) / (SkydiveComp.Settings.TerminalVelocity);
		TargetPanningSpeed = Math::Clamp(TargetPanningSpeed, 0, 1);
		TargetPanningSpeed *= SkydiveComp.Settings.SpeedEffectPanningMultiplier;

		AcceleratedSpeedEffect.AccelerateTo(TargetShimmer, 4 , DeltaTime);
		AcceleratedPanningSpeed.AccelerateTo(TargetPanningSpeed, 4, DeltaTime);

		SpeedEffect::RequestSpeedEffect(Player, AcceleratedSpeedEffect.Value, this, EInstigatePriority::Normal, AcceleratedPanningSpeed.Value);


	}

	void UpdateIdealDistance(float DeltaTime)
	{
		float TargetDistance = Math::GetMappedRangeValueClamped(FVector2D(0, MoveComp.GetTerminalVelocity()),FVector2D(DefaultIdealDistance, SkydiveComp.Settings.IdealDistance), MoveComp.VerticalVelocity.Size());

		float NewDistance = AcceleratedIdealDistance.AccelerateTo(TargetDistance, 4.5, DeltaTime);
		UCameraSettings::GetSettings(Player).IdealDistance.Apply(NewDistance, this);
	}
};