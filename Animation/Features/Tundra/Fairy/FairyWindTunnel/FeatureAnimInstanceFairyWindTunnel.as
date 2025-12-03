UCLASS(Abstract)
class UFeatureAnimInstanceFairyWindTunnel : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureFairyWindTunnel Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureFairyWindTunnelAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayExit;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureFairyWindTunnel NewFeature = GetFeatureAsClass(ULocomotionFeatureFairyWindTunnel);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;
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

		bPlayExit = LocomotionAnimationTag != Feature.Tag;



	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag != n"AirMovement")
			return true;
		return IsTopLevelGraphRelevantAnimFinished() && TopLevelGraphRelevantStateName == n"Exit";
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}
