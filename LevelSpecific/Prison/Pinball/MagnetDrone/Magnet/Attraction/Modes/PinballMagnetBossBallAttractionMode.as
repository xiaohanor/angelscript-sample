class UPinballMagnetBossBallAttractionMode : UMagnetDroneAttractionMode
{
	default TickOrder = 70;

#if !RELEASE
	default DebugColor = ColorDebug::Yellow;
#endif

	FHazeAcceleratedVector AccLocation;
	float TimeUntilArrival;

	const float Acceleration = 10000;
	const float LateralVelocityDrag = 5;
	const float TerminalVelocity = 3000;

	void Setup(FMagnetDroneAttractionModeSetupParams Params) override
	{
		Super::Setup(Params);
	}

	bool ShouldActivate(FMagnetDroneAttractionModeShouldActivateParams Params) const override
	{
		if(!Super::ShouldActivate(Params))
			return false;

		const auto PinballBossBall = Cast<APinballBossBall>(Params.AimData.GetActor());
		if(PinballBossBall == nullptr)
			return false;

		return true;
	}

	bool PrepareAttraction(
		FMagnetDroneAttractionModePrepareAttractionParams& Params,
	    float&out OutPathLength,
		float&out OutTimeUntilArrival) override
	{
		AccLocation.SnapTo(InitialLocation, GetStartTangent());

		if(!Super::PrepareAttraction(Params, OutPathLength, OutTimeUntilArrival))
			return false;

		TimeUntilArrival = OutTimeUntilArrival;

		return true;
	}

	FVector TickAttraction(
		FMagnetDroneAttractionModeTickAttractionParams Params,
		float DeltaTime,
	    float& AttractionAlpha) override
	{
		AccLocation.SnapTo(Params.CurrentLocation, Params.CurrentVelocity);
		AccLocation.ThrustTo(GetEndLocation(), Acceleration, DeltaTime, LateralVelocityDrag, TerminalVelocity);

		AttractionAlpha = Math::Saturate(Params.ActiveDuration / TimeUntilArrival);

		// Don't let it finish on it's own, always check
		AttractionAlpha = Math::Min(AttractionAlpha, 0.99);

		FPlane TargetPlane = FPlane(GetEndLocation(), GetEndTangent());
		if(TargetPlane.PlaneDot(AccLocation.Value) < 0)
		{
			AccLocation.Value = AccLocation.Value.PointPlaneProject(TargetPlane.Origin, TargetPlane.Normal);
			AttractionAlpha = 1.0;
		}

		return AccLocation.Value;
	}

	float CalculatePathLength() const override
	{
		return GetStartLocation().Distance(GetEndLocation());
	}

	float CalculateTimeUntilArrival(float PathLength) const override
	{
		FVector ToEnd = (GetEndLocation() - GetStartLocation()).GetSafeNormal();
		float SpeedTowardsEnd = InitialVelocity.DotProduct(ToEnd);
		return Trajectory::GetTimeToReachTarget(PathLength, SpeedTowardsEnd, Acceleration);
	}

	FVector GetEndLocation() const override
	{
		FVector BossBallLocation = AttractionTarget.GetActor().ActorLocation;
		FVector FromBoss = (AccLocation.Value - BossBallLocation).GetSafeNormal();
		FVector BossBallEdgeLocation = BossBallLocation + FromBoss * APinballBossBall::Radius;
		return BossBallEdgeLocation;
	}

	FVector GetEndTangent() const override
	{
		FVector BossBallLocation = AttractionTarget.GetActor().ActorLocation;
		return (AccLocation.Value - BossBallLocation).GetSafeNormal();
	}

#if !RELEASE
	void LogToTemporalLog(FTemporalLog SectionLog, FMagnetDroneAttractionModeLogParams Params) const override
	{
		Super::LogToTemporalLog(SectionLog, Params);
	}
#endif
};