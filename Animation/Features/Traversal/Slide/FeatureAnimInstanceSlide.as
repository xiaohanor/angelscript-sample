enum ESlideExitTypes
{
	Sprint,
	Idle,
	Jog,
	Jump
};

UCLASS(Abstract)
class UFeatureAnimInstanceSlide : UHazeFeatureSubAnimInstance
{
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSlide Feature;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSlideAnimData AnimData;

	UPlayerSlideJumpComponent SlideJumpComp;
	UAnimFootTraceComponent FootTraceComp;
	UPlayerSlideDashComponent SlideDashComp;
	UPlayerMovementComponent MoveComp;
	UPlayerSlideComponent SlideComp;
	UPlayerSprintComponent SprintComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCameFromGrapple;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCameFromAirMovement;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCameFromDash;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCameFromStepDash;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJumping;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJumpActive;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDashing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsZoe;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float TurnAngle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSlideFast;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "SlopeData")
	FRotator SlopeRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "SlopeData")
	float SlopeAlphaRoot;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "SlopeData")
	FHazeSlopeWarpingData SlopeWarpData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsSprinting;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ESlideExitTypes ExitType;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSkipEnter;

	FVector InterpolatedFloorNormal;

	const float WantedSlopeAlphaRoot = 0.4; // How much should we rotate the root to follow the slope ?
	const float SlideFastThreshold = 1650;	// When speed is above this value it'll transition into FastSlide

	bool bRotatePitchOnly;
	float TargetSlopeRotationAlpha;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSlide NewFeature = GetFeatureAsClass(ULocomotionFeatureSlide);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}
		if (Feature == nullptr)
			return;

		SlideJumpComp = UPlayerSlideJumpComponent::GetOrCreate(Player);
		SlideComp = UPlayerSlideComponent::GetOrCreate(Player);
		SlideDashComp = UPlayerSlideDashComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::GetOrCreate(Player);
		FootTraceComp = UAnimFootTraceComponent::GetOrCreate(Player);
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);

		bCameFromGrapple = (GetPrevLocomotionAnimationTag() == n"Grapple");
		bCameFromDash = GetPrevLocomotionAnimationTag() == n"Dash";
		bCameFromStepDash = (GetAnimBoolParam(n"WasStepDash", true));
		bCameFromAirMovement = (GetPrevLocomotionAnimationTag() == n"AirMovement") || (GetPrevLocomotionAnimationTag() == n"Jump");
		bIsZoe = Player.IsZoe();
		bSkipEnter = SlideComp.GetSlideParameters().bSkipEnterAnim;

		AnimNotify_ResetSlopeData();
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		if (PrevLocomotionAnimationTag == n"Dash")
			return 0;

		else if (PrevLocomotionAnimationTag == n"Grapple")
			return 0.2;

		return 0.1;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bJumping = SlideJumpComp.bStartedJump;
		bDashing = SlideDashComp.bDashing;
		bWantsToMove = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();
		bJumpActive = SlideComp.AnimData.bSlideJumpActive; // True for the whole jump duration

		if (bJumpActive)
			SetAnimBoolParam(n"SlideJumping", true);

		Speed = SlideComp.Speed;
		TurnAngle = SlideComp.TurnAngle;
		bSlideFast = bSlideFast ? !(Speed < SlideFastThreshold - 50.0) : Speed > SlideFastThreshold + 50.0;

		// Pick an exit type.
		ExitType = GetExitType();
		if (CheckValueChangedAndSetBool(bExit, LocomotionAnimationTag != Feature.Tag, EHazeCheckBooleanChangedDirection::FalseToTrue))
		{
			if (ExitType == ESlideExitTypes::Sprint)
			{
				bRotatePitchOnly = true;
				TargetSlopeRotationAlpha = 1;
			}
			else
				TargetSlopeRotationAlpha = 0;
		}

		TargetSlopeRotationAlpha = GetAnimFloatParam(n"CustomSlideRotationAlpha", true, TargetSlopeRotationAlpha);

		// Update slope rotation data
		FootTraceComp.UpdateSlopeWarpData(SlopeWarpData); // SlopeWarp data used for HazeSlopeWarping node

		// Rotation values used for the root
		SetSmoothSlopeRotation(DeltaTime);

		SlopeAlphaRoot = Math::FInterpTo(SlopeAlphaRoot, TargetSlopeRotationAlpha, DeltaTime, 3);

		bIsSprinting = SprintComp.IsSprinting();
	}

	/**
	 * Get what type of exit animation to play
	 */
	ESlideExitTypes GetExitType()
	{
		if (bIsSprinting)
			return ESlideExitTypes::Sprint;

		if (bWantsToMove && bIsSprinting == false && !MoveComp.IsInAir())
			return ESlideExitTypes::Jog;

		if (MoveComp.IsInAir())
			return ESlideExitTypes::Jump;

		return ESlideExitTypes::Idle;
	}

	/**
	 * Get the current slope rotation (interpolated)
	 */
	void SetSmoothSlopeRotation(float DeltaTime)
	{
		// Interpolate the floor normal
		FVector TargetFloorNormal = MoveComp.GetGroundContact().bBlockingHit ? MoveComp.GetCurrentGroundNormal() : HazeOwningActor.ActorUpVector;
		if (bRotatePitchOnly)
			TargetFloorNormal = TargetFloorNormal.VectorPlaneProject(Player.ActorUpVector.CrossProduct(Player.ActorForwardVector));

		InterpolatedFloorNormal = Math::VInterpTo(InterpolatedFloorNormal, TargetFloorNormal, DeltaTime, 9);

		SlopeRotation = FRotator::MakeFromZY(
			Player.ActorTransform.InverseTransformVector(InterpolatedFloorNormal),
			Player.ActorTransform.InverseTransformVector(HazeOwningActor.ActorRightVector));
		SlopeRotation.Yaw = 0;
	}

	UFUNCTION()
	void AnimNotify_ResetSlopeData()
	{
		InterpolatedFloorNormal = MoveComp.GetCurrentGroundImpactNormal();
		TargetSlopeRotationAlpha = WantedSlopeAlphaRoot;
		SlopeAlphaRoot = TargetSlopeRotationAlpha;
		bRotatePitchOnly = false;
		SlopeRotation = FRotator::ZeroRotator;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		SetAnimBoolParam(n"SlideJumping", false);
	}

}
