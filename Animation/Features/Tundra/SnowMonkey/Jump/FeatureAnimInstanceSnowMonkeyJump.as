UCLASS(Abstract)
class UFeatureAnimInstanceSnowMonkeyJump : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSnowMonkeyJump Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSnowMonkeyJumpAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float CurrentMoveSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJumpFromLandingFwd;

	AHazePlayerCharacter PlayerRef;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		PlayerRef = Cast<AHazePlayerCharacter>(HazeOwningActor.AttachParentActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSnowMonkeyJump NewFeature = GetFeatureAsClass(ULocomotionFeatureSnowMonkeyJump);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		if (GetPrevLocomotionAnimationTag() == n"Landing") 
		{
			bJumpFromLandingFwd = GetAnimBoolParam (n"JumpFromLandingFwd", bConsume = true, bDefaultValue =  false);
		}
		else
		{
			ClearAnimBoolParam (n"JumpFromLandingFwd");
			bJumpFromLandingFwd = false;
		}
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

		CurrentMoveSpeed = PlayerRef.GetActorLocalVelocity().Size2D();

	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag != n"AirMovement")
		{
			return true;
		}

		return TopLevelGraphRelevantAnimTimeRemaining <= HazeAnimation::ANIMATION_MIN_TIME;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}
