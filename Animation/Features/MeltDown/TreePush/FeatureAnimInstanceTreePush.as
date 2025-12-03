UCLASS(Abstract)
class UFeatureAnimInstanceTreePush : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureTreePush Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureTreePushAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTransform LeftHandIK;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTransform RightHandIK;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStruggle;

	ASplitTraversalPushableTree2 PushableTree;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureTreePush NewFeature = GetFeatureAsClass(ULocomotionFeatureTreePush);
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

		if (PushableTree == nullptr)
		{
			TListedActors<ASplitTraversalPushableTree2> ListedTrees;
			PushableTree = ListedTrees.Single;
			if (PushableTree == nullptr)
				return;
		}

		LeftHandIK = PushableTree.FantasytHandIKLeft.WorldTransform;
		RightHandIK = PushableTree.FantasyHandIKRight.WorldTransform;

		bStruggle = PushableTree.bPushing;
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
}
