enum EPinballMagnetAttractionState
{
	FlyingBack,
	LaunchingForward
};

/**
 * Will suck the ball to the nearest magnetic surface
 */
class UPinballMagnetDefaultAttractionMode : UMagnetDroneAttractionMode
{
	default TickOrder = 100;

#if !RELEASE
	default DebugColor = FLinearColor::LucBlue;
#endif

	UPinballMagnetDroneComponent PinballComp;

	FHazeAcceleratedVector AccLocation;
	float TimeUntilArrival;

	EPinballMagnetAttractionState AttractionState;
	float StartSpringingBackDistance;
	float StartSpringingBackAlpha;

	const float AttractionAlphaPow = 2.5;

	void Setup(FMagnetDroneAttractionModeSetupParams Params) override
	{
		Super::Setup(Params);

		PinballComp =UPinballMagnetDroneComponent::Get(Params.Player);
	}

	bool ShouldActivate(FMagnetDroneAttractionModeShouldActivateParams Params) const override
	{
		if(!Super::ShouldActivate(Params))
			return false;

		return true;
	}

	protected bool PrepareAttraction(FMagnetDroneAttractionModePrepareAttractionParams& Params, float&out OutPathLength, float&out OutTimeUntilArrival) override
	{
		if(!Super::PrepareAttraction(Params, OutPathLength, OutTimeUntilArrival))
			return false;
	
		PrepareFlyingBack();

		TimeUntilArrival = OutTimeUntilArrival;
		
		return true;
	}

	protected FVector TickAttraction(FMagnetDroneAttractionModeTickAttractionParams Params, float DeltaTime, float& AttractionAlpha) override
	{
		const float TimeAlpha = Math::Saturate(Params.ActiveDuration / TimeUntilArrival);
		AttractionAlpha = Math::Max(AttractionAlpha, TimeAlpha);
		AttractionAlpha = Math::Min(AttractionAlpha, 0.99);
		
		switch(AttractionState)
		{
			case EPinballMagnetAttractionState::FlyingBack:
				return TickFlyingBack(Params, DeltaTime, AttractionAlpha);

			case EPinballMagnetAttractionState::LaunchingForward:
				return TickLaunchingForward(Params, DeltaTime, AttractionAlpha);
		}
	}

	private void PrepareFlyingBack()
	{
		AttractionState = EPinballMagnetAttractionState::FlyingBack;
		AccLocation.SnapTo(GetStartLocation(), GetStartTangent());
	}

	private FVector TickFlyingBack(FMagnetDroneAttractionModeTickAttractionParams Params, float DeltaTime, float& AttractionAlpha)
	{
		const float SpringAlpha = Math::Pow(AttractionAlpha, PinballComp.MovementSettings.AttractionSpringAlphaPow);

		const float SpringStiffness = Math::Lerp(PinballComp.MovementSettings.SpringStiffness.X, PinballComp.MovementSettings.SpringStiffness.Y, SpringAlpha);
		const float SpringDamping = Math::Lerp(PinballComp.MovementSettings.SpringDamping.X, PinballComp.MovementSettings.SpringDamping.Y, SpringAlpha);

		const FVector TargetLocation = GetBezierStartLocationFromDistanceAlpha(Params.CurrentLocation, AttractionAlpha);

		AccLocation.SpringTo(
			TargetLocation,
			SpringStiffness,
			SpringDamping,
			DeltaTime);

		const FVector DirToTarget = (AttractionTarget.GetTargetLocation() - Params.CurrentLocation).GetSafeNormal();
		const bool bIsMovingAway = AccLocation.Velocity.DotProduct(DirToTarget) < 0;
		if(!bIsMovingAway)
		{
			SetupLaunchingForward(Params.CurrentLocation, AttractionAlpha);
		}

		return AccLocation.Value;
	}

	private void SetupLaunchingForward(FVector Location, float AttractionAlpha)
	{
		AttractionState = EPinballMagnetAttractionState::LaunchingForward;
		StartSpringingBackDistance = Location.Distance(GetEndLocation());
		StartSpringingBackAlpha = AttractionAlpha;
	}

	private FVector TickLaunchingForward(FMagnetDroneAttractionModeTickAttractionParams Params, float DeltaTime, float& AttractionAlpha)
	{
		const float SpringAlpha = Math::Pow(AttractionAlpha, PinballComp.MovementSettings.AttractionSpringAlphaPow);

		const float SpringStiffness = Math::Lerp(PinballComp.MovementSettings.SpringStiffness.X, PinballComp.MovementSettings.SpringStiffness.Y, SpringAlpha);
		const float SpringDamping = Math::Lerp(PinballComp.MovementSettings.SpringDamping.X, PinballComp.MovementSettings.SpringDamping.Y, SpringAlpha);

		const FVector TargetLocation = GetEndLocation();

		AccLocation.SpringTo(
			TargetLocation,
			SpringStiffness,
			SpringDamping,
			DeltaTime);

		float DistanceAlpha = GetSpringBackDistanceAlpha();
		AttractionAlpha = Math::Max(AttractionAlpha, DistanceAlpha);

		float AdjustAlpha = Math::NormalizeToRange(AttractionAlpha, StartSpringingBackAlpha, 1.0);
		AdjustAlpha = Math::Pow(AdjustAlpha, AttractionAlphaPow);

		// Move in horizontally before vertically
		float HorizontalAlpha = Math::GetMappedRangeValueClamped(FVector2D(0, 0.9), FVector2D(0, 1), AdjustAlpha);
		float VerticalAlpha = Math::GetMappedRangeValueClamped(FVector2D(0.1, 1), FVector2D(0, 1), AdjustAlpha);

		FVector HorizontalLocation = Math::Lerp(
			AccLocation.Value.VectorPlaneProject(AttractionTarget.GetTargetImpactNormal()),
			TargetLocation.VectorPlaneProject(AttractionTarget.GetTargetImpactNormal()),
			HorizontalAlpha
		);

		FVector VerticalLocation = Math::Lerp(
			AccLocation.Value.ProjectOnToNormal(AttractionTarget.GetTargetImpactNormal()),
			TargetLocation.ProjectOnToNormal(AttractionTarget.GetTargetImpactNormal()),
			VerticalAlpha
		);
		
		return HorizontalLocation + VerticalLocation;
	}

	float GetDistanceAdjustedAlpha(float AttractionAlpha) const
	{
		return Math::Max(
			AttractionAlpha,
			Math::GetMappedRangeValueClamped(FVector2D(1000, 0), FVector2D(0, 1),
			AccLocation.Value.Distance(AttractionTarget.GetTargetLocation())));
	}

	float GetSpringBackDistanceAlpha() const
	{
		check(AttractionState == EPinballMagnetAttractionState::LaunchingForward);
		const FVector CurrentLocation = AccLocation.Value;
		const FVector TargetLocation = GetEndLocation();
		const float DistanceToTarget = CurrentLocation.Distance(TargetLocation);
		return 1.0 - Math::Saturate(DistanceToTarget / StartSpringingBackDistance);
	}

	FVector GetBezierStartLocationFromDistanceAlpha(FVector CurrentLocation, float DistanceAlpha) const
	{
		const FVector Target = GetEndLocation();
		const FVector AboveTarget = Target - (GetEndTangent() * 0.5);
		FVector LerpAboveTargetToTarget = Math::Lerp(AboveTarget, Target, DistanceAlpha);

		const FVector Start = CurrentLocation;
		FVector LerpStartToAboveTarget = Math::Lerp(Start, AboveTarget, DistanceAlpha);

		const FVector Location = Math::Lerp(LerpStartToAboveTarget, LerpAboveTargetToTarget, DistanceAlpha);

#if !RELEASE
		FTemporalLog TemporalLog = GetTemporalLog();
		TemporalLog.Value("Bezier;DistanceAlpha", DistanceAlpha);
		TemporalLog.Sphere("Bezier;AboveTarget", AboveTarget, MagnetDrone::Radius, FLinearColor::Blue);

		TemporalLog.Arrow("Bezier;LerpEndToTarget", AboveTarget, Target);
		TemporalLog.Sphere("Bezier;LerpAboveTargetToTarget Location", LerpAboveTargetToTarget, MagnetDrone::Radius);

		TemporalLog.Line("Bezier;LerpStartToAboveTarget", Start, AboveTarget, Color = FLinearColor::Yellow);
		TemporalLog.Sphere("Bezier;LerpStartToAboveTarget Location", LerpStartToAboveTarget, MagnetDrone::Radius, FLinearColor::Yellow);

		TemporalLog.Line("Bezier;Lerp", LerpStartToAboveTarget, LerpAboveTargetToTarget, 2.0, FLinearColor::Green);
		TemporalLog.Sphere("Bezier;Location", Location, MagnetDrone::Radius, FLinearColor::Green);
#endif

		return Location;
	}

	FVector GetStartLocation() const override
	{
		return InitialLocation;
	}

	FVector GetStartTangent() const override
	{
		return (InitialVelocity * 0.2) + FVector(-PinballComp.MovementSettings.StartExtraBackVelocity, 0, 0);
	}

	FVector GetEndTangent() const override
	{
		return FVector(PinballComp.MovementSettings.StartExtraBackVelocity, 0, 0);
	}

	FVector GetEndLocation() const override
	{
		return AttractionTarget.GetTargetLocation();
	}

	float CalculateTimeUntilArrival(float PathLength) const override
	{
		return PathLength / PinballComp.MovementSettings.AttractionSpeed;
	}

#if !RELEASE
	void LogToTemporalLog(FTemporalLog TemporalLog, FMagnetDroneAttractionModeLogParams Params) const override
	{
		Super::LogToTemporalLog(TemporalLog, Params);
		
		TemporalLog.Value("Attraction State", AttractionState);
		
		TemporalLog.Sphere("AccLocation", AccLocation.Value, 40);
		TemporalLog.Sphere("Target Location", AttractionTarget.GetTargetLocation(), 40);
		TemporalLog.Line("Perfect Path", GetStartLocation(), GetEndLocation());
		
		const FVector PerfectLocation = Math::ClosestPointOnLine(GetStartLocation(), GetEndLocation(), AccLocation.Value);
		TemporalLog.Sphere("Perfect Location", PerfectLocation, 40);
	}
#endif
}