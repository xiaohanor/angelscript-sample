struct FFallSandFishMovementActivateParams
{
	bool bWasProgressPoint;
}

class UFallSandFishMovementCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	AVortexSandFish SandFish;
	FHazeAcceleratedTransform AccRelativeOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SandFish = Cast<AVortexSandFish>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FFallSandFishMovementActivateParams& Params) const
	{
		if(Desert::GetDesertLevelState() != EDesertLevelState::Fall)
			return false;

		Params.bWasProgressPoint = Desert::GetDesertLevelState() == Desert::GetDesertProgressPointLevelState();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Desert::GetDesertLevelState() != EDesertLevelState::Fall)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FFallSandFishMovementActivateParams Params)
	{
		SandFish.bIsFalling = true;

		if(Params.bWasProgressPoint)
		{
			SandFish.FallDistanceAlongSpline = 0;
			AccRelativeOffset.SnapTo(FTransform::Identity);
		}
		else
		{
			SandFish.FallDistanceAlongSpline = SandFish.FallSpline.Spline.GetClosestSplineDistanceToWorldLocation(SandFish.ActorLocation);
			const FTransform SplineTransform = SandFish.FallSpline.Spline.GetWorldTransformAtSplineDistance(SandFish.FallDistanceAlongSpline);
			const FTransform RelativeTransform = SandFish.ActorTransform.GetRelativeTransform(SplineTransform);
			AccRelativeOffset.SnapTo(RelativeTransform);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SandFish.FallDistanceAlongSpline += FallSandFish::MoveSpeed * DeltaTime;

		const FTransform SplineTransform = SandFish.FallSpline.Spline.GetWorldTransformAtSplineDistance(SandFish.FallDistanceAlongSpline);
		
		AccRelativeOffset.AccelerateTo(FTransform::Identity, 5, DeltaTime);
		const FTransform NewTransform = AccRelativeOffset.Value * SplineTransform;
		
		SandFish.SetActorLocationAndRotation(NewTransform.Location, NewTransform.Rotation);
	}
};