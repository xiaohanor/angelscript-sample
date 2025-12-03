UCLASS(Abstract)
class UFeatureAnimInstanceSpaceTouchScreen : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSpaceTouchScreen Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSpaceTouchScreenAnimData AnimData;

	// Add Custom Variables Here
	bool bInExitState = false;

	//Is set on initialize to determine if the player is in the ZeroG part of the level or not
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsGrounded;

	//Is set for a frame when the player makes a selection to the left. Can trigger again on continuous left-selects to be used to interrupt the animation
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStepLeft;

	//Is set for a frame when the player makes a selection to the right. Can trigger again on continuous right-selects to be used to interrupt the animation
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStepRight;

	//Is set for a frame when the player confirms a selection. Can trigger again on continuous confirms to be used to interrupt the animation
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bConfirmSelection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCancelInteract = false;

	USpaceWalkOxygenPlayerComponent OxygenComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		OxygenComp = USpaceWalkOxygenPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSpaceTouchScreen NewFeature = GetFeatureAsClass(ULocomotionFeatureSpaceTouchScreen);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here
	}

	/*UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.2f;
	}
	*/

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bCancelInteract = (LocomotionAnimationTag != n"SpaceTouchScreen");

		bIsGrounded = OxygenComp.bTouchScreenGrounded;
		bStepLeft = OxygenComp.AnimTouchScreenStepLeft.IsSetThisFrame();
		bStepRight = OxygenComp.AnimTouchScreenStepRight.IsSetThisFrame();
		bConfirmSelection = OxygenComp.AnimTouchScreenConfirm.IsSetThisFrame();

	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here

		if ((LowestLevelGraphRelevantStateName == n"ZeroGExit" || LowestLevelGraphRelevantStateName == n"GroundedExit") && IsLowestLevelGraphRelevantAnimFinished())
		{
			return true;
		}

		if (bInExitState)
		{
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
	}
    UFUNCTION()
    void AnimNotify_ExitState()
    {
        bInExitState = true;
    }

}
