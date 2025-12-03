UCLASS(Abstract)
class UFeatureAnimInstancePaddleRaftHitReaction : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeaturePaddleRaftHitReaction Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeaturePaddleRaftHitReactionAnimData AnimData;

	// Add Custom Variables Here

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ERaftPaddleAnimationState AnimationState;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FSummitRaftHitStaggerData StaggerData;

	private USummitRaftPlayerStaggerComponent StaggerComp;
	private USummitRaftPaddleComponent PaddleComp;

	TArray<FName> HitReactionStateNames;
	default HitReactionStateNames.Add(n"Left");
	default HitReactionStateNames.Add(n"Right");

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		StaggerComp = USummitRaftPlayerStaggerComponent::Get(Player);
		PaddleComp = USummitRaftPaddleComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeaturePaddleRaftHitReaction NewFeature = GetFeatureAsClass(ULocomotionFeaturePaddleRaftHitReaction);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		if (StaggerComp.StaggerData.IsSet())
			StaggerData = StaggerComp.StaggerData.Value;

		AnimationState = PaddleComp.AnimationState.Get();
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag != n"Waveraft")
		{
			return true;
		}

		//DB change: toplevelgraphrelevantstatename is either LeftMh or RightMh, so lowestgraphrelevantname is left or right when we can exit
		return HitReactionStateNames.Contains(LowestLevelGraphRelevantStateName) && IsLowestLevelGraphRelevantAnimFinished();
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
	}
}
