asset GravityBikeBladeThrowVelocityCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	1.0 |''''''··..                                                      |
	    |          ''·.                                                  |
	    |              ''·.                                              |
	    |                  '·.                                           |
	    |                     '·.                                        |
	    |                        '·.                                     |
	    |                           '.                                   |
	    |                             '·.                                |
	    |                                '·.                             |
	    |                                   '.                           |
	    |                                     '·.                        |
	    |                                        '·.                     |
	    |                                           '·.                  |
	    |                                              '·..              |
	    |                                                  '·..          |
	0.0 |                                                      ''··......|
	    ------------------------------------------------------------------
	    0.0                                                            1.0
	*/
	AddAutoCurveKey(0.0, 1.0);
	AddLinearCurveKey(1.0, 0.0);
};

asset GravityBikeBladeThrowFOVCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	1.0 |                        .··'''''''''''··..                      |
	    |                    .·''                  '·.                   |
	    |                  ·'                         '·.                |
	    |               .·'                              ·.              |
	    |              ·                                   ·.            |
	    |            .'                                      ·           |
	    |          .'                                         '          |
	    |         .                                            '.        |
	    |        ·                                               ·       |
	    |       '                                                 ·      |
	    |     .'                                                   ·     |
	    |    .                                                      ·    |
	    |   .                                                        ·   |
	    |  .                                                          ·  |
	    | .                                                            . |
	0.0 |.                                                              .|
	    ------------------------------------------------------------------
	    0.0                                                            1.0
	*/
	AddCurveKeyTangent(0.0, 0.0, 4.383755);
	AddCurveKeyTangent(0.5, 1.0, 0.0);
	AddCurveKeyTangent(1.0, 0.0, -4.974693);
};

struct FGravityBikeBladeThrownActivateParams
{
	float TimeToImpact;
	FVector BladeStartLocation;
	FVector BladeTargetLocation;
};

struct FGravityBikeBladeThrownDeactivateParams
{
	bool bFinished = false;
};

class UGravityBikeBladeThrownCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);
	default CapabilityTags.Add(GravityBikeBlade::Tags::GravityBikeBlade);
	default CapabilityTags.Add(GravityBikeBlade::Tags::GravityBikeBladeThrow);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 10;

	AGravityBikeSpline GravityBike;
	UGravityBikeSplineMovementComponent MoveComp;
	UGravityBikeSplineMovementData MoveData;

	FVector BikeStartVelocity;
	FQuat BikeStartRotation;
	FQuat BikeTargetRotation;

	AHazePlayerCharacter BladePlayer;
	UGravityBikeBladePlayerComponent BladeComp;
	
	float TimeToImpact = 0;
	FVector BladeStartLocation;
	FVector BladeTargetLocation;
	FQuat BladeStartRotation;

	UCameraUserComponent CameraUserComp;
	bool bAppliedCameraSettings = false;
	UCameraSettings CameraSettings;
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
		CameraSettings = UCameraSettings::GetSettings(BladePlayer);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBikeBladeThrownActivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!BladeComp.bThrowAnimFinished)
			return false;

		const float ThrowDistance = BladePlayer.ActorCenterLocation.Distance(BladeComp.GetThrowTargetTransform().Location);
		Params.TimeToImpact = ThrowDistance / GravityBikeBlade::ThrowSpeed;
		Params.TimeToImpact = Math::Clamp(Params.TimeToImpact, GravityBikeBlade::MinThrowDuration, GravityBikeBlade::MaxThrowDuration);
		Params.BladeStartLocation = BladeComp.BladeActor.ActorLocation;
		Params.BladeTargetLocation = BladeComp.GetThrowTargetTransform().Location;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeBladeThrownDeactivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(BladeComp.State != EGravityBikeBladeState::Thrown)
			return true;

		if(ActiveDuration > TimeToImpact)
		{
			Params.bFinished = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeBladeThrownActivateParams Params)
	{
		BladeComp.OnStartThrow();
		InitialFrameDeltaTime = GetCapabilityDeltaTime();

		TimeToImpact = Params.TimeToImpact;
		BladeStartLocation = Params.BladeStartLocation;
		BladeStartRotation = BladeComp.BladeActor.ActorQuat;
		BladeTargetLocation = Params.BladeTargetLocation;

		BikeStartVelocity = MoveComp.Velocity;
		BikeStartRotation = GravityBike.ActorQuat;

		GravityBike.BlockCapabilities(GravityBikeSpline::AlignmentTags::GravityBikeSplineAlignment, this);
		GravityBike.BlockCapabilities(GravityBikeSpline::MovementTags::GravityBikeSplineMovement, this);

		GravityBike.IsAirborne.Apply(true, this);

		FGravityBikeBladeThrowEventData EventData;
		EventData.BladeActor = BladeComp.BladeActor;
		EventData.TargetLocation = BladeComp.GetThrowTargetTransform().Location;
		EventData.TargetNormal = BladeComp.GetThrowTargetTransform().Rotation.UpVector;
		EventData.ThrowDuration = TimeToImpact;
		UGravityBikeBladeEventHandler::Trigger_OnThrowStarted(BladePlayer, EventData);

		const FVector ToTarget = BladeComp.TargetComp.WorldLocation - GravityBike.ActorLocation;
		const FTransform SplineTransform = GravityBike.GetSplineTransform();
		BikeTargetRotation = FQuat::MakeFromXZ(ToTarget, SplineTransform.Rotation.UpVector);

		if(CameraUserComp.IsUsingDefaultCamera())
		{
			CameraSettings.FOV.ApplyAsAdditive(GravityBikeBlade::ThrowFOVAdditive, this, 0.1, EHazeCameraPriority::VeryHigh);
			CameraSettings.PivotLagMax.Apply(FVector::ZeroVector, this, 0.1, EHazeCameraPriority::VeryHigh);
			CameraSettings.PivotLagAccelerationDuration.Apply(FVector::ZeroVector, this, 0.1, EHazeCameraPriority::VeryHigh);
			bAppliedCameraSettings = true;
		}
		else
		{
			bAppliedCameraSettings = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeBladeThrownDeactivateParams Params)
	{
		GravityBike.UnblockCapabilities(GravityBikeSpline::AlignmentTags::GravityBikeSplineAlignment, this);
		GravityBike.UnblockCapabilities(GravityBikeSpline::MovementTags::GravityBikeSplineMovement, this);

		GravityBike.IsAirborne.Clear(this);

		if(bAppliedCameraSettings)
		{
			CameraSettings.FOV.Clear(this, 0);
			CameraSettings.PivotLagMax.Clear(this, 0);
			CameraSettings.PivotLagAccelerationDuration.Clear(this, 0);
		}

		if(Params.bFinished)
		{
			BladeComp.FinishThrow();

			FGravityBikeBladeThrowEventData EventData;
			EventData.BladeActor = BladeComp.BladeActor;
			EventData.TargetLocation = BladeComp.GetThrowTargetTransform().Location;
			EventData.TargetNormal = BladeComp.GetThrowTargetTransform().Rotation.UpVector;
			UGravityBikeBladeEventHandler::Trigger_OnThrowStopped(BladePlayer, EventData);
		}
		else
		{
			BladeComp.Reset();
		}

		TimeDilation::StopWorldTimeDilationEffect(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float Alpha = Math::Saturate((ActiveDuration + InitialFrameDeltaTime) / TimeToImpact);

		if(bAppliedCameraSettings)
		{
			CameraSettings.FOV.SetManualFraction(GravityBikeBladeThrowFOVCurve.GetFloatValue(Alpha), this);
			CameraSettings.PivotLagMax.SetManualFraction(Alpha, this);
			CameraSettings.PivotLagAccelerationDuration.SetManualFraction(Alpha, this);
		}

		UGravityBikeBladeTargetComponent TargetComp = BladeComp.TargetComp;

		FTimeDilationEffect TimeDilationEffect;
		TimeDilationEffect.BlendInDurationInRealTime = 0;
		TimeDilationEffect.BlendOutDurationInRealTime = 0;
		TimeDilationEffect.TimeDilation = TargetComp.GrappleTimeDilationCurve.GetFloatValue(Alpha);
		TimeDilation::StartWorldTimeDilationEffect(TimeDilationEffect, this);

		TickBikeMovement(Alpha);
		TickBladeMovement(DeltaTime, Alpha);

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(GravityBike).Page("GravityBikeBlade").Section("Throw");
		TemporalLog.Value("Alpha", Alpha);
		TemporalLog.Rotation("TargetRotation", BikeTargetRotation, GravityBike.ActorLocation);
#endif
	}

	void TickBikeMovement(float Alpha)
	{
		const FVector WorldUp = GravityBike.GetGlobalWorldUp();

		if(!MoveComp.PrepareMove(MoveData, WorldUp))
			return;

		if(GravityBike.HasControl())
		{
			const float MovementAlpha = GravityBikeBladeThrowVelocityCurve.GetFloatValue(Alpha);
			
			const FVector Velocity = BikeStartVelocity * MovementAlpha;
			MoveData.AddVelocity(Velocity);

			const FVector Gravity = MoveComp.Gravity * MovementAlpha;
			MoveData.AddAcceleration(Gravity);

			const float RotationAlpha = Math::EaseInOut(0, 1, Alpha, 2);
			const FQuat Rotation = FQuat::Slerp(BikeStartRotation, BikeTargetRotation, RotationAlpha);
			MoveData.SetRotation(Rotation);
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}
	
	void TickBladeMovement(float DeltaTime, float Alpha)
	{
		const float ThrowAlpha = Math::Pow(Alpha, GravityBikeBlade::AlphaExponent);

		const FVector BladeLocation = Math::Lerp(BladeStartLocation, BladeTargetLocation, ThrowAlpha);

		const float RotationAlpha = Math::GetMappedRangeValueClamped(FVector2D(0, 0.5), FVector2D(0, 1), ThrowAlpha);
		const FQuat BladeTargetRotation = FQuat::MakeFromZ(BladeTargetLocation - BladeStartLocation);
		const FQuat BladeRotation = FQuat::Slerp(BladeStartRotation, BladeTargetRotation, RotationAlpha);

		// const FRotator BladeRotation = Math::RInterpShortestPathTo(
		// 	BladeComp.BladeActor.ActorRotation,
		// 	BladeTargetRotation,
		// 	DeltaTime,
		// 	GravityBikeBlade::BladeRotationInterpSpeed
		// );

		BladeComp.BladeActor.SetActorLocationAndRotation(BladeLocation, BladeRotation);

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(GravityBike).Page("GravityBikeBlade").Section("Throw");
		TemporalLog.Transform("BladeTransform", FTransform(BladeRotation, BladeLocation), 500, 10);
#endif
	}
}