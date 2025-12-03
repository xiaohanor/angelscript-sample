UCLASS(Abstract)
class UFeatureAnimInstanceNotGravityWhippable : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureNotGravityWhippable Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureNotGravityWhippableAnimData AnimData;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayExit;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureNotGravityWhippable NewFeature = GetFeatureAsClass(ULocomotionFeatureNotGravityWhippable);
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
		bPlayExit = LocomotionAnimationTag != Feature.Tag;
	
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return TopLevelGraphRelevantAnimTimeRemaining <= 0.1;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}
