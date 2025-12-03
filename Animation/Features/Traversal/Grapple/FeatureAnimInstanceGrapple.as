enum EHazeGrappleTurnDirection
{
	Forward,
	TurnToLeft,
	TurnToRight,
	
};


UCLASS(Abstract)
class UFeatureAnimInstanceGrapple : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(BlueprintHidden, NotEditable)
	ULocomotionFeatureGrapple Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FLocomotionFeatureGrappleAnimData AnimData;

	// Add Custom Variables Here

	UPROPERTY()
	UPlayerMovementComponent MoveComponent;

	UPROPERTY()
	UPlayerGrappleComponent GrappleComponent;

	UPROPERTY()
	UPlayerSlideComponent SlideComponent;

	UPROPERTY()
	UPlayerSlideJumpComponent SlideJumpComponent;

	UPROPERTY()
	UPlayerSprintComponent SprintComponent;

	UPROPERTY()
	UPlayerAirMotionComponent AirMotionComp;

	UPROPERTY()
	EHazeGrappleHookHeightMomentumAnimationType HeightDirection;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FPlayerGrappleAnimData GrappleAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EHazeGrappleTurnDirection TurnDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EPlayerGrappleStates GrappleState;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ESlideGrappleVariants SlideVariants;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector GrappleWorldPos;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ArmAimAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float StartCalculatingArmAimAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasLeftThrowState;
	
	UPROPERTY()
	bool bIsGrounded;

	UPROPERTY()
	bool bIsThrowing;

	UPROPERTY()
	bool bIsInterrupting;

	UPROPERTY()
	float InitialAngleDifference;

	UPROPERTY()
	float AngleDifference;

	UPROPERTY()
	float InitialHeightDifference;

	UPROPERTY()
	float HeightDifference;

	UPROPERTY()
	float InitialDistanceToTarget;

	UPROPERTY()
	float DistanceToTarget;

	UPROPERTY()
	bool bWasGrounded;

	UPROPERTY()
	bool bIsInLaunchMH;

	UPROPERTY()
	bool bIsInSlideMH;

	UPROPERTY()
	bool bSlideLanding;

	UPROPERTY()
	bool bIsInWallRunPullMH;

	UPROPERTY()
	bool bIsInWallRunEnter;

	UPROPERTY()
	bool bWallRunToTheLeft;

	UPROPERTY()
	bool bGrappleToPointAerialExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShouldPerformQuickPerchEnter;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShouldPerformGrappleToPerchExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasInput;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator AngleToPoint;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator InitialAngleToPoint;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float PitchAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector Diff;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector StartDiff;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float LaunchPitchAngle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float InitialDiff;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bResetGrapple;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float MoveSpeed;

	bool bWasSprintToggled;

	bool bStartedSlideJump;

	float PitchInterpSpeed = 0;

	// UPROPERTY()
	// bool bGrappling;

	// UPROPERTY()
	// bool bPerchGrappling;

	// UPROPERTY()
	// bool bLaunching;

	// UPROPERTY()
	// bool bIsInEnter;

	// UPROPERTY()
	// bool bIsWallRunGrappling;
	
	// UPROPERTY()
	// bool bIsSlideGrappling;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHighSpeedLandingDetected = false;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "Slide")
	FRotator SlideSlopeRotation;
	
	FVector InterpolatedFloorNormal;
	bool bCalculateSlopeAngles;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureGrapple NewFeature = GetFeatureAsClass(ULocomotionFeatureGrapple);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		GrappleComponent = UPlayerGrappleComponent::GetOrCreate(Player);
		MoveComponent = UPlayerMovementComponent::GetOrCreate(Player);
		SlideComponent = UPlayerSlideComponent::GetOrCreate(Player);
		SlideJumpComponent = UPlayerSlideJumpComponent::GetOrCreate(Player);
		SprintComponent = UPlayerSprintComponent::GetOrCreate(Player);
		AirMotionComp = UPlayerAirMotionComponent::Get(Player);

		if (GrappleComponent == nullptr)
			return;

		if (GrappleComponent.Data.CurrentGrapplePoint == nullptr)
			return;

		// Implement Custom Stuff Here
		bIsInterrupting = false;

		bIsThrowing = false;

		bIsInLaunchMH = false;

		bIsInSlideMH = false;

		bSlideLanding = false;

		bIsInWallRunPullMH = false;

		bIsInWallRunEnter = false;

		bCalculateSlopeAngles = false;
		
		bGrappleToPointAerialExit = false;

		ArmAimAlpha = 0;

		StartCalculatingArmAimAlpha = 0;

		PitchInterpSpeed = 0;

		bHasLeftThrowState = false;

		bWasGrounded = MoveComponent.IsOnWalkableGround();

		InitialDiff = (GrappleComponent.Data.CurrentGrapplePoint.WorldLocation - HazeOwningActor.ActorLocation).Size();

		PitchAlpha = 0;

		InitialAngleDifference = GrappleComponent.AnimData.AngleDiff;

		StartDiff = GrappleComponent.Data.CurrentGrapplePoint.WorldLocation - HazeOwningActor.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.1;
	}
	

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		if (GrappleComponent == nullptr)
			return;

		// Implement Custom Stuff Here

		GrappleAnimData = GrappleComponent.AnimData;

		DistanceToTarget = GrappleComponent.DistToTarget;
		
		AngleDifference = GrappleComponent.AnimData.AngleDiff;

		HeightDifference = GrappleComponent.AnimData.HeightDiff;

		bIsGrounded = MoveComponent.IsOnWalkableGround();

		bHasInput = !MoveComponent.SyncedMovementInputForAnimationOnly.IsNearlyZero();

		GrappleState = GrappleComponent.Data.GrappleState;

		MoveSpeed = MoveComponent.HorizontalVelocity.Size();

		bWasSprintToggled = SprintComponent.IsSprintToggled();

		SlideVariants = GrappleComponent.Data.SlideGrappleVariant;

		bStartedSlideJump = SlideJumpComponent.bStartedJump;

		bHighSpeedLandingDetected = AirMotionComp.AnimData.bHighVelocityLandingDetected;

		bGrappleToPointAerialExit = GrappleComponent.AnimData.bGrappleToPointAirborneExit;

		bShouldPerformQuickPerchEnter = GrappleComponent.AnimData.bPerformQuickPerchGrapple;

		// bGrappling = GrappleComponent.AnimDataGrapple.bGrappling;

		// bPerchGrappling = GrappleComponent.AnimDataGrapple.bPerchGrappling;
		
		// bLaunching = GrappleComponent.AnimDataGrapple.bLaunching;

		// bIsSlideGrappling = GrappleComponent.AnimDataGrapple.bSliding;

		// bIsInEnter = GrappleComponent.AnimDataGrapple.bInEnter;
		
		// bIsWallRunGrappling = GrappleComponent.AnimDataGrapple.bWallrunGrappling;

		//bIsThrowing = GrappleComponent.bInEnter;

		if (GrappleComponent.Data.CurrentGrapplePoint != nullptr)
			{
				GrappleWorldPos = GrappleComponent.Data.CurrentGrapplePoint.WorldLocation;
				//DistToTarget = Direction.Size();
				Diff = GrappleComponent.Data.CurrentGrapplePoint.WorldLocation - HazeOwningActor.ActorLocation;
				InitialHeightDifference = Diff.Z;
				FVector FlattenedDirection = Diff.ConstrainToPlane(MoveComponent.WorldUp);
				// float AngleDiff = Math::Acos(FlattenedDirection.GetSafeNormal().DotProduct(OwningActor.ActorForwardVector));
				AngleDifference = Math::Atan2(FlattenedDirection.DotProduct(HazeOwningActor.ActorRightVector), FlattenedDirection.DotProduct(HazeOwningActor.ActorForwardVector));
				AngleDifference = Math::RadiansToDegrees(AngleDifference);

				FVector UnRotated = HazeOwningActor.ActorRotation.UnrotateVector(Diff);
				AngleToPoint = FRotator::MakeFromXY(UnRotated, FVector::RightVector);
			}

		// else
		// 	{
		// 		PitchAlpha = 0;
		// 		InitialAngleDifference = AngleDifference;
		// 		PrintToScreenScaled("Hej", 0.f, Scale = 3.f);
		// 	}
			
		if (CheckValueChangedAndSetBool(bResetGrapple, GrappleComponent.Data.GrappleState == EPlayerGrappleStates::Inactive, EHazeCheckBooleanChangedDirection::TrueToFalse))
		{
			InitialDiff = (GrappleComponent.Data.CurrentGrapplePoint.WorldLocation - HazeOwningActor.ActorLocation).Size();
			InitialAngleDifference = GrappleComponent.AnimData.AngleDiff;
		}
		
		if (InitialAngleDifference > 70)
		{
			TurnDirection = EHazeGrappleTurnDirection :: TurnToRight;
		}
		else if (InitialAngleDifference < -70)
		{
			TurnDirection = EHazeGrappleTurnDirection :: TurnToLeft;
		}
		else
			TurnDirection = EHazeGrappleTurnDirection :: Forward;
		
		
		// if (CheckValueChangedAndSetBool(bIsThrowing, GrappleComponent.AnimData.bInEnter, TriggerDirection = EHazeCheckBooleanChangedDirection::FalseToTrue))
		// {
		// 	FVector Direction = GrappleComponent.Data.CurrentGrapplePoint.WorldLocation - HazeOwningActor.ActorLocation;
		// 	//DistToTarget = Direction.Size();
		// 	FVector Diff = GrappleComponent.Data.CurrentGrapplePoint.WorldLocation - HazeOwningActor.ActorLocation;
		// 	InitialHeightDifference = Diff.Z;
		// 	FVector FlattenedDirection = Direction.ConstrainToPlane(MoveComponent.WorldUp);
		// 	// float AngleDiff = Math::Acos(FlattenedDirection.GetSafeNormal().DotProduct(OwningActor.ActorForwardVector));
		// 	AngleDifference = Math::Atan2(FlattenedDirection.DotProduct(HazeOwningActor.ActorRightVector), FlattenedDirection.DotProduct(HazeOwningActor.ActorForwardVector));
		// 	AngleDifference = Math::RadiansToDegrees(AngleDifference);
		// 	InitialAngleDifference = AngleDifference;
		// 	InitialDistanceToTarget = GrappleComponent.DistToTarget;

		// 	GrappleWorldPos = GrappleComponent.Data.CurrentGrapplePoint.WorldLocation;
			

		// }
		
		//__________________________________________________________________________
		//TO DO: Physical animation, maybe only on the legs, activated in pull state
		//__________________________________________________________________________

		//If we are Launching or performing GrappleToGround then lean into the velocity direction to not remain entirely horizontal during the launch / not Level out during the end of GrappleToGround
		if ((GetLowestLevelGraphRelevantStateName() == "Launch" || GetLowestLevelGraphRelevantStateName() == "LaunchMH" || GetLowestLevelGraphRelevantStateName() == "ToLaunch")
			 || GrappleComponent.Data.GrappleState == EPlayerGrappleStates::GrappleToPointGrounded)
		{
			PitchInterpSpeed = Math::FInterpConstantTo(PitchInterpSpeed, 20, DeltaTime, 10);
			PitchAlpha = Math::FInterpTo(PitchAlpha, 1, DeltaTime, PitchInterpSpeed);

			float ForwardToVelocityPitchAngle = Math::Clamp(Math::RadiansToDegrees(MoveComponent.Velocity.GetSafeNormal().AngularDistanceForNormals(MoveComponent.HorizontalVelocity.GetSafeNormal())) * 1, -45, 45);
			ForwardToVelocityPitchAngle *= -Math::Sign(MoveComponent.VerticalVelocity.DotProduct(-MoveComponent.WorldUp));

			LaunchPitchAngle = ForwardToVelocityPitchAngle;
		}
		else
		{
			if (InitialDiff != 0)
			{

				if(Diff.Size() <= GrappleComponent.Settings.TriggerLandingDistance)
				{
					float NewPitchAlpha = Math::Lerp(1, 0, ((GrappleComponent.Settings.TriggerLandingDistance - Diff.Size()) / GrappleComponent.Settings.TriggerLandingDistance));

					if(NewPitchAlpha <= PitchAlpha)
						PitchAlpha = NewPitchAlpha;
				}
				else if (Diff.Size() / InitialDiff >= 0.3 && (GrappleState != EPlayerGrappleStates::GrappleToPointExit && GrappleState != EPlayerGrappleStates::GrappleToPointGroundedExit && GrappleState != EPlayerGrappleStates::Inactive))
				{
					//Lerp to full alpha if we are 30% or more into travelling towards the point
					PitchAlpha = Math::FInterpTo(PitchAlpha, 1, DeltaTime, 2);		
				}
				else if (Diff.Size() / InitialDiff < 0.3 || (GrappleState == EPlayerGrappleStates::GrappleToPointExit || GrappleState == EPlayerGrappleStates::GrappleToPointGroundedExit || GrappleState == EPlayerGrappleStates::Inactive))
				{
					//Lerp to 0 alpha if we are less then 30% into travelling towards the point
					PitchAlpha = Math::FInterpTo(PitchAlpha, 0, DeltaTime, 4);
				}
				// else
				// 	PitchAlpha = 0;
			}
			else
				PitchAlpha = 0;
		}	
	
		StartCalculatingArmAimAlpha += DeltaTime;

		if (StartCalculatingArmAimAlpha > 0.2)
		{
			if (GrappleState == EPlayerGrappleStates::GrappleEnter)
				ArmAimAlpha = Math::FInterpTo(ArmAimAlpha, 1, DeltaTime, 5);	

			if (bHasLeftThrowState && ((GrappleState != EPlayerGrappleStates::GrappleSlide) && (GrappleState != EPlayerGrappleStates::GrappleEnter)))
			//ArmAimAlpha = Math::Clamp(ArmAimAlpha - DeltaTime / 0.05, 0.0, 0.85);
				ArmAimAlpha = Math::FInterpTo(ArmAimAlpha, 0, DeltaTime, 15);
			
			if (bHasLeftThrowState && ((GrappleState == EPlayerGrappleStates::GrappleSlide) && (GrappleState != EPlayerGrappleStates::GrappleEnter)))
			//ArmAimAlpha = Math::Clamp(ArmAimAlpha - DeltaTime / 0.05, 0.0, 0.85);
				ArmAimAlpha = Math::FInterpTo(ArmAimAlpha, 0, DeltaTime, 30);
			
			else
				ArmAimAlpha = Math::FInterpTo(ArmAimAlpha, 0, DeltaTime, 10);	
		}

		// // if (StartCalculatingArmAimAlpha > 0.2)
		// // {
		// // 	if (bHasLeftThrowState)
		// // 		//ArmAimAlpha = Math::Clamp(ArmAimAlpha - DeltaTime / 0.05, 0.0, 0.85);
		// // 		ArmAimAlpha = Math::FInterpTo(ArmAimAlpha, 0, DeltaTime, 10);
		// // 	else
		// // 		ArmAimAlpha = Math::FInterpTo(ArmAimAlpha, 1, DeltaTime, 1);
		// // 		//ArmAimAlpha = Math::Clamp(ArmAimAlpha - DeltaTime / 0.2, 0.0, 0.85);
		// // }

		// else
		// 	StartCalculatingArmAimAlpha += DeltaTime;

		//
		

		// Slope angle
		if (bCalculateSlopeAngles)
			UpdateSmoothSlopeRotation(DeltaTime, 5);
	}

	/**
	 * Calculate the slope rotation used when goint into Slide
	 */
	void UpdateSmoothSlopeRotation(float DeltaTime, float InterpSpeed)
	{
		// Interpolate the floor normal
		const FVector CurrentGroundNormal = MoveComponent.GetGroundContact().bBlockingHit ? MoveComponent.GetCurrentGroundNormal() : HazeOwningActor.ActorUpVector;
		InterpolatedFloorNormal = Math::VInterpTo(InterpolatedFloorNormal, CurrentGroundNormal, DeltaTime, InterpSpeed);

		// Turn the normal into a rotator
		// TODO: This can be done in a better way, just doing this InverseTransformVectorNoScale now to fix the issue
		SlideSlopeRotation = FRotator::MakeFromZY(
			Player.ActorTransform.InverseTransformVectorNoScale(InterpolatedFloorNormal), 
			Player.ActorTransform.InverseTransformVectorNoScale(HazeOwningActor.ActorRightVector)
			);
		SlideSlopeRotation.Yaw = 0;
	}
	

	UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom() const
    {
        // Implement Custom Stuff Here
        if ((LocomotionAnimationTag != n"AirMovement" && LocomotionAnimationTag != n"Slide") &&
        (LowestLevelGraphRelevantStateName != n"ToPointExit" && LowestLevelGraphRelevantStateName != n"ToPointExitStill" && LowestLevelGraphRelevantStateName != n"ToPointGroundedExit" && LowestLevelGraphRelevantStateName != n"ToPointGroundedExitStill"))
        {
            return true;
        }
        if ((LowestLevelGraphRelevantStateName == n"Launch" || LowestLevelGraphRelevantStateName == n"LaunchMH") && (LocomotionAnimationTag != n"Movement" && LocomotionAnimationTag != n"AirMovement"))
        {
            return true;
        }
        if ((LowestLevelGraphRelevantStateName == n"LandingAnticipation" || LowestLevelGraphRelevantStateName == n"LandingAnticipationMH") && (LocomotionAnimationTag != n"AirMovement"))
        {
            return true;
        }
        if ((LowestLevelGraphRelevantStateName == n"Launch" || LowestLevelGraphRelevantStateName == n"LaunchMH") && MoveComponent.HorizontalVelocity.Size() <= AirMotionComp.Settings.HorizontalMoveSpeed)
        {
            return true;
        }
        if (LowestLevelGraphRelevantStateName == n"ToPointExit" && ((IsLowestLevelGraphRelevantAnimFinished() == true) || (LocomotionAnimationTag != n"Movement" && LocomotionAnimationTag != n"AirMovement")))
        {
            return true;
        }
        if (LowestLevelGraphRelevantStateName == n"ToPointExitStill" && (((IsLowestLevelGraphRelevantAnimFinished() == true) ||
            (LocomotionAnimationTag != n"Movement" && LocomotionAnimationTag != n"AirMovement" && LocomotionAnimationTag != n"Landing")) ||
                (LocomotionAnimationTag == n"Movement" && bHasInput && LowestLevelGraphRelevantAnimTime >= 0.7) || LocomotionAnimationTag == n"Movement"))
        {
            return true;
        }
        if (LowestLevelGraphRelevantStateName == n"ToPointGroundedExit" && ((IsLowestLevelGraphRelevantAnimFinished() == true) ||
            (LocomotionAnimationTag != n"Movement" && LocomotionAnimationTag != n"AirMovement")))// || (LowestLevelGraphRelevantAnimTimeFraction >= 0.4 && !bHasInput)))
        {
            return true;
        }
        if (LowestLevelGraphRelevantStateName == n"ToPointGroundedExitStill" && ((IsLowestLevelGraphRelevantAnimFinished() == true) ||
        (LocomotionAnimationTag != n"Movement" && LocomotionAnimationTag != n"AirMovement") || (LowestLevelGraphRelevantAnimTimeFraction >= 0.5 && bHasInput)))// || (LowestLevelGraphRelevantAnimTimeFraction >= 0.4 && !bHasInput)))
        {
            return true;
        }
        if (LocomotionAnimationTag == n"Slide"  && (LowestLevelGraphRelevantStateName == n"SlideLanding" || LowestLevelGraphRelevantStateName == n"ToSlideClose") && IsLowestLevelGraphRelevantAnimFinished())
        {
            return true;
        }
        if (LowestLevelGraphRelevantStateName == n"ToWallRun" && LocomotionAnimationTag == n"AirMovement")
        {
            return true;
        }
        if (LowestLevelGraphRelevantStateName == n"ToPointAirborneExit" && (LocomotionAnimationTag == n"AirMovement" || LocomotionAnimationTag == n"Movement") && LowestLevelGraphRelevantAnimTimeFraction >= 0.4)
        {
            return true;
        }
        //If we are requesting air motion and are not in Launch animations / in a certain period of the grounded exit to point animation then allow it
        if (LocomotionAnimationTag == "AirMovement" &&  LowestLevelGraphRelevantStateName != n"ToPointAirborneExit" && (
            ((LowestLevelGraphRelevantStateName == n"ToPointGroundedExitStill" || LowestLevelGraphRelevantStateName == n"ToPointGroundedExit") && LowestLevelGraphRelevantAnimTimeFraction >= 0.2)
                || (LowestLevelGraphRelevantStateName != n"Launch" && LowestLevelGraphRelevantStateName != n"LaunchMH" && LowestLevelGraphRelevantStateName != n"LandingAnticipation" && LowestLevelGraphRelevantStateName != n"LandingAnticipationMH")
                    /*|| Maybe add slide requirement here ()*/)
                        )
            return true;
        if (bStartedSlideJump)
        {
            return true;
        }
        if (Player.IsPlayingAnyAnimationOnSlot(EHazeSlotAnimType::SlotAnimType_Default))
        {
            return true;
        }
        return LowestLevelGraphRelevantAnimTimeRemaining == SMALL_NUMBER;
    }

	

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
		if ((LowestLevelGraphRelevantStateName == n"ToPointExit" || LowestLevelGraphRelevantStateName == n"ToPointGroundedExit") && LocomotionAnimationTag == "Movement" && MoveComponent.Velocity.Size() >= 200)
			SetAnimFloatParam(n"MovementBlendTime", 0.1);

		if (LocomotionAnimationTag == n"Movement" && bWasSprintToggled)
		{
			SetAnimBoolParam(n"SkipSprintStart", true);
		}

	}

    UFUNCTION()
    void AnimNotify_StartCalculatingSlideAngle()
    {
		bCalculateSlopeAngles = true;
    }

    UFUNCTION()
    void AnimNotify_LeftThrowState()
    {
        bHasLeftThrowState = true;
		InitialAngleToPoint = AngleToPoint;
    }

	UFUNCTION()
    void AnimNotify_ResetGrappleInterrupt()
    {
        bHasLeftThrowState = false;
		bIsInterrupting = false;
		//StartCalculatingArmAimAlpha = 0;
    }

	UFUNCTION()
	void AnimNotify_EnableGrappleInterrupt()
	{
		bHasLeftThrowState = true;
	}
	
	UFUNCTION()
	void AnimNotify_FullyBlendedGrappleLaunchState()
	{
		if (bIsThrowing)
			bIsInterrupting = true;
	}

}
