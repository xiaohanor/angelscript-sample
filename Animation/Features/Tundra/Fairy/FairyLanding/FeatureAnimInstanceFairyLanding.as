UCLASS(Abstract)
class UFeatureAnimInstanceFairyLanding : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureFairyLanding Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureFairyLandingAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector RootOffset;

	FVector InitialRootOffset;

	UHazeMovementComponent MoveComp;
	int TickActive;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureFairyLanding NewFeature = GetFeatureAsClass(ULocomotionFeatureFairyLanding);
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

		InitialRootOffset = GetAnimVectorParam(n"LeapRootOffset", true);
		RootOffset = InitialRootOffset;
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

		// Lerp back the InitialRootOffset over the landing animation
		if (LocomotionAnimationTag != Feature.Tag)
		{
			// RootOffset = InitialRootOffset * Math::Clamp(TopLevelGraphRelevantAnimTimeRemainingFraction, 0.0, 1.0);
			RootOffset = Math::VInterpTo(RootOffset, FVector::ZeroVector, DeltaTime, 10);
		}
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
