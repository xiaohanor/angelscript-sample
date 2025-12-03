UCLASS(Abstract)
class UFeatureAnimInstancePaddleRaftFalling : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeaturePaddleRaftFalling Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeaturePaddleRaftFallingAnimData AnimData;

	// Add Custom Variables Here

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ERaftPaddleAnimationState AnimationState;

	private USummitRaftPaddleComponent PaddleComp;
	UWaveRaftPlayerComponent WaveRaftComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bRaftIsFalling;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
		// Get components here...
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeaturePaddleRaftFalling NewFeature = GetFeatureAsClass(ULocomotionFeaturePaddleRaftFalling);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		PaddleComp = USummitRaftPaddleComponent::Get(Player);
		WaveRaftComp = UWaveRaftPlayerComponent::Get(Player);
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

		// Implement Custom Stuff Here
		if (WaveRaftComp.WaveRaft == nullptr)
			return;

		bRaftIsFalling = WaveRaftComp.WaveRaft.IsFalling();
		AnimationState = PaddleComp.AnimationState.Get();
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag != n"Waveraft")
		{
			return true;
		}

		return LowestLevelGraphRelevantStateName == n"Land" && IsLowestLevelGraphRelevantAnimFinished();
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
	}
}
