struct FGravityBikeFreeQuarterPipeLandRotationActivateParams
{
	float TimeTilBottom;
}

class UGravityBikeFreeQuarterPipeLandRotationCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 80;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeQuarterPipeComponent QuarterPipeComp;
	UGravityBikeFreeMovementComponent MoveComp;

	FQuat StartRotation;
	float LandRotationDuration;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		QuarterPipeComp = UGravityBikeFreeQuarterPipeComponent::Get(GravityBike);
		MoveComp = UGravityBikeFreeMovementComponent::Get(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBikeFreeQuarterPipeLandRotationActivateParams& Params) const
	{
		if(!HasControl())
			return false;
		
		if(!QuarterPipeComp.IsJumping())
			return false;

		if(QuarterPipeComp.HasAppliedRotation())
			return false;

		if(QuarterPipeComp.JumpData.VerticalSpeed > 0)
			return false;

		const float Velocity = QuarterPipeComp.JumpData.VerticalSpeed;
		const float Gravity = GravityBikeFree::QuarterPipe::Gravity;
		const float Distance = QuarterPipeComp.JumpData.VerticalLocation;

		const float TimeTilBottom = (Velocity + Math::Sqrt(Math::Square(Velocity) + (2 * Gravity * Distance))) / Gravity;
		if(TimeTilBottom > GravityBikeFree::QuarterPipe::LandMaxRotationDuration)
			return false;

		Params.TimeTilBottom = TimeTilBottom;

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
	void OnActivated(FGravityBikeFreeQuarterPipeLandRotationActivateParams Params)
	{
		LandRotationDuration = Params.TimeTilBottom;
		StartRotation = GravityBike.ActorQuat;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FTransform SplineTransform = QuarterPipeComp.JumpData.Spline.Spline.GetWorldTransformAtSplineDistance(QuarterPipeComp.JumpData.GetHorizontalDistanceAlongSpline());

		FQuat TargetRotation = FQuat::MakeFromXZ(MoveComp.Velocity, SplineTransform.Rotation.RightVector);
		TargetRotation = FQuat(-SplineTransform.Rotation.ForwardVector, Math::DegreesToRadians(-GravityBikeFree::QuarterPipe::LandTargetPitch)) * TargetRotation;

		QuarterPipeComp.ApplyRotationAccelerateTo(TargetRotation, LandRotationDuration, DeltaTime);
	}
};