class UClimbSandFishMovementCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	//default CapabilityTags.Add(ArenaSandFish::Tags::ArenaSandFishDefaultMovement);
	//default CapabilityTags.Add(ArenaSandFish::Tags::ArenaSandFishGroundMovement);

	AVortexSandFish SandFish;
	FHazeAcceleratedTransform AccRelativeOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SandFish = Cast<AVortexSandFish>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Desert::GetDesertLevelState() != EDesertLevelState::Climb)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Desert::GetDesertLevelState() != EDesertLevelState::Climb)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SandFish.ClimbDistanceAlongSpline = SandFish.ClimbSpline.Spline.GetClosestSplineDistanceToWorldLocation(SandFish.ActorLocation);
		const FTransform SplineTransform = SandFish.ClimbSpline.Spline.GetWorldTransformAtSplineDistance(SandFish.ClimbDistanceAlongSpline);
		const FTransform RelativeTransform = SandFish.ActorTransform.GetRelativeTransform(SplineTransform);
		AccRelativeOffset.SnapTo(RelativeTransform);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SandFish.ClimbDistanceAlongSpline = (SandFish.ClimbDistanceAlongSpline + ClimbSandFish::MaxMoveSpeed * DeltaTime) % SandFish.ClimbSpline.Spline.SplineLength; 

		const FTransform SplineTransform = SandFish.ClimbSpline.Spline.GetWorldTransformAtSplineDistance(SandFish.ClimbDistanceAlongSpline);

		AccRelativeOffset.AccelerateTo(FTransform::Identity, 5, DeltaTime);
		const FTransform NewTransform = AccRelativeOffset.Value * SplineTransform;

		SandFish.SetActorLocationAndRotation(NewTransform.Location, NewTransform.Rotation);
	}
};