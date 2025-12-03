struct FGravityBikeFreeQuarterPipeJumpDistanceAndAlphaEntry
{
	float Distance;
	float Alpha;
}

struct FGravityBikeFreeQuarterPipeJumpData
{
	private bool bIsValid = false;
	private bool bLanded = false;

	AGravityBikeFreeQuarterPipeSplineActor Spline;

	private float HorizontalDistanceAlongSpline;
	float VerticalLocation;
	float NormalLocation;

	float HorizontalSpeed;
	float VerticalSpeed;

	uint JumpStartedFrame;

	FGravityBikeFreeQuarterPipeJumpData(AGravityBikeFreeQuarterPipeSplineActor InSpline, FVector InInitialLocation, FVector InInitialVelocity)
	{
		Spline = InSpline;

		HorizontalDistanceAlongSpline = Spline.Spline.GetClosestSplineDistanceToWorldLocation(InInitialLocation);
		const FTransform SplineTransform = Spline.Spline.GetWorldTransformAtSplineDistance(HorizontalDistanceAlongSpline);

		const FVector RelativeLocation = SplineTransform.InverseTransformPositionNoScale(InInitialLocation);
		VerticalLocation = RelativeLocation.Z;
		NormalLocation = RelativeLocation.Y;

		// Get the velocity relative to the spline
		const FVector RelativeVelocity = SplineTransform.InverseTransformVectorNoScale(InInitialVelocity);
		HorizontalSpeed = RelativeVelocity.X;
		VerticalSpeed = RelativeVelocity.Z;

		JumpStartedFrame = Time::FrameNumber;

		bIsValid = true;
	}

	void AddDrag(float DragFactor, float DeltaTime)
	{
		const float IntegratedDragFactor = Math::Exp(-DragFactor);
		FVector RelativeVelocity = FVector(HorizontalSpeed, 0, VerticalSpeed);
		FVector NewVelocity = RelativeVelocity * Math::Pow(IntegratedDragFactor, DeltaTime);
		FVector Drag = NewVelocity - RelativeVelocity;

		Drag = Drag.GetClampedToMaxSize(RelativeVelocity.Size());

		NewVelocity -= Drag;
		HorizontalSpeed = NewVelocity.X;
		VerticalSpeed = NewVelocity.Z;
	}

	void SetHorizontalDistanceAlongSpline(float InHorizontalDistanceAlongSpline)
	{
		if(!IsValid())
			return;

		if(Spline.Spline.IsClosedLoop())
			HorizontalDistanceAlongSpline = Math::Wrap(InHorizontalDistanceAlongSpline, 0, Spline.Spline.SplineLength);
		else
			HorizontalDistanceAlongSpline = InHorizontalDistanceAlongSpline;
	}

	float GetHorizontalDistanceAlongSpline() const
	{
		return HorizontalDistanceAlongSpline;
	}

	void Invalidate()
	{
		bIsValid = false;
	}

	void FinishJump()
	{
		bLanded = true;
		Invalidate();
	}

	bool IsValid() const
	{
		if(!bIsValid)
			return false;

		return true;
	}

	bool HasLanded() const
	{
		return bLanded;
	}

	#if EDITOR
	void WriteToTemporalLog(FTemporalLog& TemporalLog, FString Prefix) const
	{
		TemporalLog.Value(f"{Prefix};Is Valid", bIsValid);
		TemporalLog.Value(f"{Prefix};Landed", bLanded);

		TemporalLog.Value(f"{Prefix};Spline", Spline);

		TemporalLog.Value(f"{Prefix};Horizontal Distance Along Spline", HorizontalDistanceAlongSpline);
		TemporalLog.Value(f"{Prefix};Vertical Location", VerticalLocation);
		TemporalLog.Value(f"{Prefix};Normal Location", NormalLocation);
		
		TemporalLog.Value(f"{Prefix};Horizontal Speed", HorizontalSpeed);
		TemporalLog.Value(f"{Prefix};Vertical Speed", VerticalSpeed);

		TemporalLog.Value(f"{Prefix};Jump Started Frame", JumpStartedFrame);
	}
	#endif
}