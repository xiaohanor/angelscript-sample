asset GravityBikeBladeGrappleToSurfaceFOVCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	1.0 |                 ·'''''··.                                      |
	    |               .'         '·.                                   |
	    |              ·              '·.                                |
	    |             .                  ·.                              |
	    |            .                     ·.                            |
	    |                                    ·.                          |
	    |           '                          ·.                        |
	    |          '                             ·                       |
	    |         ·                               '·                     |
	    |        .                                  '·                   |
	    |                                             '.                 |
	    |       '                                       '.               |
	    |      '                                          '·             |
	    |     '                                             '·.          |
	    |   .'                                                 '·.       |
	0.0 |..·                                                      '··....|
	    ------------------------------------------------------------------
	    0.0                                                            1.0
	*/
	AddAutoCurveKey(0.0, 0.0);
	AddCurveKeyTangent(0.3, 1.0, -0.007742);
	AddLinearCurveKey(1.0, 0.0);
};

asset GravityBikeBladeGrappleToSurfaceRotationCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	1.2 |                                                      ...····'''|
	    |                                            ...···''''          |
	    |                                   ...···'''                    |
	    |                             ..··''                             |
	    |                        ..·''                                   |
	    |                      ·'                                        |
	    |                    ·'                                          |
	    |                  ·'                                            |
	    |                .'                                              |
	    |              .'                                                |
	    |             ·                                                  |
	    |           .'                                                   |
	    |         .'                                                     |
	    |       .·                                                       |
	    |     .·                                                         |
	0.0 |...·'                                                           |
	    ------------------------------------------------------------------
	    0.0                                                            1.0
	*/
	AddCurveKeyTangent(0.0, 0.0, 0.341072);
	AddCurveKeyTangent(0.4, 0.85, 0.994774);
	AddCurveKeyTangent(1.0, 1.2, 0.56356);
};

struct FGravityBikeBladeGrappleToSurfaceDeactivateParams
{
	bool bLanded = false;
};

class UGravityBikeBladeGrappleToSurfaceCapability : UHazeCapability
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
	UCameraUserComponent CameraUserComp;

	FVector StartLocation;
	FVector StartVelocity;
	FQuat StartRotation;

	FVector TargetLocation;
	FVector TargetVelocity;
	FQuat TargetRotation;

	bool bAppliedCameraSettings = false;
	float32 InitialFrameDeltaTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
		MoveComp = GravityBike.MoveComp;
		MoveData = MoveComp.SetupMovementData(UGravityBikeSplineMovementData);
		
		BladePlayer = GravityBikeBlade::GetPlayer();
		BladeComp = UGravityBikeBladePlayerComponent::Get(BladePlayer);
		CameraUserComp = UCameraUserComponent::Get(BladePlayer);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(BladeComp.State != EGravityBikeBladeState::Grappling)
			return false;

		if(BladeComp.TargetComp.Type != EGravityBikeBladeTargetType::Surface)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeBladeGrappleToSurfaceDeactivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(BladeComp.State != EGravityBikeBladeState::Grappling)
			return true;

		if(BladeComp.TargetComp.Type != EGravityBikeBladeTargetType::Surface)
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
		if(CameraUserComp.IsUsingDefaultCamera())
		{
			UCameraSettings::GetSettings(BladePlayer).FOV.ApplyAsAdditive(GravityBikeBlade::GrappleFOVAdditive, this, 0, EHazeCameraPriority::VeryHigh);
			UCameraSettings::GetSettings(BladePlayer).FOV.SetManualFraction(GravityBikeBladeGrappleToSurfaceFOVCurve.GetFloatValue(0), this);
			UCameraSettings::GetSettings(BladePlayer).PivotLagMax.Apply(FVector::ZeroVector, this, 0, EHazeCameraPriority::VeryHigh);
			UCameraSettings::GetSettings(BladePlayer).PivotLagAccelerationDuration.Apply(FVector::ZeroVector, this, 0, EHazeCameraPriority::VeryHigh);
			bAppliedCameraSettings = true;
		}
		else
		{
			bAppliedCameraSettings = false;
		}

		BladeComp.StartGrapple(GravityBike);
		InitialFrameDeltaTime = GetCapabilityDeltaTime();

		PrepareMovement();

		GravityBike.IsAirborne.Apply(true, this);

#if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(GravityBike);
		TemporalLog.Event("Changed Gravity");
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeBladeGrappleToSurfaceDeactivateParams Params)
	{
		if(Owner.IsActorBeingDestroyed())
			return;
				
		BladeComp.FinishGrapple(GravityBike);

		GravityBike.IsAirborne.Clear(this);
		BladeComp.GravityChangeAlpha = 1;
		BladeComp.RotateDirection = 0;

		const FTransform SplineTransform = GravityBike.GetSplineTransform();
		GravityBike.AccBikeUp.SnapTo(GravityBike.ActorQuat);
		GravityBike.SnapTurnReferenceRotation(SplineTransform.Rotation);
		GravityBike.AccGlobalUp.SnapTo(SplineTransform.Rotation);

		GravityBike.SetActorVelocity(TargetRotation.ForwardVector * GravityBike.Settings.MaxSpeed);
		GravityBike.ApplyFullBoost();

		if(bAppliedCameraSettings)
		{
			UCameraSettings::GetSettings(BladePlayer).FOV.Clear(this, GravityBikeBlade::GrappleFOVBlendOutTime);
			UCameraSettings::GetSettings(BladePlayer).PivotLagMax.Clear(this, 0.5);
			UCameraSettings::GetSettings(BladePlayer).PivotLagAccelerationDuration.Clear(this, 0.5);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float Alpha = Math::Saturate((ActiveDuration + InitialFrameDeltaTime) / BladeComp.GravityChangeDuration);

		if(bAppliedCameraSettings)
		{
			UCameraSettings::GetSettings(BladePlayer).FOV.SetManualFraction(GravityBikeBladeGrappleToSurfaceFOVCurve.GetFloatValue(Alpha), this);
		}

		const FTransform SplineTransform = GravityBike.GetSplineTransform();

		const FQuat TargetSplineRotation = FQuat::MakeFromZX(GravityBike.GetGlobalWorldUp(), SplineTransform.Rotation.ForwardVector);
		const float RotationAlpha = GravityBikeBladeGrappleToSurfaceRotationCurve.GetFloatValue(Alpha);
		FQuat NewSplineRotation = FQuat::Slerp(StartRotation, TargetSplineRotation, RotationAlpha);

		GravityBike.AccBikeUp.SnapTo(NewSplineRotation);
		GravityBike.SnapTurnReferenceRotation(NewSplineRotation);
		GravityBike.AccGlobalUp.SnapTo(NewSplineRotation);

		TickMovement(Alpha, NewSplineRotation);
		
		BladeComp.GravityChangeAlpha = Alpha;
		
#if !RELEASE
			FTemporalLog TemporalLog = TEMPORAL_LOG(GravityBike).Page("GravityBikeBlade").Section("Grapple");
			TemporalLog.Value("Alpha", Alpha);
#endif
	}

	void PrepareMovement()
	{
		StartLocation = GravityBike.ActorLocation;
		StartRotation = GravityBike.ActorQuat;

		BladeComp.GravityChangeAlpha = 0;
		BladeComp.GravityChangeDuration = BladeComp.TargetComp.BladeGrappleDuration;
		BladeComp.NewGravityDirection = GravityBike.GetGravityDir();

		TargetLocation = BladeComp.TargetComp.WorldLocation;
		TargetRotation = BladeComp.TargetComp.ComponentQuat;
		TargetVelocity = TargetRotation.ForwardVector * GravityBike.Settings.MaxSpeed;

		const FVector StartOnTargetPlane = StartLocation.PointPlaneProject(TargetLocation, TargetRotation.UpVector);
		StartVelocity = (StartOnTargetPlane - StartLocation).GetSafeNormal() * 500;

		const FQuat HalfwayUpRotation = FQuat::Slerp(StartRotation, TargetRotation, 0.5);
		const FQuat DeltaRotation = HalfwayUpRotation * StartRotation.Inverse();

		// FB TODO: This needs a revisit
		float FullRoll = DeltaRotation.Rotator().Roll * 2;
		FullRoll = Math::Sign(FullRoll) * Math::Min(Math::Abs(FullRoll), 180);

		BladeComp.RotateDirection = FullRoll / 180;
	}

	void TickMovement(float Alpha, FQuat NewSplineRotation)
	{
		if(!MoveComp.PrepareMove(MoveData, NewSplineRotation.UpVector))
			return;

		if(GravityBike.HasControl())
		{
			const FVector CP1 = StartLocation;
			const FVector CP2 = StartLocation + StartVelocity * 0.3;
			const FVector CP3 = TargetLocation - TargetVelocity * 0.3;
			const FVector CP4 = TargetLocation;

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
}