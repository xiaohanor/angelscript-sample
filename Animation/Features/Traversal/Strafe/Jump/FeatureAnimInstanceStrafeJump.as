
UCLASS(Abstract)
class UFeatureAnimInstanceStrafeJump : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureStrafeJump Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureStrafeJumpAnimData AnimData;

	UPROPERTY(BlueprintReadOnly)
	FPlayerStrafeAnimData StrafeAnimData;

	UPlayerStrafeComponent StrafeComponent;

	UPlayerAirJumpComponent AirJumpComp;

	UPROPERTY()
	bool bDoubleJumped;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureStrafeJump NewFeature = GetFeatureAsClass(ULocomotionFeatureStrafeJump);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}
		if (Feature == nullptr)
			return;

		StrafeComponent = UPlayerStrafeComponent::GetOrCreate(Player);
		AirJumpComp = UPlayerAirJumpComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
    float GetBlendTime() const
    {
        return 0.0;
    }


	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		StrafeAnimData = StrafeComponent.AnimData;

		bDoubleJumped = AirJumpComp.bPerformedDoubleJump;

		
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// if(LocomotionAnimationTag != n"StrafeAir" || IsLowestLevelGraphRelevantAnimFinished())
		// {
		// 	return true;
		// }

		if(LocomotionAnimationTag != n"StrafeAir" || IsLowestLevelGraphRelevantAnimFinished())
		{
			return true;
		}
		

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}
