UCLASS(Abstract)
class UFeatureAnimInstanceSnowMonkeyLedgeGrab : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSnowMonkeyLedgeGrab Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSnowMonkeyLedgeGrabAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FSnowMonkeyLedgeGrabAnimationData SnowMonkeyLedgeAnimData;

	USnowMonkeyLedgeGrabComponent LedgeGrabComp;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSnowMonkeyLedgeGrab NewFeature = GetFeatureAsClass(ULocomotionFeatureSnowMonkeyLedgeGrab);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		LedgeGrabComp = USnowMonkeyLedgeGrabComponent::Get(HazeOwningActor.AttachParentActor);

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		SnowMonkeyLedgeAnimData = LedgeGrabComp.AnimData;
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
