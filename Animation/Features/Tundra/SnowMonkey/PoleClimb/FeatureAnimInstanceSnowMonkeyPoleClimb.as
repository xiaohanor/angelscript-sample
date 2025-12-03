UCLASS(Abstract)
class UFeatureAnimInstanceSnowMonkeyPoleClimb : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSnowMonkeyPoleClimb Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSnowMonkeyPoleClimbAnimData AnimData;

	UPlayerPoleClimbComponent PoleClimbComponent;

	FPlayerPoleClimbAnimData PoleClimbAnimData;




	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float VerticalVelocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float RotationSpeedAroundPole;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float JumpOutAngle;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bClimbing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSliding;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStoppedSliding;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bRightHand;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDashToClimb;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSlippingDown;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPerformingLeftTurnAround;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPerformingRightTurnAround;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTurnAroundEnter;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPoleAllowsFull360Rotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStartedLeftTurnAround;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStartedRightTurnAround;

	bool bJumping;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FName CachedLowestLevelStateName;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EPlayerPoleClimbState PoleClimbAnimationState;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{

		JumpOutAngle = 0.0;
		RotationSpeedAroundPole = 0.0;

		ULocomotionFeatureSnowMonkeyPoleClimb NewFeature = GetFeatureAsClass(ULocomotionFeatureSnowMonkeyPoleClimb);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		PoleClimbComponent = UPlayerPoleClimbComponent::Get(HazeOwningActor.AttachParentActor);

		ClearAnimBoolParam (n"RightHand");


	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{	
		if (Feature == nullptr)
			return;


		bJumping = PoleClimbComponent.AnimData.bJumping;
		RotationSpeedAroundPole = PoleClimbComponent.AnimData.PoleRotationSpeed;
		PoleClimbAnimationState = PoleClimbComponent.AnimData.State;
		bDashToClimb = PoleClimbComponent.AnimData.PoleClimbVerticalInput>= 0.01;
		CachedLowestLevelStateName = GetLowestLevelGraphRelevantStateName();
		VerticalVelocity = PoleClimbComponent.AnimData.PoleClimbVerticalVelocity;

		bRightHand = GetAnimBoolParam (n"RightHand", bConsume = false, bDefaultValue =  false);

		bClimbing = PoleClimbComponent.AnimData.PoleClimbVerticalInput>= 0.01;
		bool bNewSliding = PoleClimbComponent.AnimData.PoleClimbVerticalInput<= -0.01;
		bStoppedSliding = CheckValueChangedAndSetBool(bSliding, bNewSliding, EHazeCheckBooleanChangedDirection::TrueToFalse);
		bTurnAroundEnter = PoleClimbComponent.AnimData.bTurnAroundEnter;
		bPoleAllowsFull360Rotation = PoleClimbComponent.DoesPoleAllowFull360Rotation();

		bStartedLeftTurnAround = (CheckValueChangedAndSetBool(bPerformingLeftTurnAround, PoleClimbComponent.AnimData.bPerformingLeftTurnAround, EHazeCheckBooleanChangedDirection::FalseToTrue));
		bStartedRightTurnAround = (CheckValueChangedAndSetBool(bPerformingRightTurnAround, PoleClimbComponent.AnimData.bPerformingRightTurnAround, EHazeCheckBooleanChangedDirection::FalseToTrue));

		
	

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

		if (PoleClimbComponent.AnimData.SlipVelocity < 0)
		{
			bSlippingDown = true;
		}
			
		else
		{
			bSlippingDown = false;
		}
		
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag != n"AirMovement" || GetTopLevelGraphRelevantStateName() == n"Climb")
		{
			return true;
		}
		else
		{
			return TopLevelGraphRelevantAnimTimeRemaining <= HazeAnimation::ANIMATION_MIN_TIME;
		}
		
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{

	}

	

}
