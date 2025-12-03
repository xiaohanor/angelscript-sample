/**
 * Attraction when we do a magnetic jump between two magnetic surfaces.
 */
class UMagnetDroneAttractionModeJump : UMagnetDroneAttractionMode
{
	default TickOrder = 50;
	default bAllowWhileAttached = true;

	float AttractionStartVerticalImpulse;
	float JumpImpulse;
	FHazeAcceleratedVector AccLocation;

	const FVector2D SpringStiffness = FVector2D(0, 30);
	const FVector2D SpringDamping = FVector2D(0, 0.05);

	bool ShouldActivate(FMagnetDroneAttractionModeShouldActivateParams Params) const override
	{
		if(!Super::ShouldActivate(Params))
			return false;
		
		if(Params.Instigator != EMagnetDroneStartAttractionInstigator::Jump)
			return false;

		return true;
	}

	protected bool PrepareAttraction(FMagnetDroneAttractionModePrepareAttractionParams& Params, float&out OutPathLength, float&out OutTimeUntilArrival) override
	{
		AttractionStartVerticalImpulse = Params.AttractionSettings.AttractionStartVerticalImpulse;
		JumpImpulse = MovementSettings.JumpImpulse;

		if(!Super::PrepareAttraction(Params, OutPathLength, OutTimeUntilArrival))
			return false;

		const FVector ToTarget = (AttractionTarget.GetTargetLocation() - Params.InitialLocation).GetSafeNormal();
		Params.InitialVelocity = ToTarget * JumpImpulse;
		AccLocation.SnapTo(InitialLocation, GetStartTangent());

		return true;
	}

	protected FVector TickAttraction(FMagnetDroneAttractionModeTickAttractionParams Params, float DeltaTime, float& AttractionAlpha) override
	{
		AccLocation.SnapTo(Params.CurrentLocation, Params.CurrentVelocity);
		AccLocation.SpringTo(
			AttractionTarget.GetTargetLocation(),
			SpringStiffness.Y,
			SpringDamping.Y,
			DeltaTime);

		if(!IsInFrontOfTarget(AccLocation.Value))
		{
			AttractionAlpha = 1.0;
			return GetEndLocation();
		}

		// if(AccLocation.Value.Distance(GetEndLocation()) < MagnetDrone::Radius)
		// {
		// 	AttractionAlpha = 1.0;
		// 	return GetEndLocation();
		// }

		return AccLocation.Value;
	}

	FVector GetTargetPlaneNormal() const
	{
		return (GetStartLocation() - GetEndLocation()).GetSafeNormal();
	}

	bool IsInFrontOfTarget(FVector CurrentLocation) const
	{
		const FVector TargetNormal = GetTargetPlaneNormal();
		const FPlane TargetPlane = FPlane(GetEndLocation(), TargetNormal);
		return TargetPlane.PlaneDot(CurrentLocation) > 0;
	}

	FVector GetStartTangent() const override
	{
		return InitialVelocity;
	}

	FVector GetEndTangent() const override
	{
		return AttractionTarget.GetTargetImpactNormal() * -JumpImpulse;
	}

#if !RELEASE
	void LogToTemporalLog(FTemporalLog TemporalLog, FMagnetDroneAttractionModeLogParams Params) const override
	{
		Super::LogToTemporalLog(TemporalLog, Params);

		TemporalLog.Sphere("AccLocation", AccLocation.Value, MagnetDrone::Radius);
		TemporalLog.DirectionalArrow("AccLocation Velocity", AccLocation.Value, AccLocation.Velocity);
		TemporalLog.Sphere("Target Location", AttractionTarget.GetTargetLocation(), MagnetDrone::Radius);

		TemporalLog.Value("IsInFrontOfTarget", IsInFrontOfTarget(Params.CurrentLocation));
		TemporalLog.DirectionalArrow("TargetPlaneNormal", GetEndLocation(), GetTargetPlaneNormal(), 500, 20);
		TemporalLog.Plane("TargetPlane", GetEndLocation(), GetTargetPlaneNormal());
	}
#endif
}