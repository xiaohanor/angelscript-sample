enum EDashExitTypes
{
	Idle,
	Movement,
	Sprint,
	Falling,
	Slide
};

UCLASS(Abstract)
class UFeatureAnimInstanceDash : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureDash Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureDashAnimData AnimData;

	UPlayerFloorSlowdownComponent SlowDownComponent;
	UPlayerMovementComponent MoveComponent; 
	UPlayerSprintComponent SprintComponent;
	UPlayerActionModeComponent ActionModeComp;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	UPlayerStepDashComponent StepDashComponent;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")	
	float SlopeAngle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	bool bStartStepDash;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStartRollDash;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsRightFootForward;

	UPROPERTY()
	bool bCameFromSprint;

	UPROPERTY()
	bool bHoldDashInput;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY()
	bool bSlowingDown;

	UPROPERTY()	
	bool bIsFalling;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsSprinting;

	UPROPERTY()
	EDashExitTypes ExitType;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsInStillFinishState;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsInMovingFinishState;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EStepDashDirection StepDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ExplicitStepDashFinishTimer;

	bool bCalculateExplicitTime;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasReachedExitState;

	FVector Velocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed; 

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float StoppingSpeed;

	bool bIsStopping;

	UPROPERTY()
	EDashFoot DashFoot;

	bool bIsInDashABP;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bUseLeftOrRightFootVariations;

	//Action MH-related variables
	
	
	bool bUseActionMH;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsInActionMode;

	//Custom Functions

	//Picks a side to start StepDash on, makes sure to pick the opposite if triggered again while in Dash
	UFUNCTION() 
	void ChooseDashFoot()
	{
		if (bIsInDashABP == false)
		{
			if (Player.IsRightFootForward() == true)
			{
				DashFoot = EDashFoot::RightStepDash;
			}
			else
			{
				DashFoot = EDashFoot::LeftStepDash;
			}
		}
		else
		{
			if (DashFoot == EDashFoot::LeftStepDash)
			{
				DashFoot = EDashFoot::RightStepDash;
			}
			else
			{
				DashFoot = EDashFoot::LeftStepDash;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{

		if (Player == nullptr)
			return;

		SlowDownComponent = UPlayerFloorSlowdownComponent::Get(Player);
		StepDashComponent = UPlayerStepDashComponent::Get(Player);
		MoveComponent =  UPlayerMovementComponent::Get(Player);
		SprintComponent = UPlayerSprintComponent::Get(Player);
		ActionModeComp = UPlayerActionModeComponent::GetOrCreate(Player);

	}


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureDash NewFeature = GetFeatureAsClass(ULocomotionFeatureDash);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		//STEPDASH logic moved over here from that AnimInstance

		
		bIsInDashABP = true;

		bIsInStillFinishState = false;

		bIsInMovingFinishState = false;

		bHasReachedExitState = false;

		ExplicitStepDashFinishTimer = 0;

		//STEPDASH logic end
		
		bCameFromSprint = (GetPrevLocomotionAnimationTag() == n"Sprint");

		ClearAnimBoolParam (n"RollDashJumpWindow");

		bIsStopping = false;

		StoppingSpeed = 0;

		ChooseDashFoot();

		bUseLeftOrRightFootVariations = Feature.UseLeftOrRightFootVariations;

		bUseActionMH = Feature.bUseActionMH;

		
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.05; 
	}

	UFUNCTION(BlueprintOverride)
    float GetBlendTimeWhenResetting() const
    {
        return 0.06;
    }
	

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		//STEPDASH logic moved over here from that AnimInstance
		
		bWantsToMove = !MoveComponent.SyncedMovementInputForAnimationOnly.IsNearlyZero();

		StepDirection = StepDashComponent.StepDirection;

		if (bCalculateExplicitTime)
		{

			ExplicitStepDashFinishTimer += DeltaTime;
			
		}

		bStartStepDash = GetAnimTrigger(n"StartStepDash");

		bIsSprinting = SprintComponent.IsSprinting();

		//bIsSprinting = SprintComponent.bSprintActive;

		//STEPDASH logic end

		//Changed this to read from the local AnimInstance variable instead of from the component to ensure it could still update even if the capability was blocked while in the ABP

		//ExitType = DashComponent.ExitType; 
		//Print (""+DashComponent.ExitType,0);

		//bHoldDashInput = DashComponent.bHoldingDashInput;

		bStartRollDash = GetAnimTrigger(n"StartRollDash");

		bSlowingDown = SlowDownComponent.bInSlowDownState;

		bWantsToMove = !MoveComponent.SyncedMovementInputForAnimationOnly.IsNearlyZero();

		bIsFalling = MoveComponent.IsFalling();

		Velocity = MoveComponent.Velocity;

		Speed = Velocity.Size();

		SlopeAngle = MoveComponent.GetSlopeRotationForAnimation().Pitch;

		if (bStartRollDash)
		{
			SetAnimBoolParam(n"RequestingLocalUpperBodyOverrideAnimation", true);
		}

		if (bStartStepDash)
			{SetAnimBoolParam(n"IsinStepDash", true);}

		//For some reason this was called on update instead of just on Entered State Event. Commenting out in case deletion causes issues
		//AnimNotify_RollDashStart();

		// Check if player is stopping
		
		// bool bIsStopping;

		//if (CheckValueChangedAndSetBool(bIsStopping, bWantsToMove, EHazeCheckBooleanChangedDirection::TrueToFalse))
		if (CheckValueChangedAndSetBool(bIsStopping, SlowDownComponent.bInSlowDownState, EHazeCheckBooleanChangedDirection::FalseToTrue))
		{

			StoppingSpeed = Speed;
			
		}



		// Setting the ExitType inside the AnimInstance instead of in the component. Comment this out if you want to return to previous ExitType logic
		if (bIsFalling)
    		
			ExitType = EDashExitTypes::Falling;

		else if (LocomotionAnimationTag == n"Slide")

			ExitType = EDashExitTypes::Slide;
		
		else if (bWantsToMove)
    		
			ExitType = EDashExitTypes::Movement;

		// else if (bWantsToMove && bIsSprinting)
    		
		// 	ExitType = EDashExitTypes::Sprint;
		
		else
    		
			ExitType = EDashExitTypes::Idle;

		// GetAnimBoolParam (n"RollDashJumpWindow", bConsume = false, bDefaultValue =  false);

		//Action MH or not when going to MH
		
		if ((ActionModeComp.IsCurrentlyInActionMode && ActionModeComp.CurrentActionMode != EPlayerActionMode::BlockActionMode && bUseActionMH) || (ActionModeComp.CurrentActionMode == EPlayerActionMode::ForceActionMode && bUseActionMH))
			{
				bIsInActionMode = true;
			}
		else
				bIsInActionMode = false;

		
		// if (LowestLevelGraphRelevantStateName == "FinishFwdStillLeftFoot")
		// 	{
		// 		ActionModeComp.IncreaseActionScore(1);
				
		// 	}




	}

	

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
		SetAnimBoolParam(n"RequestingLocalUpperBodyOverrideAnimation", false);
		SetAnimBoolParam(n"IsInStepDash", false);

		SetAnimFloatParam(n"MovementBlendTime", 0.06);

		bIsInDashABP = false;

		if (GetLocomotionAnimationTag() != n"Jump")
		{
			ClearAnimBoolParam(n"RollDashJumpWindow");
		}

		if (GetLocomotionAnimationTag() == n"Movement" && Speed <= 200)
		{
			SetAnimFloatParam(n"MovementBlendTime", 0.3);
		}
		
		if (GetLocomotionAnimationTag() == n"Movement" && bIsInStillFinishState)
		{
			SetAnimBoolParam(n"ForceMovementStart", true);
			SetAnimFloatParam(n"MovementBlendTime", 0.3);
		}

		if (LocomotionAnimationTag == n"Slide")
		{
			SetAnimBoolParam(n"WasStepDash", TopLevelGraphRelevantStateName == n"StepDash");

		}

		if (bIsSprinting)
		{
			SetAnimBoolParam(n"SkipSprintStart", true);
		}

		if (LocomotionAnimationTag == n"Movement" && bIsInActionMode) // If going into movement in Action Mh so that we go straight into Action Mh and not play enter animation
		{
			SetAnimBoolParam(n"ExitedToActionMH", true);
		}

	}

	UFUNCTION()
	void AnimNotify_StepDashInitiated()
	{
		bCalculateExplicitTime = false;
		
		ExplicitStepDashFinishTimer = 0;

	}

	UFUNCTION()
	void AnimNotify_StepDashFinished()
	{
		bCalculateExplicitTime = true;

	}

	UFUNCTION()
	void AnimNotify_StepDashFinishStill()
	{
		bIsInStillFinishState = true;

		bIsInMovingFinishState = false;
	} 

	UFUNCTION()
	void AnimNotify_StepDashFinishMoving()
	{
		bIsInMovingFinishState = true;

		bIsInStillFinishState = false;
	} 

	UFUNCTION()
	void AnimNotify_CanExit()
	{

		bHasReachedExitState = true;
		ClearAnimBoolParam(n"RollDashJumpWindow");

	}

	UFUNCTION()
	void AnimNotify_RollDashTransitionAnimationState()
	{
		ClearAnimBoolParam(n"RollDashJumpWindow");
	}

    UFUNCTION()
    void AnimNotify_RollDashStart()
    {
        bIsInStillFinishState = false;

		bIsInMovingFinishState = false;


    }

    UFUNCTION()
    void AnimNotify_SwapDashFoot()
    {
        if (DashFoot == EDashFoot::LeftStepDash)
		{
			DashFoot = EDashFoot::RightStepDash;
		}
		else
		if (DashFoot == EDashFoot::RightStepDash)
		{
			DashFoot = EDashFoot::LeftStepDash;
		}


    }

}
