class UMagnetDroneAttractionModeWall : UMagnetDroneAttractionMode
{
	default TickOrder = 80;

#if !RELEASE
	default DebugColor = FLinearColor::Red;
#endif

	float TimeUntilArrival;
	FHazeAcceleratedVector AccLocation;

	// Spring Back
	bool bHasStartedSpringingBack = false;
	float StartSpringBackTime;
	float SpringBackDuration;

	const float SpringBackSpeed = 1500;
	const float AttractionWallDistanceThreshold = 100.0;
	const float AttractionSpringAlphaPow = 1.5;
	const FVector2D SpringStiffness = FVector2D(0, 30);
	const FVector2D SpringDamping = FVector2D(0, 0.05);
	const float AttractionAlphaPow = 2.5;

	void Setup(FMagnetDroneAttractionModeSetupParams Params) override
	{
		Super::Setup(Params);
	}

	bool ShouldActivate(FMagnetDroneAttractionModeShouldActivateParams Params) const override
	{
		if(!Super::ShouldActivate(Params))
			return false;

		const FPlane TargetPlane = FPlane(Params.AimData.GetTargetLocation(), Params.AimData.GetTargetImpactNormal());
		if(TargetPlane.PlaneDot(Params.PlayerLocation) > AttractionWallDistanceThreshold)
			return false;

		// FB TODO: Quick solution since it feels terrible to do a wall attraction when moving away from a surface
		if(Params.PlayerVelocity.DotProduct(Params.AimData.GetTargetImpactNormal()) > 10)
			return false;

		return true;
	}

	protected bool PrepareAttraction(FMagnetDroneAttractionModePrepareAttractionParams& Params, float&out OutPathLength, float&out OutTimeUntilArrival) override
	{
		if(!Super::PrepareAttraction(Params, OutPathLength, OutTimeUntilArrival))
			return false;

		TimeUntilArrival = OutTimeUntilArrival;
		AccLocation.SnapTo(InitialLocation, GetStartTangent());
		bHasStartedSpringingBack = false;
		
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
		if(!bHasStartedSpringingBack)
		{
			AttractionAlpha = 0;
			const float Alpha = Math::Saturate(Params.ActiveDuration / TimeUntilArrival);

			const float SpringAlpha = Math::Pow(Alpha, AttractionSpringAlphaPow);

			const float Stiffness = Math::Lerp(SpringStiffness.X, SpringStiffness.Y, SpringAlpha);
			const float Damping = Math::Lerp(SpringDamping.X, SpringDamping.Y, SpringAlpha);

			const FVector TargetLocation = GetBezierStartLocationFromDistanceAlpha(Params.CurrentLocation, Alpha);

			AccLocation.SpringTo(
				TargetLocation,
				Stiffness,
				Damping,
				DeltaTime);

			const FVector DirToTarget = (AttractionTarget.GetTargetLocation() - Params.CurrentLocation).GetSafeNormal();
			const bool bIsMovingAway = AccLocation.Velocity.DotProduct(DirToTarget) < 0;

			if(!bHasStartedSpringingBack && !bIsMovingAway)
			{
				bHasStartedSpringingBack = true;
				//BezierCurve::DebugDraw_2CP(Player.ActorLocation, Player.ActorLocation + Player.ActorVelocity, GetEndLocation() - GetEndTangent(), GetEndLocation(), FLinearColor::Blue, 3, 5);
				float StartSpringingBackDistance = BezierCurve::GetLength_2CP(Params.CurrentLocation, Params.CurrentLocation + Params.CurrentVelocity, GetEndLocation() - GetEndTangent(), GetEndLocation());
				StartSpringBackTime = Params.CurrentGameTime;
				SpringBackDuration = StartSpringingBackDistance / SpringBackSpeed;
			}

			return AccLocation.Value;
		}
		else
		{
			AttractionAlpha = Math::Saturate((Params.CurrentGameTime - StartSpringBackTime) / SpringBackDuration);

			const float SpringAlpha = Math::Pow(AttractionAlpha, AttractionSpringAlphaPow);

			const float Stiffness = Math::Lerp(SpringStiffness.X, SpringStiffness.Y, SpringAlpha);
			const float Damping = Math::Lerp(SpringDamping.X, SpringDamping.Y, SpringAlpha);

			const FVector TargetLocation = GetBezierStartLocationFromDistanceAlpha(Params.CurrentLocation, AttractionAlpha);

			AccLocation.SpringTo(
				TargetLocation,
				Stiffness,
				Damping,
				DeltaTime);

			float AdjustAlpha = Math::Pow(AttractionAlpha, AttractionAlphaPow);

			return Math::Lerp(AccLocation.Value, TargetLocation, AdjustAlpha);
		}
	}

	FVector GetBezierStartLocationFromDistanceAlpha(FVector CurrentLocation, float DistanceAlpha) const
	{
		const FVector AboveTarget = GetEndLocation() - (GetEndTangent() * 0.5);
		const FVector Target = GetEndLocation();
		FVector LerpAboveTargetToTarget = Math::Lerp(AboveTarget, Target, DistanceAlpha);

		FVector LerpStartToAboveTarget = Math::Lerp(CurrentLocation, AboveTarget, DistanceAlpha);

		const FVector Location = Math::Lerp(LerpStartToAboveTarget, LerpAboveTargetToTarget, DistanceAlpha);

#if !RELEASE
		FTemporalLog TemporalLog = GetTemporalLog();
		TemporalLog.Value("Bezier;DistanceAlpha", DistanceAlpha);
		TemporalLog.Sphere("Bezier;AboveTarget", AboveTarget, MagnetDrone::Radius, FLinearColor::Blue);

		TemporalLog.Arrow("Bezier;LerpEndToTarget", AboveTarget, Target);
		TemporalLog.Sphere("Bezier;LerpAboveTargetToTarget Location", LerpAboveTargetToTarget, MagnetDrone::Radius);

		TemporalLog.Line("Bezier;LerpStartToAboveTarget", CurrentLocation, AboveTarget, Color = FLinearColor::Yellow);
		TemporalLog.Sphere("Bezier;LerpStartToAboveTarget Location", LerpStartToAboveTarget, MagnetDrone::Radius, FLinearColor::Yellow);

		TemporalLog.Line("Bezier;Lerp", LerpStartToAboveTarget, LerpAboveTargetToTarget, 2.0, FLinearColor::Green);
		TemporalLog.Sphere("Bezier;Location", Location, MagnetDrone::Radius, FLinearColor::Green);
#endif

		return Location;
	}

	FVector GetStartTangent() const override
	{
		FVector DirFromWall = AttractionTarget.GetTargetImpactNormal();
		FVector JumpDir = InitialWorldUp;
		FVector ImpulseDirection = (DirFromWall + JumpDir).GetSafeNormal();
		const FVector Impulse = ImpulseDirection * 500;
		const FVector InheritedVelocity = InitialVelocity * 0.2;
		FVector StartTangent = InheritedVelocity + Impulse;
		if(StartTangent.DotProduct(ImpulseDirection) > Impulse.Size())
		{
			FVector KeptStartTangent = StartTangent.VectorPlaneProject(ImpulseDirection);
			StartTangent = KeptStartTangent + Impulse;
		}

		return StartTangent;
	}

	FVector GetEndTangent() const override
	{
		return AttractionTarget.GetTargetImpactNormal() * -500;
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

		// if(bHasStartedSpringingBack)
		// {
		// 	TemporalLog.Value("SpringBack;GetSpringBackDistanceAlpha()", GetSpringBackDistanceAlpha());
		// 	TemporalLog.Sphere("SpringBack;GetBezierStartLocationFromDistanceAlpha()", GetBezierStartLocationFromDistanceAlpha(DroneComp.GetAttractionAlpha()), MagnetDrone::Radius);
		// }
	}
#endif
};