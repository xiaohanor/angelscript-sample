UCLASS(Abstract)
class UFeatureAnimInstanceControlledBabyDragonMovement : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureControlledBabyDragonMovement Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureControlledBabyDragonMovementAnimData AnimData;

	UPROPERTY(BlueprintReadOnly)
	float MovementSpeedAlpha = 0;

	UPROPERTY(BlueprintReadOnly)
	float CurrentMovementSpeed = 0;

	UPlayerMovementComponent MoveComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSkipStart;

	FTimerHandle GestureTimer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayGesture;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureControlledBabyDragonMovement NewFeature = GetFeatureAsClass(ULocomotionFeatureControlledBabyDragonMovement);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		MoveComp = UPlayerMovementComponent::Get(Player);
		bWantsToMove = MoveComp.SyncedMovementInputForAnimationOnly != FVector::ZeroVector;
		bSkipStart = GetAnimBoolParam(n"SkipMovementStart", true) || (PrevLocomotionAnimationTag == n"Sprint" && bWantsToMove );


	}

	UFUNCTION(BlueprintOverride)
    float GetBlendTime() const
    {
        return GetAnimFloatParam(n"MovementBlendTime", true, 0.2);
    }


	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;
		
		CurrentMovementSpeed = Player.GetActorVelocity().Size();
		FVector TargetDirection = MoveComp.MovementInput;
		float InputSize = MoveComp.MovementInput.Size();
		MovementSpeedAlpha = Math::Clamp((InputSize - ControlledBabyDragon::MinimumInput) / (1.0 - AdultDragonMovement::MinimumInput), 0.0, 1.0);

		bWantsToMove = MoveComp.SyncedMovementInputForAnimationOnly != FVector::ZeroVector;
		
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
    UFUNCTION()
    void AnimNotify_EnteredMovement()
    {
        bSkipStart = false;
    }

    UFUNCTION()
    void AnimNotify_EnteredMh()
    {
		const float GestureTime = Math::RandRange(Feature.GestureTime.X, Feature.GestureTime.Y);
        GestureTimer = Timer::SetTimer(this, n"PlayGesture", GestureTime);
    }

    UFUNCTION()
    void AnimNotify_LeftMh()
    {
        bPlayGesture = false;
		GestureTimer.ClearTimer();
    }

	UFUNCTION()
	void PlayGesture()
	{
		bPlayGesture = true;
	}

}