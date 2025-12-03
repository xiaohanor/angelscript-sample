class UGravityBikeFreeQuarterPipeVerticalCameraCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(GravityBikeFree::QuarterPipeTags::GravityBikeFreeQuarterPipe);
	default CapabilityTags.Add(GravityBikeFree::QuarterPipeTags::GravityBikeFreeQuarterPipeCamera);

	default TickGroup = EHazeTickGroup::Gameplay;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeQuarterPipeComponent QuarterPipeComp;
	UGravityBikeFreeMovementComponent MoveComp;
	
	UGravityBikeFreeCameraDataComponent CameraDataComp;

	float TimeUntilApex;
	const float ApexDuration = 0.5;
	uint LastJumpFrame;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		QuarterPipeComp = UGravityBikeFreeQuarterPipeComponent::Get(GravityBike);
		MoveComp = UGravityBikeFreeMovementComponent::Get(GravityBike);

		CameraDataComp = UGravityBikeFreeCameraDataComponent::Get(GravityBike.GetDriver());
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!QuarterPipeComp.IsJumping())
			return false;

		if(!QuarterPipeComp.IsVertical())
			return false;

		if(QuarterPipeComp.JumpData.JumpStartedFrame == LastJumpFrame)
			return false;

		if(CameraDataComp.IsInputting())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!QuarterPipeComp.IsJumping())
			return true;

		if(ActiveDuration > TimeUntilApex + ApexDuration)
			return true;

		if(!QuarterPipeComp.IsVertical())
			return true;

		if(CameraDataComp.IsInputting())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GravityBike.BlockCapabilities(GravityBikeFree::Tags::GravityBikeFreeCamera, this);

		const float InitialVelocity = QuarterPipeComp.JumpData.VerticalSpeed;
		const float Gravity = GravityBikeFree::QuarterPipe::Gravity;
		const float Location = QuarterPipeComp.JumpData.VerticalLocation;
		TimeUntilApex = ((InitialVelocity + Math::Sqrt(Math::Square(InitialVelocity) + (2 * Gravity * Location))) / Gravity) * 0.5;

		LastJumpFrame = QuarterPipeComp.JumpData.JumpStartedFrame;

		CameraDataComp.AccCameraRotation.SnapTo(
			CameraDataComp.GetDesiredRotation().Quaternion(),
			CameraDataComp.AccCameraRotation.VelocityAxisAngle.GetSafeNormal(),
			CameraDataComp.AccCameraRotation.VelocityAxisAngle.Size()
		);

		CameraDataComp.ResetInputOffset();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GravityBike.UnblockCapabilities(GravityBikeFree::Tags::GravityBikeFreeCamera, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
			TickControl(DeltaTime);
	}

	void TickControl(float DeltaTime)
	{
		const FTransform SplineTransform = QuarterPipeComp.JumpData.Spline.Spline.GetWorldTransformAtSplineDistance(QuarterPipeComp.JumpData.GetHorizontalDistanceAlongSpline());
		FQuat TargetRotation = FQuat::MakeFromXZ(SplineTransform.Rotation.RightVector, FVector::UpVector);
		CameraDataComp.AccCameraRotation.AccelerateTo(TargetRotation, TimeUntilApex, DeltaTime);

		CameraDataComp.ApplyDesiredRotation(this);
	}
};