
UCLASS(Abstract)
class ULedgeGrabAnimInstance : UHazeFeatureSubAnimInstance
{
    UPROPERTY(BlueprintHidden)
    ULocomotionFeatureLedgeGrab Feature;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureLedgeGrabAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FPlayerLedgeGrabAnimationData LedgeGrabAnimData;

	UPlayerLedgeGrabComponent LedgeGrabComp;

	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureLedgeGrab NewFeature = GetFeatureAsClass(ULocomotionFeatureLedgeGrab);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		LedgeGrabComp = UPlayerLedgeGrabComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (LedgeGrabComp == nullptr)
			return;

		LedgeGrabAnimData = LedgeGrabComp.AnimData;

	}
}