UCLASS(Abstract)
class UFeatureAnimInstancePoleClimb : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeaturePoleClimb Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeaturePoleClimbAnimData AnimData;

	// Add Custom Variables Here

	UPlayerPoleClimbComponent PoleClimbComponent;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bClimbing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bInEnter;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bClimbingDown;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bClimbingUp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bRotatingRight;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bRotatingLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJumping;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWasGrounded;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bClimbToPerch;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float JumpOutAngle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWasPerched;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float RotationSpeedAroundPole;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStartedClimbingUp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStoppedClimbingUp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStartedClimbingDown;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStoppedClimbingDown;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLeftFoot;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLetGo;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float VerticalVelocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDashUp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStartedDashingUp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPoleDashing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSlippingDown;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTurnAroundEnter;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPerformingLeftTurnAround;

	bool bStartedPerformingLeftTurnAround;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bResetLeftTurnAround;

	bool bStartedPerformingRightTurnAround;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bResetRightTurnAround;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPerformingRightTurnAround;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Lean")
	float LeanTimer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Lean")
	bool bLeanSideIsLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPoleClimbActive;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPoleAllowsFull360Rotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWillRotateJumpAlongPlayerRight;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EPlayerPoleClimbState PoleClimbAnimationState;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FPlayerPoleClimbAnimData PoleClimbAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EDashSideOverrideState DashSideOverride;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		/*
		 * Reset all variables
		 */
		bClimbing = false;
		bInEnter = false;
		bClimbingUp = false;
		bClimbingDown = false;
		bRotatingRight = false;
		bRotatingLeft = false;
		bJumping = false;
		bClimbToPerch = false;
		bStartedClimbingUp = false;
		bStoppedClimbingUp = false;
		bStartedClimbingDown = false;
		bStoppedClimbingDown = false;
		bLetGo = false;
		bDashUp = false;
		bStartedDashingUp = false;
		bIsPoleDashing = false;
		LeanTimer = 0;

		JumpOutAngle = 0.0;
		RotationSpeedAroundPole = 0.0;
		VerticalVelocity = 0.0;

		ULocomotionFeaturePoleClimb NewFeature = GetFeatureAsClass(ULocomotionFeaturePoleClimb);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		PoleClimbComponent = UPlayerPoleClimbComponent::GetOrCreate(Player);

		bWasGrounded = (GetPrevLocomotionAnimationTag() == n"Movement" || GetPrevLocomotionAnimationTag() == n"Landing" || GetPrevLocomotionAnimationTag() == n"Sprint");

		bWasPerched = PrevLocomotionAnimationTag == n"Perch";

	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		if (PrevLocomotionAnimationTag == n"Perch")
		{
			return 0.06;
		}
		else
		
		return 0.2;
	}
	

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		PoleClimbAnimData = PoleClimbComponent.AnimData;
		
		PoleClimbAnimationState = PoleClimbComponent.AnimData.State;

		bJumping = PoleClimbComponent.AnimData.bJumping;

		RotationSpeedAroundPole = PoleClimbComponent.AnimData.PoleRotationSpeed;

		bClimbToPerch = PoleClimbComponent.AnimData.bClimbingToPerchPoint;

		bLeftFoot = GetAnimBoolParam(n"PoleClimbLeftFootUp", bConsume = false);

		VerticalVelocity = PoleClimbAnimData.PoleClimbVerticalVelocity;

		bLetGo = PoleClimbAnimData.bCancellingPoleClimb;

		bInEnter = PoleClimbAnimData.bInEnter;

		bTurnAroundEnter = PoleClimbAnimData.bTurnAroundEnter;

		bIsPoleClimbActive = PoleClimbComponent.Data.ActivePole != nullptr;
		bPoleAllowsFull360Rotation = PoleClimbComponent.DoesPoleAllowFull360Rotation();

		bPerformingLeftTurnAround = PoleClimbAnimData.bPerformingLeftTurnAround;
		bPerformingRightTurnAround = PoleClimbAnimData.bPerformingRightTurnAround;

		bResetLeftTurnAround = (CheckValueChangedAndSetBool(bStartedPerformingLeftTurnAround, PoleClimbAnimData.bPerformingLeftTurnAround, EHazeCheckBooleanChangedDirection::FalseToTrue));
		bResetRightTurnAround = (CheckValueChangedAndSetBool(bStartedPerformingRightTurnAround, PoleClimbAnimData.bPerformingRightTurnAround, EHazeCheckBooleanChangedDirection::FalseToTrue));

		bRotatingLeft = PoleClimbAnimData.PoleRotationInput > 0.1;
		bRotatingRight = PoleClimbAnimData.PoleRotationInput < -0.1;

		bWillRotateJumpAlongPlayerRight = PoleClimbAnimData.bJumpingTowardsRight;
		DashSideOverride = PoleClimbComponent.AnimData.DashSideOverrideState;

		CheckValueChangedAndSetBool(bJumping, bJumping, EHazeCheckBooleanChangedDirection::FalseToTrue);
		{
			if (bJumping)
			{
				JumpOutAngle = PoleClimbComponent.AnimData.JumpOutAngle;
			}
			else
			{
				
				
			}
		}


		if (CheckValueChangedAndSetBool(bClimbingUp,PoleClimbComponent.AnimData.PoleClimbVerticalInput>= 0.01))
		{
			if (bClimbingUp)
			{

				bStartedClimbingUp = true;
				bIsPoleDashing = false;
			}

			else
			{

				bStoppedClimbingUp = true;
			}
		}

		else
		{
			bStartedClimbingUp = false;
			bStoppedClimbingUp = false;
		}
		
		if (CheckValueChangedAndSetBool(bClimbingDown,PoleClimbComponent.AnimData.PoleClimbVerticalInput<= -0.01))
		{
			if (bClimbingDown)
			{

				bStartedClimbingDown = true;
				bIsPoleDashing = false;

			}

			else
			{

				bStoppedClimbingDown = true;

			}
			
		}

		else
		{
			bStartedClimbingDown = false;
			bStoppedClimbingDown = false;
		}

		// bStartedDashingUp = (CheckValueChangedAndSetBool(bDashUp, PoleClimbComponent.AnimData.bJumpingUp, EHazeCheckBooleanChangedDirection::FalseToTrue));
		bStartedDashingUp = PoleClimbComponent.AnimData.bJumpingUp;
		PoleClimbComponent.AnimData.bJumpingUp = false;

		if (PoleClimbAnimData.SlipVelocity < 0 && bClimbingUp == false && bClimbingDown == false )
		{
			bSlippingDown = true;
		}
			
		else
		{
			bSlippingDown = false;
		}

		if (bClimbingUp || bClimbingDown || Math::Abs(RotationSpeedAroundPole) >= 15)
		{
			LeanTimer = 0;
		}
		else
		{
			LeanTimer += DeltaTime;
		}

#if !RELEASE
		FTemporalLog Log = TEMPORAL_LOG(this);
		Log.Value("bStartedDashingUp", bStartedDashingUp);
		Log.Value("LeftFoot", bLeftFoot);
		Log.Value("PoleDashing", bIsPoleDashing);
		Log.Value("ClimbingUp", bClimbingUp);
		Log.Value("Override:", DashSideOverride);
		Log.Value("AnimState: ", PoleClimbAnimationState);
		Log.Value("State:", GetLowestLevelGraphRelevantStateName());
#endif
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
	}
	
    UFUNCTION()
    void AnimNotify_StartedPoleDashing()
    {
        bIsPoleDashing = true;
    }

	UFUNCTION()
	void AnimNotify_OnPoleDashLeft()
	{
		PoleClimbComponent.AnimData.DashSideOverrideState = EDashSideOverrideState::Right;
	}

	UFUNCTION()
	void AnimNotify_OnPoleDashRight()
	{
		PoleClimbComponent.AnimData.DashSideOverrideState = EDashSideOverrideState::Left;
	}
}
