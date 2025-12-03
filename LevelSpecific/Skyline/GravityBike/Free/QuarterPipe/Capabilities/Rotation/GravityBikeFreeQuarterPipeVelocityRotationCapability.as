class UGravityBikeFreeQuarterPipeVelocityRotationCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeQuarterPipeComponent QuarterPipeComp;
	UGravityBikeFreeMovementComponent MoveComp;

	FVector RightVector;

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

		return true;
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!QuarterPipeComp.IsJumping())
			return true;

		if(QuarterPipeComp.HasAppliedRotation())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FTransform SplineTransform = QuarterPipeComp.JumpData.Spline.Spline.GetWorldTransformAtSplineDistance(QuarterPipeComp.JumpData.GetHorizontalDistanceAlongSpline());
		const FQuat TargetRotation = FQuat::MakeFromXZ(MoveComp.Velocity, SplineTransform.Rotation.RightVector);

		QuarterPipeComp.ApplyRotationAccelerateTo(TargetRotation, GravityBikeFree::QuarterPipe::VelocityRotationAccelerateDuration, DeltaTime);
	}
};