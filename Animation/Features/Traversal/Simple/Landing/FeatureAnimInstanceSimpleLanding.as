UCLASS(Abstract)
class UFeatureAnimInstanceSimpleLanding : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSimpleLanding Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSimpleLandingAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSimpleLanding NewFeature = GetFeatureAsClass(ULocomotionFeatureSimpleLanding);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		MoveComp = UHazeMovementComponent::Get(HazeOwningActor);
		// Added this here for shapeshifting, since each shape is a seperate actor that is attached the the player (only fairy seems to use this atm)
		if(MoveComp == nullptr)
			MoveComp = UHazeMovementComponent::Get(HazeOwningActor.AttachParentActor);
	}

	UFUNCTION(BlueprintOverride)
    float GetBlendTime() const
    {
        return 0;
    }


	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bWantsToMove = MoveComp.SyncedMovementInputForAnimationOnly != FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{

		if (LocomotionAnimationTag != n"Movement")
		{
			return true;
		}

		if (TopLevelGraphRelevantStateName == n"ExitToMovement" && !bWantsToMove)
		{
			return true;
		}
		
		if (TopLevelGraphRelevantStateName == n"ExitToMm" && bWantsToMove)
		{
			return true;
		}

		return TopLevelGraphRelevantAnimTimeRemaining <= HazeAnimation::ANIMATION_MIN_TIME;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if(LocomotionAnimationTag == n"Movement")
		{
			if(TopLevelGraphRelevantStateName == n"ExitToMovement" && bWantsToMove)
			{
				SetAnimBoolParam(n"SkipMovementStart", true);
				SetAnimBlendTimeToMovement(HazeOwningActor, 0);
			}
			
		}
	
	}
}
