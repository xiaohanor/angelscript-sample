class UGravityBikeFreeQuarterPipeMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(GravityBikeFree::QuarterPipeTags::GravityBikeFreeQuarterPipe);
	default CapabilityTags.Add(GravityBikeFree::QuarterPipeTags::GravityBikeFreeQuarterPipeMovement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 10;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeQuarterPipeComponent QuarterPipeComp;
	UGravityBikeFreeMovementComponent MoveComp;
	USweepingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		QuarterPipeComp = UGravityBikeFreeQuarterPipeComponent::Get(Owner);
		MoveComp = UGravityBikeFreeMovementComponent::Get(GravityBike);
		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!QuarterPipeComp.JumpData.IsValid())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!QuarterPipeComp.JumpData.IsValid())
			return true;
		
		if(MoveComp.HasAnyValidBlockingContacts())
			return true;	// We hit something, go back to default movement

		if(GravityBike.HasExploded())
			return true;

		if(!QuarterPipeComp.JumpData.Spline.Spline.IsClosedLoop())
		{
			if(QuarterPipeComp.JumpData.GetHorizontalDistanceAlongSpline() > QuarterPipeComp.JumpData.Spline.Spline.SplineLength || QuarterPipeComp.JumpData.GetHorizontalDistanceAlongSpline() < 0)
				return true;	// We went past the start or end of the spline
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GravityBike.BlockCapabilities(GravityBikeFree::Tags::GravityBikeFreeBoost, this);
		GravityBike.BlockCapabilities(GravityBikeFree::Tags::GravityBikeFreeMovement, this);
		GravityBike.BlockCapabilities(GravityBikeFree::Tags::GravityBikeFreeAlignment, this);
		GravityBike.BlockCapabilities(GravityBikeFree::Tags::GravityBikeFreeDrift, this);

		GravityBike.IsAirborne.Apply(true, this);

		QuarterPipeComp.RotationSnapTo(GravityBike.ActorQuat);
		QuarterPipeComp.InitialVelocity = MoveComp.Velocity;
		
		GravityBike.OnTeleported.AddUFunction(this, n"OnTeleported");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GravityBike.UnblockCapabilities(GravityBikeFree::Tags::GravityBikeFreeBoost, this);
		GravityBike.UnblockCapabilities(GravityBikeFree::Tags::GravityBikeFreeMovement, this);
		GravityBike.UnblockCapabilities(GravityBikeFree::Tags::GravityBikeFreeAlignment, this);
		GravityBike.UnblockCapabilities(GravityBikeFree::Tags::GravityBikeFreeDrift, this);

		QuarterPipeComp.Reset();

		GravityBike.IsAirborne.Clear(this);

		GravityBike.OnTeleported.Unbind(this, n"OnTeleported");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector WorldUp = QuarterPipeComp.GetRotation().UpVector;
		if(!MoveComp.PrepareMove(Movement, WorldUp))
			return;

		FQuat SplineRotation = FQuat::Identity;

		if(HasControl())
		{
			// Drag
			QuarterPipeComp.JumpData.AddDrag(GravityBikeFree::QuarterPipe::Drag, DeltaTime);

			// Vertical Movement
			const float Gravity = GravityBikeFree::QuarterPipe::Gravity;
			QuarterPipeComp.JumpData.VerticalSpeed -= (Gravity * DeltaTime);
			QuarterPipeComp.JumpData.VerticalLocation += QuarterPipeComp.JumpData.VerticalSpeed * DeltaTime;

			// Horizontal Movement
			float HorizontalLocation = QuarterPipeComp.JumpData.GetHorizontalDistanceAlongSpline();
			HorizontalLocation += (QuarterPipeComp.JumpData.HorizontalSpeed * DeltaTime);
			QuarterPipeComp.JumpData.SetHorizontalDistanceAlongSpline(HorizontalLocation);

			// Distance from the surface in the normal direction
			QuarterPipeComp.JumpData.NormalLocation = Math::FInterpConstantTo(QuarterPipeComp.JumpData.NormalLocation, GravityBikeFree::QuarterPipe::NormalTargetOffset, DeltaTime, GravityBikeFree::QuarterPipe::NormalLocationInterpSpeed);

			// Get new location relative to the spline
			const FTransform SplineTransform = QuarterPipeComp.JumpData.Spline.Spline.GetWorldTransformAtSplineDistance(QuarterPipeComp.JumpData.GetHorizontalDistanceAlongSpline());
			const FVector NewLocation = SplineTransform.TransformPositionNoScale(FVector(0, QuarterPipeComp.JumpData.NormalLocation, QuarterPipeComp.JumpData.VerticalLocation));
			FVector Delta = NewLocation - GravityBike.ActorLocation;

			// Apply the delta and velocity
			FVector Velocity = Delta / DeltaTime;
			Movement.AddDeltaWithCustomVelocity(Delta, Velocity);

			GravityBike.AccelerateUpTo(QuarterPipeComp.GetRotation().UpVector, 0.1, DeltaTime, this);

			Movement.SetRotation(QuarterPipeComp.GetRotation());

			SplineRotation = SplineTransform.Rotation;
		}
		else
		{
			Movement.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(Movement);

		if(HasControl())
		{
			if(IsCurvatureTooGreat(SplineRotation))
				QuarterPipeComp.JumpData.Invalidate();
		}
	}

	private bool IsCurvatureTooGreat(FQuat SplineRotation) const
	{
		const float PredictionDistance = QuarterPipeComp.JumpData.HorizontalSpeed * GravityBikeFree::QuarterPipe::LeavePredictionDistanceMultiplier;
		const FTransform PredictedSplineTransform = QuarterPipeComp.JumpData.Spline.Spline.GetWorldTransformAtSplineDistance(QuarterPipeComp.JumpData.GetHorizontalDistanceAlongSpline() + PredictionDistance);
		const FQuat PredictedSplineRotation = PredictedSplineTransform.Rotation;
		const FVector PredictedSplineDirection = QuarterPipeComp.JumpData.HorizontalSpeed > 0 ? PredictedSplineRotation.ForwardVector : -PredictedSplineRotation.ForwardVector;
		const FVector PredictedSplineNormal = PredictedSplineRotation.RightVector;

		const FVector SplineDirection = QuarterPipeComp.JumpData.HorizontalSpeed > 0 ? SplineRotation.ForwardVector : -SplineRotation.ForwardVector;

		const bool bIsConvex = SplineDirection.DotProduct(PredictedSplineNormal) > 0;
		float AngleDiffThreshold = bIsConvex ? GravityBikeFree::QuarterPipe::LeaveConvexAngleDiffThreshold : GravityBikeFree::QuarterPipe::LeaveConcaveAngleDiffThreshold;

		float DirectionDelta = PredictedSplineDirection.AngularDistanceForNormals(SplineDirection);
		DirectionDelta = Math::RadiansToDegrees(DirectionDelta);
		DirectionDelta /= PredictionDistance;
		DirectionDelta *= 100;	// Just to get a nicer range

		return Math::Abs(DirectionDelta) > AngleDiffThreshold;
	}

	UFUNCTION()
	private void OnTeleported()
	{
		QuarterPipeComp.JumpData.Invalidate();
	}
}