

class UFeatureAnimInstanceWallRun : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureWallRun Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureWallRunAnimData AnimData;

	UPlayerWallRunComponent WallRunComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	FPlayerWallRunAnimationData WallRunAnimData;

	UPROPERTY()
	bool bCameFromGrapple = false;


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureWallRun NewFeature = GetFeatureAsClass(ULocomotionFeatureWallRun);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		WallRunComp = UPlayerWallRunComponent::GetOrCreate(Player);

		bCameFromGrapple = PrevLocomotionAnimationTag == n"Grapple";
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

		WallRunAnimData = WallRunComp.AnimData;
	}


	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LowestLevelGraphRelevantStateName == "Jump" && LocomotionAnimationTag == "AirMovement" && (LowestLevelGraphRelevantAnimTime <= 1.1))
			return false;

		return true;
	}


	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{

	}

	
}