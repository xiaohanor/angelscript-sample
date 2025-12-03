struct FAnimInstanceTripodMechAnimations
{
	UPROPERTY(BlueprintReadOnly, Category = "Combat")
	FHazePlaySequenceData CombatMh;

	UPROPERTY(BlueprintReadOnly, Category = "Fall|PhaseOne")
	FHazePlaySequenceData FallPhaseOneMh;

	UPROPERTY(BlueprintReadOnly, Category = "Fall|Clockwise")
	FHazePlaySequenceData FallClockwise;

	UPROPERTY(BlueprintReadOnly, Category = "Fall|Clockwise")
	FHazePlaySequenceData FallClockwiseMh;

	UPROPERTY(BlueprintReadOnly, Category = "Fall|CounterClockwise")
	FHazePlaySequenceData FallCounterClockwise;

	UPROPERTY(BlueprintReadOnly, Category = "Fall|CounterClockwise")
	FHazePlaySequenceData FallCounterClockwiseMh;

	UPROPERTY(BlueprintReadOnly, Category = "Fall|Center")
	FHazePlaySequenceData FallFromCenter;

	UPROPERTY(BlueprintReadOnly, Category = "Fall|Center")
	FHazePlaySequenceData FallFromCenterMh;

	UPROPERTY(BlueprintReadOnly, Category = "Feet")
	FHazePlaySequenceData FootLeftGround;

	UPROPERTY(BlueprintReadOnly, Category = "Feet")
	FHazePlaySequenceData FootLand;

	UPROPERTY(BlueprintReadOnly, Category = "Attack")
	FHazePlaySequenceData FireRockets;

	UPROPERTY(BlueprintReadOnly, Category = "Feet")
	FHazePlaySequenceData FootPlaced;

	UPROPERTY(BlueprintReadOnly, Category = "Feet")
	FHazePlaySequenceData FootPlacedFalling;

}

class UAnimInstanceTripodMech : UHazeAnimInstanceBase
{
	ASkylineBoss SkylineBoss;

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	FAnimInstanceTripodMechAnimations AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTransform CachedActorTransform;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTransform HeadTransform;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LegTransforms")
	FTransform FootTransformBack;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LegTransforms")
	FTransform FootTransformRight;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LegTransforms")
	FTransform FootTransformLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LegTransforms")
	FTransform LegBackPullVector;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LegTransforms")
	FTransform LegLeftPullVector;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LegTransforms")
	FTransform LegRightPullVector;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Attacks")
	bool bFiringLaser;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Attacks")
	FVector LaserHitLocation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator CoreRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Attacks")
	bool bFiringRockets;

	/** Fix the chain transforms during blends */
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCorrectiveChainAlign;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ESkylineBossState BossState;

	/**
	 * Alpha to set whether to override full body animations with code or not.
	 * 1 = Code-driven
	 * 0 = Animation-driven
	 */
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float CodeAnimAlpha;

	/**
	 * True when the hatches on the back are supposed to open.
	 * False when they are supposed to close again.
	 */
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHatchOpen;

	/**
	 * True when the core is exposed and vulnerable to attack.
	 */
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCoreExposed;

	/**
	 * True for one frame when a footstep is finished/when a foot impacts the ground.
	 */
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFootPlacedThisFrame;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Leg|Grounded")
	bool bLeftLegGrounded;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Leg|Grounded")
	bool bBackLegGrounded;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Leg|Grounded")
	bool bRightLegGrounded;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Leg|Damaged")
	bool bLeftLegDamaged;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Leg|Damaged")
	bool bBackLegDamaged;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Leg|Damaged")
	bool bRightLegDamaged;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK|Enabled")
	bool bFootIkEnabledLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK|Enabled")
	bool bFootIkEnabledRight;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK|Enabled")
	bool bFootIkEnabledBack;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCodeDrivesHeadRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float FallBlendTime = 0.7;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float RiseBlendTime = 1.0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ESkylineBossFallDirection FallDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ESkylineBossPhase Phase;

	bool bBossStateChangedThisFrame;

	bool bCachedShouldAnimationControlLegs;

	FTransform FootTransformLeftWS, FootTransformBackWS, FootTransformRightWS;
	float FallTime;


	// On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		SkylineBoss = Cast<ASkylineBoss>(HazeOwningActor);
		if (SkylineBoss == nullptr)
			return;
	}

	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (SkylineBoss == nullptr)
			return;

		BossState = SkylineBoss.GetState();
		Phase = SkylineBoss.GetPhase();
		FallDirection = SkylineBoss.AnimData.FallDirection;

		CachedActorTransform = SkylineBoss.ActorTransform;

		HeadTransform = SkylineBoss.GetHeadTransform();

		bCachedShouldAnimationControlLegs = ShouldAnimationControlLegs();
		if (!bCachedShouldAnimationControlLegs)
		{
			FootTransformLeftWS = SkylineBoss.GetFootAnimationTargetTransform(ESkylineBossLeg::Left);
			FootTransformBackWS = SkylineBoss.GetFootAnimationTargetTransform(ESkylineBossLeg::Center);
			FootTransformRightWS = SkylineBoss.GetFootAnimationTargetTransform(ESkylineBossLeg::Right);

			if (SkylineBoss.LegComponents.Num() > 0)
			{
				bLeftLegGrounded = SkylineBoss.LegComponents[ESkylineBossLeg::Left].bIsGrounded;
				bBackLegGrounded = SkylineBoss.LegComponents[ESkylineBossLeg::Center].bIsGrounded;
				bRightLegGrounded = SkylineBoss.LegComponents[ESkylineBossLeg::Right].bIsGrounded;

				bLeftLegDamaged = SkylineBoss.LegComponents[ESkylineBossLeg::Left].Leg.IsDestroyed();
				bBackLegDamaged = SkylineBoss.LegComponents[ESkylineBossLeg::Center].Leg.IsDestroyed();
				bRightLegDamaged = SkylineBoss.LegComponents[ESkylineBossLeg::Right].Leg.IsDestroyed();
			}
		}

		if (BossState == ESkylineBossState::Fall)
		{
			if (Phase == ESkylineBossPhase::First)
			{
				bCorrectiveChainAlign = false;

				bFootIkEnabledLeft = false;
				bFootIkEnabledRight = false;
				bFootIkEnabledBack = false;

				FallBlendTime = 0;
			}
			else
			{
				bCorrectiveChainAlign = true;

				FallTime += DeltaTime;
				bFootIkEnabledLeft = FallingGroundedIKAlpha(bLeftLegGrounded);
				bFootIkEnabledRight = FallingGroundedIKAlpha(bRightLegGrounded);
				bFootIkEnabledBack = FallingGroundedIKAlpha(bBackLegGrounded);

				FallBlendTime = 0.7;
			}
		}
		else if (BossState == ESkylineBossState::Rise || BossState == ESkylineBossState::Assemble)
		{
			bCorrectiveChainAlign = true;

			SetRiseGroundedIKAlpa(bFootIkEnabledLeft, n"FootIKLeft");
			SetRiseGroundedIKAlpa(bFootIkEnabledRight, n"FootIKRight");
			SetRiseGroundedIKAlpa(bFootIkEnabledBack, n"FootIKBack");

			if (BossState == ESkylineBossState::Assemble && bFootIkEnabledLeft)
				RiseBlendTime = 0.6;
			else
				RiseBlendTime = 1;

			if (SkylineBoss.LegComponents.Num() > 0)
			{
				if (SkylineBoss.LegComponents[ESkylineBossLeg::Left].FootTargetComponent != nullptr)
				{
					FootTransformLeftWS = GetRiseFootTargetTransform(ESkylineBossLeg::Left);
					FootTransformBackWS = GetRiseFootTargetTransform(ESkylineBossLeg::Center);
					FootTransformRightWS = GetRiseFootTargetTransform(ESkylineBossLeg::Right);
				}
			}
		}
		else if (bCachedShouldAnimationControlLegs)
		{
			bCorrectiveChainAlign = false;

			bFootIkEnabledBack = false;
			bFootIkEnabledLeft = false;
			bFootIkEnabledRight = false;
		}
		else
		{
			bFootIkEnabledBack = true;
			bFootIkEnabledLeft = true;
			bFootIkEnabledRight = true;
			FallTime = 0;

			bCorrectiveChainAlign = false;
		}

		bCodeDrivesHeadRotation = !bCachedShouldAnimationControlLegs;

		CodeAnimAlpha = (bCachedShouldAnimationControlLegs ? 0.0 : 1.0);

		bFiringRockets = SkylineBoss.AnimData.bFiringRockets;
		bFiringLaser = SkylineBoss.AnimData.bFiringLaser;
		LaserHitLocation = SkylineBoss.AnimData.LaserLocation;

		bHatchOpen = SkylineBoss.HatchComponent.IsHatchOpen();
		bCoreExposed = SkylineBoss.CoreComponent.IsCoreExposed();
		bFootPlacedThisFrame = SkylineBoss.FootStompComponent.WasFootPlacedThisFrame();

		if (BossState == ESkylineBossState::Fall || BossState == ESkylineBossState::Down)
		{
			CoreRotation.Yaw += Math::Wrap(DeltaTime * 360, 0.0, 360.0);
		}

		// Debug();
	}

	bool FallingGroundedIKAlpha(bool bFootGrounded)
	{
		if (!bFootGrounded)
			return false;

		if (FallTime > 0.8)
			return false;

		return true;
	}

	void SetRiseGroundedIKAlpa(bool& bCurrentValue, FName AnimBoolParamTag)
	{
		if (GetAnimTrigger(AnimBoolParamTag))
			bCurrentValue = true;
	}

	UFUNCTION(BlueprintOverride, Meta = (BlueprintThreadSafe))
	void BlueprintThreadSafeUpdateAnimation(float DeltaTime)
	{
		if (SkylineBoss == nullptr)
			return;

		FootTransformLeftWS.SetScale3D(FVector(1, 1, 1));
		FootTransformBackWS.SetScale3D(FVector(1, 1, 1));
		FootTransformRightWS.SetScale3D(FVector(1, 1, 1));

		FootTransformBack = FootTransformBackWS;
		FootTransformLeft = FootTransformLeftWS;
		FootTransformRight = FootTransformRightWS;

		// Apply some offsets for the foot transform
		const FVector LocationOffset = FVector(0, 0, SkylineBoss::IK_CHAIN_END_VERTICAL_OFFSET); // FVector(0, 0, 2700)
		FootTransformBack.AddToTranslation(FootTransformBack.TransformVectorNoScale(LocationOffset));
		FootTransformRight.AddToTranslation(FootTransformRight.TransformVectorNoScale(LocationOffset));
		FootTransformLeft.AddToTranslation(FootTransformLeft.TransformVectorNoScale(LocationOffset));

		const FQuat RotationOffset = SkylineBoss::IK_CHAIN_END_ROTATION_OFFSET.Quaternion();
		FootTransformBack.SetRotation(FootTransformBack.GetRotation() * RotationOffset);
		FootTransformRight.SetRotation(FootTransformRight.GetRotation() * RotationOffset);
		FootTransformLeft.SetRotation(FootTransformLeft.GetRotation() * RotationOffset);

		// Set the foot transforms to be in component space
		FootTransformBack.SetToRelativeTransform(CachedActorTransform);
		FootTransformRight.SetToRelativeTransform(CachedActorTransform);
		FootTransformLeft.SetToRelativeTransform(CachedActorTransform);

		// Calculate the PullVectors
		CalculatePullVector(LegLeftPullVector, FootTransformLeft, FVector(1, -1, 0).GetUnsafeNormal());
		CalculatePullVector(LegBackPullVector, FootTransformBack, FVector::BackwardVector);
		CalculatePullVector(LegRightPullVector, FootTransformRight, FVector(1, 1, 0).GetUnsafeNormal());
	}

	void CalculatePullVector(FTransform& OutPullVectorTransformCompSpace, FTransform& FootTransformCompSpace, FVector BendAxis)
	{
		const FVector FootLocation = FootTransformCompSpace.GetLocation();
		const float Multiplier = Math::Clamp(20000 - FootLocation.Size(), 0.0, 4000);

		OutPullVectorTransformCompSpace.SetLocation((FootLocation / 3) + (BendAxis * Multiplier));
	}

	/**
	 * Return false here to have animation
	 */
	bool ShouldAnimationControlLegs() const
	{
		switch (SkylineBoss.GetState())
		{
			case ESkylineBossState::None:
				return true;

			case ESkylineBossState::Assemble:
				return true;

			case ESkylineBossState::Combat:
				return false;

			case ESkylineBossState::PendingDown:
				return false;

			case ESkylineBossState::Fall:
				return true;

			case ESkylineBossState::Down:
				return true;

			case ESkylineBossState::Rise:
				return true;

			case ESkylineBossState::Dead:
				return true;
		}
	}

	void Debug()
	{
#if EDITOR
		const float Size = 50;
		const FLinearColor Color = FLinearColor::LucBlue;
		// Pull Vectors
		Debug::DrawDebugPoint(
			CachedActorTransform.TransformPosition(LegBackPullVector.GetLocation()),
			Size,
			Color);
		Debug::DrawDebugPoint(
			CachedActorTransform.TransformPosition(LegLeftPullVector.GetLocation()),
			Size,
			Color);
		Debug::DrawDebugPoint(
			CachedActorTransform.TransformPosition(LegRightPullVector.GetLocation()),
			Size,
			Color);

		// Capsule
		Debug::DrawDebugSphere(
			OwningComponent.WorldLocation, 1500, 6, Thickness = 50);
		Debug::DrawDebugArrow(
			OwningComponent.WorldLocation,
			OwningComponent.WorldLocation + (OwningComponent.ForwardVector * 5000),
			50000,
			FLinearColor::Red,
			50);
		Debug::DrawDebugArrow(
			OwningComponent.WorldLocation,
			OwningComponent.WorldLocation + (OwningComponent.UpVector * 5000),
			50000,
			FLinearColor::Blue,
			50);
		Debug::DrawDebugArrow(
			OwningComponent.WorldLocation,
			OwningComponent.WorldLocation + (OwningComponent.RightVector * 5000),
			50000,
			FLinearColor::Green,
			50);

#endif
	}

	FTransform GetRiseFootTargetTransform(ESkylineBossLeg Leg) const
	{
		FTransform TargetTransform = SkylineBoss.LegComponents[Leg].FootTargetComponent.WorldTransform;
		FVector PlacementForward = SkylineBoss.ActorForwardVector.GetSafeNormal2D(FVector::UpVector);

		switch(Leg)
		{
			case ESkylineBossLeg::Left:
				PlacementForward = FQuat(FVector::UpVector, Math::DegreesToRadians(-60)) * PlacementForward;
				break; 

			case ESkylineBossLeg::Right:
				PlacementForward = FQuat(FVector::UpVector, Math::DegreesToRadians(60)) * PlacementForward;
				break; 

			case ESkylineBossLeg::Center:
				PlacementForward = -PlacementForward;
				break; 
		}

		TargetTransform.SetRotation(FQuat::MakeFromZX(FVector::UpVector, PlacementForward));
		return TargetTransform;
	}

	UFUNCTION(BlueprintOverride)
	void LogAnimationTemporalData(FTemporalLog& TemporalLog) const
	{
		TemporalLog.Value("BossState", BossState);
		TemporalLog.Value("bCachedShouldAnimationControlLegs", bCachedShouldAnimationControlLegs);

		TemporalLog.Value("bBackLegGrounded", bBackLegGrounded);
		TemporalLog.Value("bLeftLegGrounded", bLeftLegGrounded);
		TemporalLog.Value("bRightLegGrounded", bRightLegGrounded);

		TemporalLog.Value("bFootIkEnabledBack", bFootIkEnabledBack);
		TemporalLog.Value("bFootIkEnabledLeft", bFootIkEnabledLeft);
		TemporalLog.Value("bFootIkEnabledRight", bFootIkEnabledRight);
		TemporalLog.Value("Phase", Phase);

		TemporalLog.Transform("FootTransformLeftWS", FootTransformLeftWS, 1000, 50);
		TemporalLog.Transform("FootTransformBackWS", FootTransformBackWS, 1000, 50);
		TemporalLog.Transform("FootTransformRightWS", FootTransformRightWS, 1000, 50);
	}
}