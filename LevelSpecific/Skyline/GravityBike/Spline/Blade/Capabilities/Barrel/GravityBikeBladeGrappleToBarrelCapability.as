asset GravityBikeBladeGrappleToBarrelFOVCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	1.0 |                ·''''''··.                                      |
	    |              ·'          '·.                                   |
	    |             '               '·.                                |
	    |           .'                   ·.                              |
	    |          .                       ·.                            |
	    |         .                          ·.                          |
	    |        .                             ·.                        |
	    |       .                                ·                       |
	    |                                         '·                     |
	    |      '                                    '·                   |
	    |     '                                       '.                 |
	    |    ·                                          '.               |
	    |   ·                                             '·             |
	    |  .                                                '·.          |
	    | .                                                    '·.       |
	0.0 |.                                                        '··....|
	    ------------------------------------------------------------------
	    0.0                                                            1.0
	*/
	AddCurveKeyTangent(0.0, 0.0, 4.383755);
	AddCurveKeyTangent(0.3, 1.0, -0.007742);
	AddLinearCurveKey(1.0, 0.0);
};

asset GravityBikeBladeGrappleToBarrelRotationCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	1.08|                                                    ··''''''·.. |
	    |                                                 .·'           '|
	    |                                               .·               |
	    |                                             .·                 |
	    |                                           .·                   |
	    |                                         .'                     |
	    |                                       ·'                       |
	    |                                    .·'                         |
	    |                                  ·'                            |
	    |                               .·'                              |
	    |                            .·'                                 |
	    |                         .·'                                    |
	    |                     ..·'                                       |
	    |                 ..·'                                           |
	    |            ..··'                                               |
	0.0 |.......···''                                                    |
	    ------------------------------------------------------------------
	    0.0                                                            1.0
	*/
	AddCurveKeyTangent(0.0, 0.0, 0.0);
	AddCurveKeyTangent(0.8, 1.0, 2.122531);
	AddCurveKeyTangent(1.0, 1.0, -1.391523);
};

struct FGravityBikeBladeGrappleToBarrelDeactivateParams
{
	bool bLanded = false;
};

class UGravityBikeBladeGrappleToBarrelCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);
	default CapabilityTags.Add(GravityBikeBlade::Tags::GravityBikeBlade);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 20;

	AGravityBikeSpline GravityBike;
	UGravityBikeSplineMovementComponent MoveComp;
	UGravityBikeSplineMovementData MoveData;

	AHazePlayerCharacter BladePlayer;
	UGravityBikeBladePlayerComponent BladeComp;

	USceneComponent RelativeToComponent;

	FVector StartLocation;
	FVector StartVelocity;
	FQuat StartRotation;

	FVector TargetRelativeLocation;
	FVector TargetVelocity;
	float32 InitialFrameDeltaTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
		MoveComp = GravityBike.MoveComp;
		MoveData = MoveComp.SetupMovementData(UGravityBikeSplineMovementData);
		
		BladePlayer = GravityBikeBlade::GetPlayer();
		BladeComp = UGravityBikeBladePlayerComponent::Get(BladePlayer);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(BladeComp.State != EGravityBikeBladeState::Grappling)
			return false;

		if(BladeComp.TargetComp.Type != EGravityBikeBladeTargetType::Barrel)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeBladeGrappleToBarrelDeactivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(BladeComp.State != EGravityBikeBladeState::Grappling)
			return true;

		if(BladeComp.TargetComp.Type != EGravityBikeBladeTargetType::Barrel)
			return true;

		if(ActiveDuration > BladeComp.GravityChangeDuration)
			return true;

		if(MoveComp.HasGroundContact())
		{
			const FVector GroundNormal = MoveComp.GroundContact.ImpactNormal;
			const FVector TargetNormal = GravityBike.GetSplineUp();
			if(GroundNormal.GetAngleDegreesTo(TargetNormal) < GravityBikeBlade::LandingAngleThreshold)
			{
				Params.bLanded = true;
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BladeComp.StartGrapple(GravityBike);
		InitialFrameDeltaTime = GetCapabilityDeltaTime();

		PrepareMovement();
		GravityBike.IsAirborne.Apply(true, this);

		UCameraSettings::GetSettings(BladePlayer).FOV.ApplyAsAdditive(GravityBikeBlade::GrappleFOVAdditive, this, 0, EHazeCameraPriority::VeryHigh);
		UCameraSettings::GetSettings(BladePlayer).FOV.SetManualFraction(GravityBikeBladeGrappleToBarrelFOVCurve.GetFloatValue(0), this);
		UCameraSettings::GetSettings(BladePlayer).PivotLagMax.Apply(FVector::ZeroVector, this, 0, EHazeCameraPriority::VeryHigh);
		UCameraSettings::GetSettings(BladePlayer).PivotLagAccelerationDuration.Apply(FVector::ZeroVector, this, 0, EHazeCameraPriority::VeryHigh);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeBladeGrappleToBarrelDeactivateParams Params)
	{
		BladeComp.FinishGrapple(GravityBike);

		GravityBike.IsAirborne.Clear(this);

		BladeComp.GravityChangeAlpha = 1;
		BladeComp.RotateDirection = 0;

		const FQuat TargetSplineRotation = FQuat::MakeFromZX(GravityBike.GetGlobalWorldUp(), BladeComp.GetThrowTargetTransform().Rotation.ForwardVector);
		GravityBike.AccBikeUp.SnapTo(GravityBike.ActorQuat);
		GravityBike.SnapTurnReferenceRotation(TargetSplineRotation);
		GravityBike.AccGlobalUp.SnapTo(TargetSplineRotation);

		GravityBike.SetActorVelocity(GetTargetRotation().ForwardVector * GravityBike.Settings.MaxSpeed);
		GravityBike.ApplyFullBoost();

		UCameraSettings::GetSettings(BladePlayer).FOV.Clear(this, GravityBikeBlade::GrappleFOVBlendOutTime);
		UCameraSettings::GetSettings(BladePlayer).PivotLagMax.Clear(this, 0.5);
		UCameraSettings::GetSettings(BladePlayer).PivotLagAccelerationDuration.Clear(this, 0.5);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float Alpha = Math::Saturate((ActiveDuration + InitialFrameDeltaTime) / BladeComp.GravityChangeDuration);
		UCameraSettings::GetSettings(BladePlayer).FOV.SetManualFraction(GravityBikeBladeGrappleToBarrelFOVCurve.GetFloatValue(Alpha), this);

		const FQuat TargetRotation = BladeComp.GetThrowTargetTransform().Rotation;
		const float RotationAlpha = GravityBikeBladeGrappleToBarrelRotationCurve.GetFloatValue(Alpha);
		FQuat NewSplineRotation = FQuat::Slerp(GetStartRotation(), TargetRotation, RotationAlpha);

		GravityBike.AccBikeUp.SnapTo(NewSplineRotation);
		GravityBike.SnapTurnReferenceRotation(NewSplineRotation);
		GravityBike.AccGlobalUp.SnapTo(NewSplineRotation);

		TickMovement(DeltaTime, Alpha, NewSplineRotation);
		
		BladeComp.GravityChangeAlpha = Alpha;
		
#if !RELEASE
			TEMPORAL_LOG(GravityBike).Page("GravityBikeBlade").Section("Grapple")
				.Value("Alpha", Alpha)
				.Rotation("TargetRotation", TargetRotation, GravityBike.ActorLocation, 500)
				.Rotation("NewSplineRotation", NewSplineRotation, GravityBike.ActorLocation, 500)
			;
#endif
	}

	void PrepareMovement()
	{
		const FTransform TargetTransform = BladeComp.GetThrowTargetTransform();

		StartLocation = GravityBike.ActorLocation;
		StartVelocity = GravityBike.ActorVelocity;
		StartRotation = GravityBike.ActorQuat;

		BladeComp.GravityChangeAlpha = 0;

		BladeComp.GravityChangeDuration = BladeComp.TargetComp.BladeGrappleDuration;

		BladeComp.NewGravityDirection = GravityBike.GetGravityDir();

		TargetRelativeLocation = BladeComp.TargetComp.WorldLocation - TargetTransform.Location;
		TargetVelocity = GetTargetRotation().ForwardVector * GravityBike.Settings.MaxSpeed;

		const FQuat HalfwayUpRotation = FQuat::Slerp(StartRotation, GetTargetRotation(), 0.5);
		const FQuat DeltaRotation = HalfwayUpRotation * StartRotation.Inverse();

		// FB TODO: This needs a revisit
		float FullRoll = DeltaRotation.Rotator().Roll * 2;
		FullRoll = Math::Sign(FullRoll) * Math::Min(Math::Abs(FullRoll), 180);

		BladeComp.RotateDirection = FullRoll / 180;
	}

	void TickMovement(float DeltaTime, float Alpha, FQuat NewSplineRotation)
	{
		// if(MoveComp.HasMovedThisFrame())
		// 	return;

		if(!MoveComp.PrepareMove(MoveData, NewSplineRotation.UpVector))
			return;

		if(GravityBike.HasControl())
		{
			const FVector CP1 = GetStartLocation();
			const FVector CP2 = GetStartLocation() + GetStartVelocity() * 0.3;
			const FVector CP3 = GetTargetLocation() - GetTargetVelocity() * 0.3;
			const FVector CP4 = GetTargetLocation();

			FVector NewLocation = BezierCurve::GetLocation_2CP_ConstantSpeed(CP1, CP2, CP3, CP4, Alpha);
			NewLocation += GravityBike.ActorTransform.InverseTransformPositionNoScale(MoveComp.ShapeComponent.WorldLocation);

			MoveData.AddDeltaFromMoveTo(NewLocation);

			FQuat SteerRelativeRotation = GravityBike.SteeringComp.GetTargetSteerRelativeRotation();
			SteerRelativeRotation = FQuat::Slerp(FQuat::Identity, SteerRelativeRotation, Math::Square(Alpha));

			FQuat NewBikeRotation = SteerRelativeRotation * NewSplineRotation;

			MoveData.SetRotation(NewBikeRotation);

			MoveData.AlwaysApplyLandingImpact();

#if !RELEASE
			FTemporalLog TemporalLog = TEMPORAL_LOG(GravityBike).Page("GravityBikeBlade").Section("Grapple");
			TemporalLog.Point("NewLocation", NewLocation);
			TemporalLog.Rotation("NewBikeRotation", NewBikeRotation, NewLocation);
			TemporalLog.BezierCurve_2CP("Bezier", CP1, CP2, CP3, CP4);
#endif
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}

	FVector GetStartLocation() const
	{
		return StartLocation;
	}

	FVector GetStartVelocity() const
	{
		return StartVelocity;
	}

	FQuat GetStartRotation() const
	{
		return StartRotation;
	}

	FVector GetTargetLocation() const
	{
		return BladeComp.GetThrowTargetTransform().Location + TargetRelativeLocation;
	}

	FVector GetTargetVelocity() const
	{
		return TargetVelocity;
	}

	FQuat GetTargetRotation() const
	{
		return BladeComp.GetThrowTargetTransform().Rotation;
	}
}