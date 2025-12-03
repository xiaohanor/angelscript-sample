UCLASS(Abstract)
class UFeatureAnimInstanceFairyJump : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureFairyJump Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureFairyJumpAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector RootOffset;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int AnimationVariation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bQuickDash;

	float PreviousJumpTime;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float StartPos;

	const float QUICK_DASH_THRESHOLD = 0.35;
	float LastJumpTime;

	UTundraPlayerFairyComponent FairyComp;

	float TargetRootOffsetY;
	bool bInterpRootToZero = false;

	const float ROOT_MAX_MOVEMENT_Y = 42;
	const float ROOT_OFFSET_INTERP_SPEED = 4;
	const float GROUND_TRACE_LENGHT = 500;
	
	FHazeAcceleratedFloat RootOffsetInterpBackZero;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		FairyComp = UTundraPlayerFairyComponent::Get(HazeOwningActor.AttachParentActor);
	}


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureFairyJump NewFeature = GetFeatureAsClass(ULocomotionFeatureFairyJump);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		const float CurrentJumpTime = Time::GameTimeSeconds;
		const float TimeSinceLastJump = (CurrentJumpTime - PreviousJumpTime); 
		PreviousJumpTime = CurrentJumpTime;

		StartPos = 0;
		if (LastJumpTime < 0.5)
		{
			StartPos = LastJumpTime;
		}
		else
		{
			// bQuickDash = TimeSinceLastJump < QUICK_DASH_THRESHOLD;
			// AnimationVariation = Math::RandRange(0, 4);
		}

		bQuickDash = TimeSinceLastJump < QUICK_DASH_THRESHOLD;
		AnimationVariation = Math::RandRange(0, 4);


		// PrintToScreenScaled("AnimationVariation: " + AnimationVariation, 1.f, Scale = 3.f);

		UpdateRootOffsetTarget();
	}
	float LastLeapTime;

	void UpdateRootOffsetTarget()
	{
		if(Time::GetGameTimeSeconds() - FairyComp.TimeOfLastLeap <= FairyComp.CurrentFairySettings.SidewaysMovementDuration)
		{
			// Trace to see how close to the ground we are, scale sidemovement based on that
			const float GroundScale = GetGroundScale();

			float TargetDelta = FairyComp.CurrentFairySettings.SidewaysMovementShapeCurve.GetFloatValue((Time::GetGameTimeSeconds() - LastLeapTime) / FairyComp.CurrentFairySettings.SidewaysMovementDuration) * ROOT_MAX_MOVEMENT_Y;
			TargetDelta *= FairyComp.AmountOfLeaps % 2 == 0 ? 1 : -1;
			
			TargetRootOffsetY = TargetDelta * GroundScale;
		}
		else
			TargetRootOffsetY = 0;

		LastLeapTime = Time::GetGameTimeSeconds();
		bInterpRootToZero = false;
	}


	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		LastJumpTime = GetTopLevelGraphRelevantAnimTime();
		if (!bInterpRootToZero && (Math::IsNearlyEqual(RootOffset.Y, TargetRootOffsetY, ErrorTolerance = 1.5) || PollGroundScaleOptimized() < 0.37))
		{
			bInterpRootToZero = true;
			RootOffsetInterpBackZero.SnapTo(RootOffset.Y);
		}
		
		if (bInterpRootToZero)
		{
			if (!Math::IsNearlyZero(RootOffset.Y))
			{
				RootOffsetInterpBackZero.AccelerateTo(
					0, 
					Math::Clamp(1.5 * PollGroundScaleOptimized(), 0.6, 1.2),
					DeltaTime
				);
				RootOffset.Y = RootOffsetInterpBackZero.Value;
			}
		}
		else
			RootOffset.Y = Math::FInterpTo(RootOffset.Y, TargetRootOffsetY, DeltaTime, ROOT_OFFSET_INTERP_SPEED);
	}

	UFUNCTION(BlueprintOverride)
	void LogAnimationTemporalData(FTemporalLog& TemporalLog) const
	{
		TemporalLog.Value("TargetRootOffsetY", TargetRootOffsetY);
		TemporalLog.Value("RootOffset.Y", RootOffset.Y);
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag != n"AirMovement")
    		return true;

		return IsTopLevelGraphRelevantAnimFinished() && TopLevelGraphRelevantStateName == n"ToAirMovement";
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (LocomotionAnimationTag == n"Landing")
		{
			SetAnimVectorParam(n"LeapRootOffset", RootOffset);
		}

	}

	UFUNCTION(BlueprintOverride)
    float GetBlendTimeWhenResetting() const
    {
        return 0.03;
    }

	float CachedGroundScale = 1;
	float PollGroundScaleTick = 0;
	/**
	 * This function only does a new trace every x ticks, and returns a cached value inbetween.
	 */
	float PollGroundScaleOptimized()
	{
		PollGroundScaleTick++;
		if (PollGroundScaleTick > 10)
			return GetGroundScale();
		return CachedGroundScale;
	}

	float GetGroundScale()
	{
		CachedGroundScale = GetGroundDistance() / GROUND_TRACE_LENGHT;
		PollGroundScaleTick = 0;
		return CachedGroundScale;
	}

	float GetGroundDistance()
	{
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_WorldDynamic);

		TraceSettings.IgnoreActor(Game::Mio);
		TraceSettings.IgnoreActor(Game::Zoe);

		const FVector StartTracePos = HazeOwningActor.GetActorLocation();
		const FVector EndTracePos = StartTracePos - (HazeOwningActor.ActorUpVector * GROUND_TRACE_LENGHT);

		FHitResult HitResutls = TraceSettings.QueryTraceSingle(StartTracePos, EndTracePos);
		if (HitResutls.bBlockingHit)
			return (StartTracePos - HitResutls.Location).Size();

		return GROUND_TRACE_LENGHT;
	}
}
