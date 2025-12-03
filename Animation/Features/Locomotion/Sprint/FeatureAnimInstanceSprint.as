UCLASS(Abstract)
class UFeatureAnimInstanceSprint : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSprint Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSprintAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	FHazeSlopeWarpingData SlopeWarpData;

	UPlayerMovementComponent MovementComponent;
	UAnimFootTraceComponent FootTraceComp;
	UPlayerSprintComponent SprintComponent;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendSpaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector Velocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	// TODO: (ns) - Unused variable
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	float SpeedWhenStopping;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSkipStart;

	// TODO: (ns) - Unused variable
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsAccelerating;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsSprintToggledOffWhileMoving;

	bool bCameFromDash;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		FootTraceComp = UAnimFootTraceComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSprint NewFeature = GetFeatureAsClass(ULocomotionFeatureSprint);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Get components
		MovementComponent =  UPlayerMovementComponent::Get(Player);
		SprintComponent = UPlayerSprintComponent::Get(Player);
		
		bCameFromDash = (GetPrevLocomotionAnimationTag() == n"Dash");
		bSkipStart = bCameFromDash || GetPrevLocomotionAnimationTag() == n"Landing" || GetPrevLocomotionAnimationTag() == n"Slide" || GetPrevLocomotionAnimationTag() == n"Dash";
	}


	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		if (bSkipStart)
			return 0;
		
		return 0.2;
	}

		

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;
		
		bIsAccelerating =  (Velocity.Size() < Speed);
		Velocity = MovementComponent.HorizontalVelocity;
		Speed = Velocity.Size();

		bIsSprintToggledOffWhileMoving = SprintComponent.bSprintToggledOffWhileMoving;

		BlendSpaceValues.X = Math::Clamp(MovementComponent.GetMovementYawVelocity(bRelativeToFloor = true) / 515, -1.0, 1.0);
		BlendSpaceValues.Y = (Speed / SprintComponent.Settings.MaximumSpeed) - 1;

		// Update bWantsToMove & get a callback when it turns false
		if (CheckValueChangedAndSetBool(bWantsToMove, !MovementComponent.SyncedMovementInputForAnimationOnly.IsNearlyZero(), EHazeCheckBooleanChangedDirection::TrueToFalse))
		{
			SpeedWhenStopping = Speed;
		}
		
		if (bWantsToMove)
			FootTraceComp.UpdateSlopeWarpData(SlopeWarpData);
		
	}


	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// If any other tag then movement is called. leave the ABP
		if (LocomotionAnimationTag != n"Movement")
			return true;

		// TODO: Replace this TempFloat check with an AnimBoolParam, when Jonas has submitted a fix so AnimParams can be consumed in const functions.
		float TempFloat = 1 - (TopLevelGraphRelevantAnimTimeRemaining / AnimData.SlowdownStopLeft.Sequence.SequenceLength);
		if (TopLevelGraphRelevantStateName == n"Stop" && !MovementComponent.SyncedMovementInputForAnimationOnly.IsNearlyZero() && TempFloat > 0.25)
		 	return true;
		

		// If we're in the 'DecelerateToJog' or 'AccelerateToJog' state, and no longer wants to move, leave ABP
		if ((TopLevelGraphRelevantStateName == n"DecelerateToJog" || TopLevelGraphRelevantStateName == n"AccelerateToJog") && !bWantsToMove)
			return true;

		// Finish playing the current animation before leaving
		return TopLevelGraphRelevantAnimTimeRemaining <= SMALL_NUMBER;
	}

	UFUNCTION(BlueprintOverride)
    void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
    {
		if (LocomotionAnimationTag == n"Movement")
			SetAnimBlendTimeToMovement(Player, 0.0);
    }


	


}
