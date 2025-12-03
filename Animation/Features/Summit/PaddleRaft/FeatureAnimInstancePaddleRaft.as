UCLASS(Abstract)
class UFeatureAnimInstancePaddleRaft : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeaturePaddleRaft Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeaturePaddleRaftAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ERaftPaddleAnimationState AnimationState;

	UPROPERTY()
	float StartPaddleTime;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPaddleFlipFlop;

	private USummitRaftPaddleComponent PaddleComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeaturePaddleRaft NewFeature = GetFeatureAsClass(ULocomotionFeaturePaddleRaft);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		PaddleComp = USummitRaftPaddleComponent::Get(Player);

		StartPaddleTime = 0;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		const auto NewAnimState = PaddleComp.AnimationState.Get();
		if (AnimationState != NewAnimState && (NewAnimState == ERaftPaddleAnimationState::LeftSidePaddle || NewAnimState == ERaftPaddleAnimationState::RightSidePaddle))
			bPaddleFlipFlop = !bPaddleFlipFlop;

		AnimationState = NewAnimState;
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
	void AnimNotify_PaddleSwitchSide()
	{
		StartPaddleTime = 0.16;
	}

	UFUNCTION()
	void AnimNotify_EnterPaddle()
	{
		StartPaddleTime = 0;
	}
}
