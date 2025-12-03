UCLASS(Abstract)
class UFeatureAnimInstanceWaveRaft : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureWaveRaft Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureWaveRaftAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float LeanAlpha = 0.0;

	UPROPERTY()
	EWaveRaftPaddleBreakDirection BreakState;

	UPROPERTY()
	float StartPaddleTime;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ERaftPaddleAnimationState AnimationState;

	UWaveRaftPlayerComponent WaveRaftComp;
	USummitRaftPaddleComponent PaddleComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureWaveRaft NewFeature = GetFeatureAsClass(ULocomotionFeatureWaveRaft);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		WaveRaftComp = UWaveRaftPlayerComponent::Get(Player);
		PaddleComp = USummitRaftPaddleComponent::Get(Player);

		StartPaddleTime = 0;
	}

	/*UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.2;
	}
	*/

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		LeanAlpha = WaveRaftComp.PlayerLean;

		BreakState = WaveRaftComp.BreakState;
		AnimationState = PaddleComp.AnimationState.Get();
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
	}
    UFUNCTION()
    void AnimNotify_EnterPaddle()
    {
        StartPaddleTime = 0;
    }

    UFUNCTION()
    void AnimNotify_PaddleSwitchSide()
    {
        StartPaddleTime = 0.13;
    }

}
