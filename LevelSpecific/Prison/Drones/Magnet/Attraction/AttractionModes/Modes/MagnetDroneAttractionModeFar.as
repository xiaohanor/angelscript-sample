/**
 * Attraction customized for when we are quite far away from the target.
 * Will simply accelerate towards the target in a bezier curve path.
 */
class UMagnetDroneAttractionModeFar : UMagnetDroneAttractionMode
{
	default TickOrder = 100;

	float AttractionStartVerticalImpulse;
	float JumpImpulse;

	FHazeAcceleratedVector AccLocation;
	float TimeUntilArrival;

	bool bHasStartedSpringingBack = false;
	float StartSpringingBackDistance;
	float StartSpringingBackAlpha;

	const float AttractionSpringAlphaPow = 1.5;
	const FVector2D SpringStiffness = FVector2D(0, 30);
	const FVector2D SpringDamping = FVector2D(0, 0.05);
	const float AttractionAlphaPow = 2.5;

	bool ShouldActivate(FMagnetDroneAttractionModeShouldActivateParams Params) const override
	{
		if(!Super::ShouldActivate(Params))
			return false;

		return true;
	}

	protected bool PrepareAttraction(FMagnetDroneAttractionModePrepareAttractionParams& Params, float&out OutPathLength, float&out OutTimeUntilArrival) override
	{
		AttractionStartVerticalImpulse = Params.AttractionSettings.AttractionStartVerticalImpulse;
		JumpImpulse = MovementSettings.JumpImpulse;

		bHasStartedSpringingBack = false;
		StartSpringingBackDistance = 0;
		StartSpringingBackAlpha = 0;

		if(!Super::PrepareAttraction(Params, OutPathLength, OutTimeUntilArrival))
			return false;

		AccLocation.SnapTo(InitialLocation, GetStartTangent());
		TimeUntilArrival = OutTimeUntilArrival;
		
		return true;
	}

	void ApplyTargetDeltaTransform(FTransform PreviousTargetTransform, FTransform CurrentTargetTransform) override
	{
		Super::ApplyTargetDeltaTransform(PreviousTargetTransform, CurrentTargetTransform);

		AccLocation.Value = CurrentTargetTransform.TransformPosition(PreviousTargetTransform.InverseTransformPosition(AccLocation.Value));
		AccLocation.Velocity = CurrentTargetTransform.TransformVectorNoScale(PreviousTargetTransform.InverseTransformVectorNoScale(AccLocation.Velocity));
	}

	protected FVector TickAttraction(FMagnetDroneAttractionModeTickAttractionParams Params, float DeltaTime, float& AttractionAlpha) override
	{
		const float TimeAlpha = Math::Saturate(Params.ActiveDuration / TimeUntilArrival);
		AttractionAlpha = Math::Max(AttractionAlpha, TimeAlpha);

		const float SpringAlpha = Math::Pow(AttractionAlpha, AttractionSpringAlphaPow);

		const float Stiffness = Math::Lerp(SpringStiffness.X, SpringStiffness.Y, SpringAlpha);
		const float Damping = Math::Lerp(SpringDamping.X, SpringDamping.Y, SpringAlpha);

		const FVector TargetLocation = GetBezierStartLocationFromDistanceAlpha(Params.CurrentLocation, AttractionAlpha);

		AccLocation.SpringTo(
			TargetLocation,
			Stiffness,
			Damping,
			DeltaTime);

		const FVector DirToTarget = (AttractionTarget.GetTargetLocation() - Params.CurrentLocation).GetSafeNormal();
		const bool bIsMovingAway = AccLocation.Velocity.DotProduct(DirToTarget) < 0;
		if(!bHasStartedSpringingBack && bIsMovingAway)
			return AccLocation.Value;

		if(!bHasStartedSpringingBack && !bIsMovingAway)
		{
			bHasStartedSpringingBack = true;
			StartSpringingBackDistance = Params.CurrentLocation.Distance(GetEndLocation());
			StartSpringingBackAlpha = AttractionAlpha;
		}

		const float DistanceAlpha = GetSpringBackDistanceAlpha();
		AttractionAlpha = Math::Max(AttractionAlpha, DistanceAlpha);

		float AdjustAlpha = Math::NormalizeToRange(AttractionAlpha, StartSpringingBackAlpha, 1.0);
		AdjustAlpha = Math::Pow(AdjustAlpha, AttractionAlphaPow);
		
		return Math::Lerp(AccLocation.Value, TargetLocation, AdjustAlpha);
	}

	FVector GetStartTangent() const override
	{
		return InitialVelocity + FVector(0, 0, AttractionStartVerticalImpulse);
	}

	FVector GetEndTangent() const override
	{
		return AttractionTarget.GetTargetImpactNormal() * -JumpImpulse;
	}

	float GetDistanceAdjustedAlpha(float AttractionAlpha) const
	{
		return Math::Max(AttractionAlpha, Math::GetMappedRangeValueClamped(FVector2D(1000, 0), FVector2D(0, 1), AccLocation.Value.Distance(AttractionTarget.GetTargetLocation())));
	}

	float GetSpringBackDistanceAlpha() const
	{
		check(bHasStartedSpringingBack);
		const FVector CurrentLocation = AccLocation.Value;
		const FVector TargetLocation = GetEndLocation();
		const float DistanceToTarget = CurrentLocation.Distance(TargetLocation);
		return 1.0 - Math::Saturate(DistanceToTarget / StartSpringingBackDistance);
	}
	
	FVector GetBezierStartLocationFromDistanceAlpha(FVector CurrentLocation, float DistanceAlpha) const
	{
		const FVector AboveTarget = GetEndLocation() - (GetEndTangent() * 0.5);
		const FVector Target = GetEndLocation();
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

#if !RELEASE
	void LogToTemporalLog(FTemporalLog TemporalLog, FMagnetDroneAttractionModeLogParams Params) const override
	{
		Super::LogToTemporalLog(TemporalLog, Params);

		TemporalLog.Sphere("AccLocation", AccLocation.Value, MagnetDrone::Radius);
		TemporalLog.DirectionalArrow("AccLocation Velocity", AccLocation.Value, AccLocation.Velocity);
		TemporalLog.Sphere("Target Location", AttractionTarget.GetTargetLocation(), MagnetDrone::Radius);

		TemporalLog.Value("SpringBack;bHasStartedSpringingBack", bHasStartedSpringingBack);
		TemporalLog.Value("SpringBack;StartSpringingBackDistance", StartSpringingBackDistance);
	}
#endif
}