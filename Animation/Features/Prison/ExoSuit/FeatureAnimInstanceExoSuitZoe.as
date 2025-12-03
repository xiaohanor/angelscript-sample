UCLASS(Abstract)
class UFeatureAnimInstanceExoSuitZoe : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureExoSuitZoe Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureExoSuitZoeAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	UMagneticFieldPlayerComponent PlayerComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EMagneticFieldChargeState ChargeState;

	/**
	 * AnimationLocomotionTags that should allow the arms to be overridden.
	 * The tags are set under `Class Defaults` in the ABP.
	 */
	UPROPERTY(BlueprintReadOnly)
	TArray<FName> OverrideArmsAnimationTags;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureExoSuitZoe NewFeature = GetFeatureAsClass(ULocomotionFeatureExoSuitZoe);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		PlayerComp = UMagneticFieldPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		ChargeState = PlayerComp.GetChargeState();
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
