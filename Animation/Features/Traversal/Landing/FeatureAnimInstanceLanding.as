
UCLASS(Abstract)
class UFeatureAnimInstanceLanding : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(BlueprintHidden, NotEditable)
	ULocomotionFeatureLanding Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FLocomotionFeatureLandingAnimData AnimData;

	UAnimFootTraceComponent FootTraceComp;
	UPlayerLandingComponent LandingComp;
	UPlayerMovementComponent MovementComp;
	UPlayerSprintComponent SprintComp;
	UPlayerFloorMotionComponent FloorMotionComp;
	UPlayerActionModeComponent ActionModeComp;
	UHazeAnimPlayerBankingComponent BankingComp;

	// TODO: This component is currently unused, remove if we don't need it
	UPlayerFloorSlowdownComponent SlowdownComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	FHazeAnimIKFeetPlacementTraceDataInput IKFeetPlacementData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	FHazeSlopeWarpingData SlopeWarpData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	bool bEnableIKFeetPlacement;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	float IKAlpha = 1;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FPlayerLandingAnimationData LandingAnimData;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bUseActionMH;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bHasInput;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bGoingToJog;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bGoingToSprint;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float InitialHorizontalSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float InterpolatedSpeed;

	float PreviousInterpolatedSpeed;

	float VerticalLandingSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float InitialSpeedNormalized;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;
	
	UPROPERTY(BlueprintReadOnly, Category = "Banking")
	UHazeAnimBankingDataAsset BankingAsset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Banking")
	float Banking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Banking")
	float BankingValueOnComplete;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Banking")
	float FadingBankingValue;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float StopDistance;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float FallDistance;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHighLanding;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHighSpeedLanding;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLandingLeftFootFwd;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTurn180;

	bool bStartedToSprint;

	bool bWasSprintToggled;

	UPROPERTY()
	bool bIKEnabled = true;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsInActionMode;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (Player == nullptr)
			return;

		// Get Components
		FootTraceComp = UAnimFootTraceComponent::Get(Player);
		LandingComp = UPlayerLandingComponent::GetOrCreate(Player);
		MovementComp = UPlayerMovementComponent::GetOrCreate(Player);
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
		SlowdownComp = UPlayerFloorSlowdownComponent::Get(Player);
		FloorMotionComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
		ActionModeComp = UPlayerActionModeComponent::GetOrCreate(Player);
		BankingComp = UHazeAnimPlayerBankingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureLanding NewFeature = GetFeatureAsClass(ULocomotionFeatureLanding);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		LandingAnimData = LandingComp.AnimData;

		FootTraceComp.InitializeTraceDataVariable(IKFeetPlacementData);

		// Set Initial Speed when Landing
		InitialHorizontalSpeed = MovementComp.HorizontalVelocity.Size();
		InitialSpeedNormalized = MovementComp.HorizontalVelocity.Size();
		InitialSpeedNormalized = Math::Clamp(InitialSpeedNormalized, 0.0, 1.0);
		VerticalLandingSpeed = FloorMotionComp.AnimData.VerticalLandingSpeed;
		InterpolatedSpeed = InitialHorizontalSpeed;

		bLandingLeftFootFwd = !Player.IsRightFootForward();

		SetAnimBoolParam(n"RequestingMeshUpperBodyOverrideAnimation", true);
		SetAnimBoolParam(n"GravityWhipLanding", true);

		if (VerticalLandingSpeed >= Feature.LandHighThreshold)
		{
			bHighLanding = true;
		}
		else
		{
			bHighLanding = false;
		}

		// FallDistance = (MovementComp.FallingData.StartLocation - HazeOwningActor.ActorLocation).ConstrainToPlane(Player.ActorForwardVector).Size();
		// if (FallDistance >= Feature.LandHighThreshold)
		// {
		// 	bHighLanding = true;
		// }
		// else
		// {
		// 	bHighLanding = false;
		// }

		// bLandingLeftFootFwd = false;

		bWasSprintToggled = SprintComp.IsSprintToggled();

		bStartedToSprint = false;

		bUseActionMH = Feature.bUseActionMH;

		bHighSpeedLanding = FloorMotionComp.AnimData.bTriggeredHighSpeedLanding;

		//Reinitialize IK state
		bIKEnabled = true;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		if (LandingAnimData.State == EPlayerLandingState::Standard)
			return 0.06;
		else
			return 0.06;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		Speed = MovementComp.HorizontalVelocity.Size();
		bHasInput = !MovementComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();

		const float BankingTarget = Math::FInterpTo(Banking, BankingComp.GetBankingRatio(DeltaTime, BankingAsset.BankingSettings), DeltaTime, 4);
		
		Banking = BankingTarget;

		if (LowestLevelGraphRelevantStateName == n"HighSpeedMove")
		{
			FadingBankingValue = Math::FInterpTo(FadingBankingValue, Banking, DeltaTime, 1);
		}
		else
		{
			FadingBankingValue = Banking;
		}

		FadingBankingValue = Math::FInterpTo(FadingBankingValue, BankingValueOnComplete, DeltaTime, 1);
		
		// bLandingLeftFootFwd = GetAnimBoolParam(n"LandingLeftFootFwd", false, false);

		// bTurn180 = GetAnimTrigger(n"Turn180") || GetAnimTrigger(n"SprintTurn180");

		bStartedToSprint = CheckValueChangedAndSetBool(bStartedToSprint, SprintComp.IsSprinting(), EHazeCheckBooleanChangedDirection::FalseToTrue);

		InterpolatedSpeed = Math::FInterpTo(InterpolatedSpeed, Speed, DeltaTime, 10);

		bTurn180 = FloorMotionComp.AnimData.bTurnaroundTriggered;


		// TODO: This could be an Enum instead of keeping track of multiple bools //ns
		if (InitialHorizontalSpeed <= 1000)
		{
			bGoingToJog = true;
			bGoingToSprint = false;
		}
		else if (InitialHorizontalSpeed > 1000)
		{
			bGoingToSprint = true;
			bGoingToJog = false;
		}
		else
		{
			bGoingToSprint = false;
			bGoingToJog = false;
		}

		// IK Data
		bEnableIKFeetPlacement = FootTraceComp.AreRequirementsMet();
		if (!bEnableIKFeetPlacement)
			FootTraceComp.UpdateSlopeWarpData(SlopeWarpData);
		else
			FootTraceComp.TraceFeet(IKFeetPlacementData);

		// Action MH or not

		if ((ActionModeComp.IsCurrentlyInActionMode && ActionModeComp.CurrentActionMode != EPlayerActionMode::BlockActionMode && bUseActionMH) || (ActionModeComp.CurrentActionMode == EPlayerActionMode::ForceActionMode && bUseActionMH))
		{
			bIsInActionMode = true;
		}
		else
			bIsInActionMode = false;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// If player initiates a 180 turn
		// if (bTurn180)
		// 	return true;

		if (!bWasSprintToggled && bStartedToSprint)
			return true;

		if (LocomotionAnimationTag != n"Movement" && LocomotionAnimationTag != n"AirMovement")
			return true;

		if (LocomotionAnimationTag == n"AirMovement" && TopLevelGraphRelevantStateName != n"LandingToMovement")
			return true;

		if (bHighSpeedLanding)
		{
			if (TopLevelGraphRelevantStateName != n"HighSpeedLanding" && IsTopLevelGraphRelevantAnimFinished())
				return true;
			
			else
				return false;
		}

		if (LocomotionAnimationTag == n"Movement" && (FloorMotionComp.AnimData.bTurnaroundTriggered || FloorMotionComp.AnimData.bSprintTurnaroundTriggered))
			return true;

		// Ensuring that the player doesn't interpolate backwards if blending out of a High Landing in motion (animation is a roll) to Air Movement. This way the character always blends out of the roll in the same direction as the momentum
		if (LocomotionAnimationTag == n"AirMovement" && TopLevelGraphRelevantStateName == n"LandingToMovement" && (!bHighLanding || (TopLevelGraphRelevantStateName == n"LandingToMovement" && bHighLanding && TopLevelGraphRelevantAnimTimeFraction >= 0.15)))
			return true;

		if (TopLevelGraphRelevantStateName == n"ToMovement" && !bHasInput && !bHighLanding && !bHighSpeedLanding)
			return true;

		if (TopLevelGraphRelevantStateName == n"ExitFromStill")
			return true;

		if (bTurn180)
			return true;

		if (GetOverrideFeatureTag() == n"GravityWhip")
			return TopLevelGraphRelevantAnimTimeRemainingFraction < 0.9;

		if (GetAnimBoolParam(n"RequestingFullBodyOverride", true))
			return true;

		// If we're playing a ToMovement anim but stop giving input
		// if (!bHasInput && LowestLevelGraphRelevantAnimTimeRemainingFraction <= 0.75 && (TopLevelGraphRelevantStateName == n"LandingToMovement" || TopLevelGraphRelevantStateName == n"ToMovement"))
		// 	return true;

		// If we're playing ToMh stop but start giving input, leave ABP
		// if (bHasInput && MovementComp.GetSyncedMovementInputForAnimationOnly().IsNearlyZero(0.0) && TopLevelGraphRelevantStateName == n"LandingToStill")
		// 	return true;

		return IsLowestLevelGraphRelevantAnimFinished();

		// return IsTopLevelGraphRelevantAnimFinished() == true;

		// return TopLevelGraphRelevantAnimTimeRemaining <= 0.03;
		/*
		return true;
		*/
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// If we're going into movement

		if (LocomotionAnimationTag == n"Movement")
		{
			if (bTurn180 || FloorMotionComp.AnimData.bTurnaroundTriggered)
			{
				SetAnimBlendTimeToMovement(Player, 0.0);
			}

			else if ((TopLevelGraphRelevantStateName == n"LandingToMovement" && bHasInput) || (TopLevelGraphRelevantStateName == n"ToMovement" && bHasInput) || (TopLevelGraphRelevantStateName == n"HighSpeedMove"))
			{
				SetAnimBlendTimeToMovement(Player, 0.1);
			}

			else if (TopLevelGraphRelevantStateName == n"LandingToMovement" && !bHasInput && !bHighLanding)
			{
				SetAnimBlendTimeToMovement(Player, 0.2);
			}

			else
			{
				SetAnimBlendTimeToMovement(Player, 0.2); // If we want a custom blend time when going into Movement
			}
		}

		bLandingLeftFootFwd = false;

		ClearAnimBoolParam(n"LandingLeftFootFwd");

		SetAnimBoolParam(n"RequestingMeshUpperBodyOverrideAnimation", false);
		SetAnimBoolParam(n"GravityWhipLanding", false);

		if (LocomotionAnimationTag == n"Movement" && bWasSprintToggled)
		{
			SetAnimBoolParam(n"SkipSprintStart", true);
		}

		if (LocomotionAnimationTag == n"Movement" && bIsInActionMode) // If going into movement in Action Mh so that we go straight into Action Mh
		{
			SetAnimBoolParam(n"ExitedToActionMH", true);
		}
	}

	UFUNCTION()
	FName GetCurrentAnimTag()
	{
		if (bHighLanding)
			return n"LandingHigh";

		return Feature.Tag;
	}

	UFUNCTION()
    void AnimNotify_HighSpeedLandingComplete()
    {
		BankingValueOnComplete = Banking;
		bIKEnabled = true;
    }

	UFUNCTION()
	void AnimNotify_HighSpeedLandingStart()
	{
		bIKEnabled = false;
	}

}
