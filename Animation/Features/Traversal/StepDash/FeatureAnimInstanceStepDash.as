UCLASS(Abstract)
class UFeatureAnimInstanceStepDash : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureStepDash Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureStepDashAnimData AnimData;

	// Add Custom Variables Here

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	UPlayerMovementComponent MoveComponent;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	UPlayerStepDashComponent StepDashComponent;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsInStillFinishState;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsInMovingFinishState;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EStepDashDirection StepDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ExplicitStepDashFinishTimer;

	bool bCalculateExplicitTime;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureStepDash NewFeature = GetFeatureAsClass(ULocomotionFeatureStepDash);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		StepDashComponent = UPlayerStepDashComponent::Get(Player);

		MoveComponent = UPlayerMovementComponent::Get(Player);

		bIsInStillFinishState = false;

		bIsInMovingFinishState = false;

		ExplicitStepDashFinishTimer = 0;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.05;
	}
	

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		bWantsToMove = !MoveComponent.SyncedMovementInputForAnimationOnly.IsNearlyZero();

		StepDirection = StepDashComponent.StepDirection;

		if (bCalculateExplicitTime)
		{

			ExplicitStepDashFinishTimer += DeltaTime;
			
		}
		
		
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

		// If we're going into movement
		if (LocomotionAnimationTag == n"Movement") 
		{
			if (bWantsToMove) //(TopLevelGraphRelevantStateName == n"ToMovement")
			{
				SetAnimBlendTimeToMovement(Player, 0.1);
			}
			else
			{
				SetAnimBlendTimeToMovement(Player, 0.2); // If we want a custom blend time when going into Movement
			}
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
}
