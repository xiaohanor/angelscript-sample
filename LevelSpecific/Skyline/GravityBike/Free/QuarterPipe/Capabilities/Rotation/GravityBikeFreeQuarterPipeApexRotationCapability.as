class UGravityBikeFreeQuarterPipeApexRotationCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 90;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeQuarterPipeComponent QuarterPipeComp;
	UGravityBikeFreeMovementComponent MoveComp;

	FQuat InitialRotation;
	bool bInvertRoll = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		QuarterPipeComp = UGravityBikeFreeQuarterPipeComponent::Get(GravityBike);
		MoveComp = UGravityBikeFreeMovementComponent::Get(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;
		
		if(!QuarterPipeComp.IsJumping())
			return false;

		if(QuarterPipeComp.HasAppliedRotation())
			return false;

		if(!QuarterPipeComp.IsVertical())
			return false;

		// Wait until we slowed down
		if(QuarterPipeComp.JumpData.VerticalSpeed > GravityBikeFree::QuarterPipe::ApexMaximumVerticalSpeed)
			return false;

		// If we are falling, never trigger
		if(QuarterPipeComp.JumpData.VerticalSpeed < GravityBikeFree::QuarterPipe::ApexMinimumVerticalSpeed)
			return false;

		// And wait until we reached a certain height
		if(QuarterPipeComp.JumpData.VerticalLocation < GravityBikeFree::QuarterPipe::ApexRotationDuration)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!QuarterPipeComp.IsJumping())
			return true;

		if(QuarterPipeComp.HasAppliedRotation())
			return true;

		if(ActiveDuration > GravityBikeFree::QuarterPipe::ApexRotationDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		InitialRotation = GravityBike.ActorQuat;
		bInvertRoll = QuarterPipeComp.JumpData.HorizontalSpeed > 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = ActiveDuration / GravityBikeFree::QuarterPipe::ApexRotationDuration;

		// Rotation animation is just two alphas
		float RollAlpha = Math::SmoothStep(0, 1, Alpha);
		RollAlpha = bInvertRoll ? -RollAlpha : RollAlpha;
		float PitchAlpha = Math::EaseOut(0, 1, Alpha, 2);

		// We need to rotate the reference rotation during the flip to aim towards the correct direction at the end
		const FQuat SplineRotation = QuarterPipeComp.JumpData.Spline.Spline.GetWorldRotationAtSplineDistance(QuarterPipeComp.JumpData.GetHorizontalDistanceAlongSpline());

		// Check what angle the initial rotation is from vertical
		float AngleFromVertical = InitialRotation.ForwardVector.AngularDistance(FVector::UpVector);
		AngleFromVertical = bInvertRoll ? -AngleFromVertical : AngleFromVertical;
		// Then flip it around the jump normal
		const FQuat FlippedRotation = FQuat(SplineRotation.RightVector, AngleFromVertical * 2) * InitialRotation;

		// Rotate the reference over the jump duration
		const FQuat ReferenceRotation = FQuat::Slerp(InitialRotation, FlippedRotation, Alpha);

		const FQuat RollRotation = FQuat(ReferenceRotation.ForwardVector, RollAlpha * PI);
		const FQuat PitchRotation = FQuat(ReferenceRotation.RightVector, PitchAlpha * -PI);
		const FQuat Rotation = PitchRotation * RollRotation * ReferenceRotation;
		
		QuarterPipeComp.ApplyRotationAccelerateTo(Rotation, GravityBikeFree::QuarterPipe::ApexRotationAccelerateDuration, DeltaTime);
	}
};