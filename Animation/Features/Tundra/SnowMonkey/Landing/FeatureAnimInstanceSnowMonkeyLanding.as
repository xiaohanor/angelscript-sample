UCLASS(Abstract)
class UFeatureAnimInstanceSnowMonkeyLanding : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSnowMonkeyLanding Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSnowMonkeyLandingAnimData AnimData;

	UHazeAnimSlopeAlignComponent SlopeAlignComp;
	UAnimFootTraceComponent FootTraceComp;
	UHazeMovementComponent MoveComp;
	UPlayerFloorMotionComponent FloorMoveComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "SlopeData")
	FHazeSlopeWarpingData SlopeWarpData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "SlopeData")
	FVector SlopeOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "SlopeData")
	FRotator SlopeRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "SlopeData")
	float SlopeAlignAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		SlopeAlignComp = UHazeAnimSlopeAlignComponent::GetOrCreate(HazeOwningActor);
		FootTraceComp = UAnimFootTraceComponent::GetOrCreate(HazeOwningActor);
		FootTraceComp.MoveComp = UHazeMovementComponent::Get(HazeOwningActor.AttachParentActor);
		FloorMoveComp = UPlayerFloorMotionComponent::GetOrCreate(HazeOwningActor.AttachParentActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSnowMonkeyLanding NewFeature = GetFeatureAsClass(ULocomotionFeatureSnowMonkeyLanding);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		MoveComp = UHazeMovementComponent::Get(HazeOwningActor.AttachParentActor);

		ClearAnimBoolParam (n"JumpFromLandingFwd");
	}

	UFUNCTION(BlueprintOverride)
    float GetBlendTime() const
    {
        return 0.1;
    }

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bWantsToMove = MoveComp.SyncedMovementInputForAnimationOnly != FVector::ZeroVector;

		// GetAnimBoolParam (n"JumpFromLandingFwd", bConsume = false, bDefaultValue =  false);

		SlopeAlignComp.GetSlopeTransformData(SlopeOffset, SlopeRotation, DeltaTime, 0.8);
		FootTraceComp = UAnimFootTraceComponent::GetOrCreate(HazeOwningActor);
		FootTraceComp.UpdateSlopeWarpData(SlopeWarpData);

		if (bWantsToMove)
		{
			SlopeAlignAlpha = 0.6;
		}
		else
		{
			SlopeAlignAlpha = 0.35;
		}

	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{

		if (LocomotionAnimationTag != n"Movement" && LocomotionAnimationTag != n"AirMovement")
		{
			return true;
		}

		if (LocomotionAnimationTag == n"AirMovement")
		{
			if (TopLevelGraphRelevantStateName == n"ExitToMovement")
				return TopLevelGraphRelevantAnimTimeRemaining < 0.2;
			else
				return true;
		}
		
		
		
		if (TopLevelGraphRelevantStateName == n"ExitToMH" && bWantsToMove)
		{
			return true;
		}

		return TopLevelGraphRelevantAnimTimeRemaining <= 0.1;
		//return TopLevelGraphRelevantAnimTimeRemaining <= HazeAnimation::ANIMATION_MIN_TIME;
	}


	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if(LocomotionAnimationTag == n"Movement")
		{
			if(TopLevelGraphRelevantStateName == n"ExitToMovement" && bWantsToMove)
			{
				SetAnimBoolParam(n"SkipMovementStart", true);
				SetAnimBlendTimeToMovement(HazeOwningActor, 0.2);
			}
			
		}

		if (GetLocomotionAnimationTag() != n"Jump")
		{
			ClearAnimBoolParam(n"JumpFromLandingFwd");
		}
	
	}
	
}
