UCLASS(Abstract)
class UFeatureAnimInstanceTailTeenHitWall : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureTailTeenHitWall Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureTailTeenHitWallAnimData AnimData;

	// Add Custom Variables Here


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		// Get components here...
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureTailTeenHitWall NewFeature = GetFeatureAsClass(ULocomotionFeatureTailTeenHitWall);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.05;
	}
	

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here
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
}
