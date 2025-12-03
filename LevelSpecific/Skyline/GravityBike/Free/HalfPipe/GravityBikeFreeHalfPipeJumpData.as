struct FGravityBikeFreeHalfPipeJumpData
{
	bool bIsValid = false;
	bool bLanded = false;

	const UGravityBikeFreeHalfPipeTriggerComponent FromTrigger;
	const UGravityBikeFreeHalfPipeTriggerComponent ToTrigger;

	FVector FromLocation;
	FVector FromTangent;

	FVector ToLocation;
	FVector ToTangent;

	float JumpTrajectoryDistance;

	FVector GetStartDirection() const
	{
		return FromTangent.GetSafeNormal();
	}

	// FB TODO: Horribly optimized, can we use something like FHazeRuntimeSpline instead?
	float CalculateJumpTrajectoryDistance(int Resolution = 30) const
	{
		float Distance = 0;
		for(int i = 0; i < Resolution; i++)
		{
			const float StartAlpha = i / float(Resolution);
			const float EndAlpha = (i + 1.0) / float(Resolution);

			const FVector Start = CubicInterpolationAlpha(StartAlpha);
			const FVector End = CubicInterpolationAlpha(EndAlpha);
			Distance += Start.Distance(End);
		}

		return Distance;
	}

	// FB TODO: Horribly optimized, can we use something like FHazeRuntimeSpline instead?
	FVector GetJumpTrajectoryDirection(float Distance) const
	{
		const FVector Start = CubicInterpolationDistance(Distance);
		const FVector End = CubicInterpolationDistance(Distance + 100);
		return (End - Start).GetSafeNormal();
	}

	bool IsJumpingToTrigger(UGravityBikeFreeHalfPipeTriggerComponent InToTrigger) const
	{
		if(!IsValid())
			return false;

		return ToTrigger == InToTrigger;
	}

	FVector CubicInterpolationAlpha(float Alpha) const
	{
		return Math::CubicInterp(FromLocation, FromTangent, ToLocation, ToTangent, Alpha);
	}

	FVector CubicInterpolationDistance(float Distance) const
	{
		const float Alpha = Distance / JumpTrajectoryDistance;
		return CubicInterpolationAlpha(Alpha);
	}

	FVector GetJumpCenterLocation() const
	{
		return (FromTrigger.WorldEdgeCenterLocation + ToTrigger.WorldEdgeCenterLocation) * 0.5;
	}

	FVector GetTargetLocation() const
	{
		return ToLocation;
	}

	FVector GetTargetNormal() const
	{
		return ToTrigger.EdgeNormal;
	}

	FVector GetJumpTangent() const
	{
		FVector JumpUp = (FromTrigger.UpVector + ToTrigger.UpVector).GetSafeNormal();
		return JumpUp.CrossProduct(ToLocation - FromLocation).GetSafeNormal();
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

		if(FromTrigger.IsDisabled.Get())
			return false;

		if(ToTrigger.IsDisabled.Get())
			return false;

		return true;
	}

	bool HasLanded() const
	{
		return bLanded;
	}
};

namespace FGravityBikeFreeHalfPipeJumpData
{
	FGravityBikeFreeHalfPipeJumpData MakeJumpData(
		const UGravityBikeFreeHalfPipeComponent HalfPipeComp,
		const UGravityBikeFreeHalfPipeTriggerComponent InFromTrigger,
		FVector InFromLocation,
		FVector InInitialVelocity,
		const UGravityBikeFreeHalfPipeTriggerComponent InToTrigger
	)
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(HalfPipeComp);
		TemporalLog
			.Value("From;Trigger", InFromTrigger)
			.Point("From;Location", InFromLocation)
			.DirectionalArrow("From;Velocity", InFromLocation, InInitialVelocity)
			.Value("To;Trigger", InToTrigger)
		;
#endif

		FGravityBikeFreeHalfPipeJumpData JumpData;

		JumpData.FromTrigger = InFromTrigger;
		JumpData.FromLocation = InFromLocation;

		const float VelocityToUpAngle = InInitialVelocity.GetSafeNormal().GetAngleDegreesTo(InFromTrigger.UpVector);

		FVector RelativeFromLocation = InFromTrigger.WorldTransform.InverseTransformPosition(InFromLocation);
		RelativeFromLocation /= InFromTrigger.Shape.BoxExtents;

		if(RelativeFromLocation.Z < 0.9)
		{
#if !RELEASE
			const FString Result = f"Was not top face of the trigger. Relative Z: {RelativeFromLocation.Z}. Invalid.";
			TemporalLog.Event(Result);
			TemporalLog.Status(Result, FLinearColor::Red);
#endif
			return JumpData;
		}

		// Angle Threshold
		if(VelocityToUpAngle > GravityBikeFree::HalfPipe::AngleThreshold)
		{
#if !RELEASE
			const FString Result = f"Angle to Up too high. Angle: {VelocityToUpAngle}, Threshold: {GravityBikeFree::HalfPipe::AngleThreshold}. Invalid.";
			TemporalLog.Event(Result);
			TemporalLog.Status(Result, FLinearColor::Red);
#endif
			return JumpData;
		}

		const float SpeedTowardsUp = InInitialVelocity.DotProduct(InFromTrigger.UpVector);

		// Minimum Vertical Speed
		if(SpeedTowardsUp < GravityBikeFree::HalfPipe::MinimumVerticalSpeed)
		{
#if !RELEASE
			const FString Result = f"Speed too low. Speed: {SpeedTowardsUp}, Threshold: {GravityBikeFree::HalfPipe::MinimumVerticalSpeed}. Invalid.";
			TemporalLog.Event(Result);
			TemporalLog.Status(Result, FLinearColor::Red);
#endif
			return JumpData;
		}

		const FVector VelocityAlongRamp = InInitialVelocity.VectorPlaneProject(JumpData.FromTrigger.ForwardVector);
		JumpData.FromTangent = VelocityAlongRamp * GravityBikeFree::HalfPipe::TangentMultiplier;

		// If the tangent is not vertical enough, we adjust it
		const float AngleToVertical = VelocityAlongRamp.GetAngleDegreesTo(JumpData.FromTrigger.UpVector);
		if(AngleToVertical > GravityBikeFree::HalfPipe::MaxAngleToVertical)
		{
			float AdjustAngle = AngleToVertical - GravityBikeFree::HalfPipe::MaxAngleToVertical;
			float Sign = Math::Sign(JumpData.FromTangent.DotProduct(JumpData.FromTrigger.RightVector));

			JumpData.FromTangent = FQuat(JumpData.FromTrigger.ForwardVector, Math::DegreesToRadians(AdjustAngle * Sign)) * JumpData.FromTangent;
		}

		JumpData.ToTrigger = InToTrigger;
		JumpData.ToTangent = FQuat(FVector::UpVector, PI) * JumpData.FromTangent;
		JumpData.ToTangent.Z = -JumpData.ToTangent.Z;

		FPlane ToEdgePlane(InToTrigger.WorldEdgeCenterLocation, InToTrigger.EdgeNormal);	// Make a plane out of the target edge

		const FVector JumpFromLocationOnEdge = Math::ClosestPointOnLine(InFromTrigger.WorldLeftEdgeLocation, InFromTrigger.WorldRightEdgeLocation, InFromLocation);
		const FVector HorizontalDirection = InInitialVelocity.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
		JumpData.ToLocation = ToEdgePlane.RayPlaneIntersection(JumpFromLocationOnEdge, HorizontalDirection);	// Project to the other edge to find where we should hit
		JumpData.ToLocation = Math::ClosestPointOnLine(InToTrigger.WorldLeftEdgeLocation, InToTrigger.WorldRightEdgeLocation, JumpData.ToLocation);	// Constrain to edge to prevent missing the other jump

		const FVector EdgeOffset = InToTrigger.EdgeNormal * GravityBikeFree::HalfPipe::TargetNormalOffset;
		JumpData.ToLocation += EdgeOffset;

		JumpData.JumpTrajectoryDistance = JumpData.CalculateJumpTrajectoryDistance();

#if !RELEASE
		TemporalLog
			.DirectionalArrow("From;Tangent", InFromLocation, JumpData.FromTangent)
			.Point("From;JumpFromLocationOnEdge", JumpFromLocationOnEdge)
			.Plane("To;EdgePlane", InToTrigger.WorldEdgeCenterLocation, ToEdgePlane.Normal)
			.Point("To;Location", JumpData.ToLocation)
			.DirectionalArrow("To;Tangent", JumpData.ToLocation, JumpData.ToTangent)
			.Arrow("To;Edge Offset", JumpData.ToLocation - EdgeOffset, JumpData.ToLocation)
			.Value("JumpTrajectoryDistance", JumpData.JumpTrajectoryDistance)
			.Value("RelativeFromLocation", RelativeFromLocation)
			.Event("Created a valid JumpData!")
			.Status("Valid!", FLinearColor::Green)
		;
#endif

		JumpData.bIsValid = true;

		return JumpData;
	}
}