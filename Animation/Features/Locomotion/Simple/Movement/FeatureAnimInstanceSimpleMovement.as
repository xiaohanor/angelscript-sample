UCLASS()
class UFeatureAnimInstanceSimpleMovement : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSimpleMovement Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSimpleMovementAnimData AnimData;


	UHazeMovementComponent MoveComp;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;
 
    // Speed 
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	float StoppingSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	float Banking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayGesture;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSkipStart;


	FQuat CachedActorRotation;
	FTimerHandle GestureTimer;
	


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSimpleMovement NewFeature = GetFeatureAsClass(ULocomotionFeatureSimpleMovement);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		MoveComp = UHazeMovementComponent::Get(HazeOwningActor);
		// Added this here for shapeshifting, since each shape is a seperate actor that is attached the the player
		if(MoveComp == nullptr)
			MoveComp = UHazeMovementComponent::Get(HazeOwningActor.AttachParentActor);

		CachedActorRotation = HazeOwningActor.ActorQuat;

		bSkipStart = GetAnimBoolParam(n"SkipMovementStart", true);
	}


	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return GetAnimFloatParam(n"MovementBlendTime", true, 0.2f);
	}
	

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;
		
		Speed = MoveComp.Velocity.Size();
		if (CheckValueChangedAndSetBool(bWantsToMove, !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero()))
		{
			if (!bWantsToMove)
			{
				// Called when user let's go of the stick
				StoppingSpeed = Speed;
			}
		}
		
		// Banking
		Banking = CalculateAnimationBankingValue(HazeOwningActor, CachedActorRotation, DeltaTime, Feature.MaxTurnSpeed);
		
	}


	UFUNCTION()
    void AnimNotify_EnteredMh()
    {
		// Make sure the feature has some gestures
		if (AnimData.Gestures.GetNumAnimations() == 0)
			return;
		
		const float GestureTime = Math::RandRange(Feature.GestureTimeRange.X, Feature.GestureTimeRange.Y);
		GestureTimer = Timer::SetTimer(this, n"PlayGesture", GestureTime);
    }


    UFUNCTION()
    void AnimNotify_LeftMh()
    {
		bSkipStart = false;
        bPlayGesture = false;
		GestureTimer.ClearTimer();
    }


	UFUNCTION()
	void PlayGesture()
	{
		bPlayGesture = true;
	}
}
