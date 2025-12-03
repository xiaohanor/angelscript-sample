UCLASS(Abstract)
class UFeatureAnimInstanceSnowMonkeyPerch : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSnowMonkeyPerch Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSnowMonkeyPerchAnimData AnimData;

	UPlayerPerchComponent PerchComponent;
	UPlayerMovementComponent MovementComponent;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	bool bPerching;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	bool bInEnter;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	bool bEnterLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJumping;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJumpingOff;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasInput;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	float RotationRateInterpolated;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float RotationRate;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bOnSpline;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSnowMonkeyPerch NewFeature = GetFeatureAsClass(ULocomotionFeatureSnowMonkeyPerch);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		PerchComponent = UPlayerPerchComponent::Get(HazeOwningActor.AttachParentActor);
		MovementComponent = UPlayerMovementComponent::Get(HazeOwningActor.AttachParentActor);

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bPerching = PerchComponent.Data.bPerching && !PerchComponent.Data.bSplineJump;

		bInEnter = PerchComponent.AnimData.bInEnter || PerchComponent.AnimData.bInGroundedEnter;

		bJumping = PerchComponent.Data.bJumpingOff || PerchComponent.Data.bSplineJump;

		bJumpingOff = PerchComponent.Data.bJumpingOff && !PerchComponent.Data.bPerching;

		bHasInput = !MovementComponent.SyncedMovementInputForAnimationOnly.IsNearlyZero();

		bOnSpline = PerchComponent.Data.bInPerchSpline;

		Speed = MovementComponent.Velocity.Size();

		float InterpSpeed = Math::Abs(RotationRate) > MovementComponent.GetMovementYawVelocity(false) / 250.0 ? 3.0 : 2.0;
		RotationRate = (MovementComponent.GetMovementYawVelocity(false) / 250.0);
		RotationRateInterpolated = Math::FInterpTo(RotationRateInterpolated, RotationRate, DeltaTime, InterpSpeed);		

	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag == n"AirMovement")
		{
			if (LowestLevelGraphRelevantStateName == n"JumpStillLeft" || LowestLevelGraphRelevantStateName == n"JumpStillRight" || LowestLevelGraphRelevantStateName == n"JumpOffLeft" || LowestLevelGraphRelevantStateName == n"JumpOffRight" || LowestLevelGraphRelevantStateName == n"SplineJumpOff" || LowestLevelGraphRelevantStateName == n"SplineJump")
				return LowestLevelGraphRelevantAnimTimeRemaining <= HazeAnimation::ANIMATION_MIN_TIME;
			else
				return true;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}


    UFUNCTION()
    void AnimNotify_CameFromLeft()
    {
        bEnterLeft = false;
    }

	UFUNCTION()
    void AnimNotify_CameFromRight()
    {
        bEnterLeft = true;
    }

}
