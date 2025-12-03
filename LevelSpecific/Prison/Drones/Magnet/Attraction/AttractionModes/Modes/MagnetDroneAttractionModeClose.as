/**
 * Attraction customized for when we are quite close to the target.
 * Will first move out a bit, and then slam back.
 */
class UMagnetDroneAttractionModeClose : UMagnetDroneAttractionMode
{
	default TickOrder = 90;

#if !RELEASE
	default DebugColor = FLinearColor::Yellow;
#endif

	FHazeAcceleratedVector AccLocation;
	float TimeUntilArrival = 0;
	bool bHasStartedSpringingBack = false;
	float StartSpringingBackDistance;
	float StartSpringingBackAlpha;
	EPlayerTargetingMode TargetingMode = EPlayerTargetingMode::ThirdPerson;

	const float AttractionSpringAlphaPow = 1.5;
	const FVector2D SpringStiffness = FVector2D(10, 30);
	const FVector2D SpringDamping = FVector2D(0.1, 0.2);
	const float AttractionCloseDistanceThreshold = 500.0;
	const float AttractionAlphaPow = 2.5;

	bool ShouldActivate(FMagnetDroneAttractionModeShouldActivateParams Params) const override
	{
		if(!Super::ShouldActivate(Params))
			return false;

		if(Params.AimData.GetTargetLocation().Distance(Params.PlayerLocation) > AttractionCloseDistanceThreshold)
			return false;

		return true;
	}

	protected bool PrepareAttraction(FMagnetDroneAttractionModePrepareAttractionParams& Params, float&out OutPathLength, float&out OutTimeUntilArrival) override
	{
		if(!Super::PrepareAttraction(Params, OutPathLength, OutTimeUntilArrival))
			return false;

		AccLocation.SnapTo(InitialLocation, GetStartTangent());
		TimeUntilArrival = OutTimeUntilArrival;
		bHasStartedSpringingBack = false;
		TargetingMode = Params.TargetingMode;

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

		float SpringAlpha = AttractionAlpha;
		SpringAlpha = Math::Pow(SpringAlpha, AttractionSpringAlphaPow);

		if(bHasStartedSpringingBack)
			SpringAlpha = Math::Saturate(SpringAlpha * 2);

		const float Stiffness = Math::Lerp(10, SpringStiffness.Y, SpringAlpha);
		const float Damping = Math::Lerp(0.1, SpringDamping.Y, SpringAlpha);

		AccLocation.SpringTo(
			GetEndLocation(),
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
			StartSpringingBackDistance = AccLocation.Value.Distance(GetEndLocation());
			StartSpringingBackAlpha = AttractionAlpha;
		}

		const float DistanceAlpha = GetSpringBackDistanceAlpha();
		AttractionAlpha = Math::Max(AttractionAlpha, DistanceAlpha);

		const FVector TargetLocation = GetEndLocation();

		float AdjustAlpha = Math::NormalizeToRange(AttractionAlpha, StartSpringingBackAlpha, 1.0);
		AdjustAlpha = Math::Pow(AdjustAlpha, AttractionAlphaPow);

		return Math::Lerp(AccLocation.Value, TargetLocation, AdjustAlpha);
	}

	float GetDistanceAdjustedAlpha(float AttractionAlpha) const
	{
		return Math::Max(
			AttractionAlpha,
			Math::GetMappedRangeValueClamped(FVector2D(1000, 0), FVector2D(0, 1),
			AccLocation.Value.Distance(AttractionTarget.GetTargetLocation()))
		);
	}

	float GetSpringBackDistanceAlpha() const
	{
		check(bHasStartedSpringingBack);
		const FVector CurrentLocation = AccLocation.Value;
		const FVector TargetLocation = GetEndLocation();
		const float DistanceToTarget = CurrentLocation.Distance(TargetLocation);
		return 1.0 - Math::Saturate(DistanceToTarget / StartSpringingBackDistance);
	}

	FVector GetStartTangent() const override
	{
		FVector DirToCamera = -InitialViewRotation.ForwardVector;
		if(TargetingMode == EPlayerTargetingMode::SideScroller)
			DirToCamera = FVector::ZeroVector;
		
		const FVector DirToPlayer = (InitialLocation - AttractionTarget.GetTargetLocation()).GetSafeNormal();
		const FVector JumpDir = InitialWorldUp;
		FVector ImpulseDirection = (DirToCamera + DirToPlayer + JumpDir).GetSafeNormal();
		ImpulseDirection = ImpulseDirection.ProjectOnToNormal(AttractionTarget.GetTargetImpactNormal());
		return (InitialVelocity + (ImpulseDirection * MovementSettings.JumpImpulse)).GetClampedToMaxSize(MovementSettings.JumpImpulse);
	}

	FVector GetEndTangent() const override
	{
		return AttractionTarget.GetTargetImpactNormal() * -MovementSettings.JumpImpulse;
	}

	FVector GetEndLocation() const override
	{
		return AttractionTarget.GetTargetLocation();
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