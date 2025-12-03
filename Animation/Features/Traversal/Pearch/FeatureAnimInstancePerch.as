
UCLASS(Abstract)
class UFeatureAnimInstancePerch : UHazeFeatureSubAnimInstance
{
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeaturePerch Feature;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeaturePerchAnimData AnimData;

	UPlayerMovementComponent MovementComponent;
	UPlayerFloorSlowdownComponent SlowDownComponent;
	UPlayerPerchComponent PerchComponent;
	UTeleportResponseComponent TPResponseComponent;
	UAnimFootTraceComponent FootTraceComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	FHazeSlopeWarpingData IKData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	float SlopeAngle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	FHazeAnimIKFeetPlacementTraceDataInput IKFeetPlacementData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	bool bEnableIKFeetPlacement;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	bool bEnableSlopeWarp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	float IKGoalAlpha = 1;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	float IKAlpha = 1;

	float IKAlphaInterpSpeed = -1;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float EnterTime;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float EnterTimeNormalized;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float InitialDistanceToPoint;

	float HeightDistanceToPoint;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector AngleDiff;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float RotationRate;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float HorizontalSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector Velocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float VerticalVelocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float StoppingVelocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float HorizontalLandingVelocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float VerticalLandingVelocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D LandingBlendSpaceValue;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ReadyMhAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float TurnMhAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bInEnter;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bInGroundedEnter;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPerching;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLanding;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float RelaxTimer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsRelaxing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJumping;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDashing;

	bool bDashingThisFrame;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bResetDashing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bOnSpline;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSwitchFoot;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsFarAway;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsHighUp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCameFromGrapple;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCameFromDash;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCameFromFalling;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasSettled;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasVelocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasInput;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSkipSplineStart;

	bool bIsStopping;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStoppedPerching;

	bool bTurnLeft180;

	bool bTurnRight180;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStartedTurningRight180;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStartedTurningLeft180;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "AdditiveLean")
	float AdditiveLean;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "AdditiveLean")
	float AdditiveLeanAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "CameraLookAt")
	float LookAtAlpha = 0.7;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "AdditiveLean")
	bool bReachedEndOfSpline;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D UnbalancedBlendspaceValue;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bUnstable;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTeleportedRecently;

	FVector PointPosition;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeaturePerch NewFeature = GetFeatureAsClass(ULocomotionFeaturePerch);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff here

		// Components

		MovementComponent = UPlayerMovementComponent::Get(Player);
		SlowDownComponent = UPlayerFloorSlowdownComponent::Get(Player);
		PerchComponent = UPlayerPerchComponent::Get(Player);
		TPResponseComponent = UTeleportResponseComponent::Get(Player);

		// Valid-check that there is a Selected SpringOff Point
		if (PerchComponent.Data.TargetedPerchPoint != nullptr)
		{
			PointPosition = PerchComponent.Data.TargetedPerchPoint.WorldLocation;
			InitialDistanceToPoint = (PointPosition - Player.ActorLocation).Size();
		}

		bCameFromGrapple = PrevLocomotionAnimationTag == n"Grapple" || PrevLocomotionAnimationTag == n"QuickGrapple";

		bCameFromFalling = PrevLocomotionAnimationTag == n"AirMovement";

		bSwitchFoot = false;

		bIsFarAway = false;

		bStoppedPerching = false;

		AdditiveLeanAlpha = 0;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		if (bIsLanding)
			return 0.2;
		else
			return 0.1;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		const FVector InheritMovementVelocity = Player.ActorRotation.UnrotateVector(MovementComponent.GetFollowVelocity());
		bUnstable = (InheritMovementVelocity.SizeSquared() > 95 * 95);
		if (bUnstable)
			UnbalancedBlendspaceValue = FVector2D(InheritMovementVelocity.Y, InheritMovementVelocity.X) / -400;

		// Current state
		// bInGroundedEnter = PerchComponent.Data.bInGroundedEnter;
		bPerching = PerchComponent.Data.bPerching && !PerchComponent.Data.bSplineJump;
		bJumping = PerchComponent.Data.bJumpingOff || PerchComponent.Data.bSplineJump;
		// bIsLanding = PerchComponent.AnimData.bLanding;

		// Exit Perch
		bStoppedPerching = !(LocomotionAnimationTag == n"Perch");

		bDashing = PerchComponent.AnimData.bDashing;

		if (CheckValueChangedAndSetBool(bDashingThisFrame, PerchComponent.AnimData.bDashing, EHazeCheckBooleanChangedDirection::FalseToTrue))
		{
			bResetDashing = true;
		}
		else
		{
			bResetDashing = false;
		}

		// Landing Velocity for Landing BlendSpace
		HorizontalLandingVelocity = PerchComponent.Data.PerchLandingHorizontalVelocity.Size2D();
		VerticalLandingVelocity = -PerchComponent.Data.PerchLandingVerticalVelocity.Z;

		float InterpSpeed = Math::Abs(RotationRate) > MovementComponent.GetMovementYawVelocity(false) / 250.0 ? 3.0 : 2.0;

		RotationRate = Math::FInterpTo(RotationRate, (MovementComponent.GetMovementYawVelocity(false) / 250.0), DeltaTime, InterpSpeed);
		Speed = MovementComponent.Velocity.Size();
		if (bIsLanding)
		{
			Velocity = MovementComponent.PreviousVelocity;
		}
		HorizontalSpeed = MovementComponent.HorizontalVelocity.Size();

		// Check for Spline and set Spline bool
		bOnSpline = PerchComponent.Data.bInPerchSpline;

		// PrintToScreenScaled("bOnSpline: " + bOnSpline, 0.0, Scale = 3.0);

		// Check for Velocity / Perch State and set Input bool
		bHasInput = ((PerchComponent.Data.State == EPlayerPerchState::PerchingOnSpline && PerchComponent.Data.bHasValidInput) || !MovementComponent.SyncedMovementInputForAnimationOnly.IsNearlyZero());

		// Check for General Velocity and set Volocity bool
		bHasVelocity = MovementComponent.GetHorizontalVelocity().Size() > 0.0;

		bReachedEndOfSpline = PerchComponent.AnimData.bReachedEndOfSpline;
		if (bReachedEndOfSpline && bSkipSplineStart)
			bSkipSplineStart = false;

		// TurnAround logic
		if (CheckValueChangedAndSetBool(bTurnRight180, PerchComponent.AnimData.bPerformingTurnaroundRight, EHazeCheckBooleanChangedDirection::FalseToTrue))
		{
			bStartedTurningRight180 = true;
		}
		else
		{
			bStartedTurningRight180 = false;
		}

		if (CheckValueChangedAndSetBool(bTurnLeft180, PerchComponent.AnimData.bPerformingTurnaroundLeft, EHazeCheckBooleanChangedDirection::FalseToTrue))
		{
			bStartedTurningLeft180 = true;
		}
		else
		{
			bStartedTurningLeft180 = false;
		}

		// Calculate EnterTime
		if (CheckValueChangedAndSetBool(bInEnter, PerchComponent.AnimData.bInEnter, EHazeCheckBooleanChangedDirection::FalseToTrue))
		{
			InitialJumpCalculation();
			EnterTimeNormalized = 0;
		}

		// Calculate EnterTime
		if (CheckValueChangedAndSetBool(bInGroundedEnter, PerchComponent.AnimData.bInGroundedEnter, EHazeCheckBooleanChangedDirection::FalseToTrue))
		{
			InitialJumpCalculation();
			EnterTimeNormalized = 0;
		}
		else if (bInEnter || (bInGroundedEnter && InitialDistanceToPoint != 0))
		{
			PointPosition = PerchComponent.Data.TargetedPerchPoint.WorldLocation;
			EnterTimeNormalized = 1 - (Player.ActorLocation - PointPosition).Size2D() / InitialDistanceToPoint;
			EnterTime = EnterTimeNormalized * AnimData.EnterForwardLFoot.Sequence.PlayLength;
		}

		// Determine when to do javelin jump
		if ((((TopLevelGraphRelevantStateName == "PerchPoint" || TopLevelGraphRelevantStateName == n"PerchSpline") && Speed < 150) && TopLevelGraphRelevantAnimTimeRemainingFraction < 0.7))
		{
			bHasSettled = true;
		}

		// Set stopping speed when input is false
		if (CheckValueChangedAndSetBool(bIsStopping, bHasInput, EHazeCheckBooleanChangedDirection::TrueToFalse))
		{
			StoppingVelocity = Speed;
		}

		FVector Direction = PointPosition - HazeOwningActor.ActorLocation;
		AngleDiff = Player.ActorRotation.UnrotateVector(Direction);

		float LandingMultiplier = Math::Clamp((InitialDistanceToPoint / 600) + 1, 0.5, 2.0);
		LandingBlendSpaceValue.X = HorizontalLandingVelocity * LandingMultiplier;
		LandingBlendSpaceValue.Y = VerticalLandingVelocity;

		FVector LocalForwardStickInput = Player.ActorRotation.UnrotateVector(MovementComponent.SyncedMovementInputForAnimationOnly);

		if ((TopLevelGraphRelevantStateName == n"PerchPoint" && GetAnimBoolParam(n"PerchReady")) || bStartedTurningRight180)
		{
			ReadyMhAlpha = Math::FInterpTo(ReadyMhAlpha, LocalForwardStickInput.Size2D(), DeltaTime, 3.0);
			TurnMhAlpha = Math::FInterpTo(TurnMhAlpha, Math::Abs(RotationRate), DeltaTime, 10.0);
		}
		else
		{
			ReadyMhAlpha = 0;
			TurnMhAlpha = 0;
		}

		if (bHasInput || bUnstable || PerchComponent.IsPerchIdleBlocked())
			RelaxTimer = Math::FInterpConstantTo(RelaxTimer, 0, DeltaTime, 10);
		else if (!PerchComponent.IsPerchIdleBlocked())
			RelaxTimer = Math::Clamp(RelaxTimer + DeltaTime, 0.0, 30.0);

		bIsRelaxing = (RelaxTimer > 10) && !bUnstable && !PerchComponent.IsPerchIdleBlocked();

		bTeleportedRecently = TPResponseComponent.HasTeleportedSinceLastFrame();

		AdditiveLean = PerchComponent.AnimData.AdditiveLean;
		AdditiveLeanAlpha = PerchComponent.AnimData.LeanAlpha;

		//Slope Warping

		// IK Data
			IKData.bBlockingHit = MovementComponent.HasGroundContact();
			IKData.ImpactNormal = MovementComponent.GroundContact.ImpactNormal;
			IKData.ImpactPoint = MovementComponent.GroundContact.ImpactPoint;
			IKData.ActorVelocity = MovementComponent.Velocity;
			IKData.OverrideMaxStepHeight = -1;
			SlopeAngle = PerchComponent.AnimData.VerticalSlopeAngle;
			


		
#if EDITOR
/*
Print("LandingBlendSpaceValue: " + LandingBlendSpaceValue, 0.f);
Print("bStartedTurningRight180: " + bStartedTurningRight180, 0.f);
Print("bTurnRight180: " + bTurnRight180, 0.f);
PrintToScreen("LocalForwardStickInput.Y: " + TurnMhAlpha, 0.f);
PrintToScreen("GetAnimBoolParam(nPerchReady): " + GetAnimBoolParam(n"PerchReady"), 0.f);
PrintToScreen("RotationRate: " + RotationRate, 0.f);
PrintToScreen("Jumping: " + bJumping, 0.f);
PrintToScreen("InEnter: " + bInEnter, 0.f);
PrintToScreen("bIsLanding: " + bIsLanding, 0.f);

Print("Speed: " + Speed, 0.f);
Print("ReadyMhBlendSpaceValue: " + ReadyMhAlpha, 0.f);
*/
#endif
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (TopLevelGraphRelevantStateName == n"PerchExit" && (LocomotionAnimationTag == n"AirMovement" || LocomotionAnimationTag == n"Jump"))
			return true;

		if (TopLevelGraphRelevantStateName == n"PerchExit")
			return (TopLevelGraphRelevantAnimTimeRemainingFraction < 0.1);

		if (LocomotionAnimationTag != n"Movement" && LocomotionAnimationTag != n"AirMovement")
		{
			return true;
		}

		if (LowestLevelGraphRelevantStateName == "PerchJump" && LocomotionAnimationTag == n"AirMovement")
		{
			return (TopLevelGraphRelevantAnimTimeRemainingFraction < 0.5);
		}

		if(LowestLevelGraphRelevantStateName == "PerchJump" && LocomotionAnimationTag == n"Movement")
			return true;

		if (LocomotionAnimationTag == n"Landing")
		{
			return true;
		}

		if (GetAnimBoolParam(n"IsInTurnAround"))
		{
			return true;
		}

		return (TopLevelGraphRelevantAnimTimeRemainingFraction < 0.01);
	}

	UFUNCTION()
	void AnimNotify_HasLanded()
	{
		bIsLanding = true;
	}

	UFUNCTION()
	void AnimNotify_LeftLanding()
	{
		bIsLanding = false;
	}

	UFUNCTION()
	void AnimNotify_EnteredEnter()
	{
		bHasSettled = false;
		bSkipSplineStart = false;
	}

	UFUNCTION()
	void AnimNotify_LeftEnter()
	{
		bHasSettled = false;
	}

	UFUNCTION()
	void AnimNotify_HasJumped()
	{
		HeightDistanceToPoint = 0;
	}

	UFUNCTION()
	void AnimNotify_SplineLandMove()
	{
		bSkipSplineStart = true;
	}

	UFUNCTION()
	void AnimNotify_LeftPerch()
	{
		bCameFromGrapple = false;
		bIsHighUp = false;
		bSkipSplineStart = false;
		SetAnimBoolParam(n"PerchReady", false);
		bIsLanding = false;
	}

	UFUNCTION()
	void AnimNotify_EnteredPerchMh()
	{
		SetAnimBoolParam(n"PerchReady", true);
	}

	UFUNCTION()
	void AnimNotify_StartedRelaxing()
	{
		SetAnimBoolParam(n"PerchReady", false);
	}

	void InitialJumpCalculation()
	{
		if (PerchComponent.Data.TargetedPerchPoint != nullptr)
			PointPosition = PerchComponent.Data.TargetedPerchPoint.WorldLocation;

		EnterTime = 0;

		// Get player relative horizontal distance
		InitialDistanceToPoint = (PointPosition - Player.ActorLocation).ConstrainToPlane(Player.MovementWorldUp).Size();

		// Get vertical distance relative to player world up.
		HeightDistanceToPoint = (PointPosition - Player.ActorLocation).DotProduct(Player.MovementWorldUp);

		bIsFarAway = InitialDistanceToPoint > 400.0;

		bIsHighUp = HeightDistanceToPoint > 300.0;
	}
}
