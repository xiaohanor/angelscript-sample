UCLASS(Abstract)
class UFeatureAnimInstanceMioAirDive : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureMioAirDive Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureMioAirDiveAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EAcidBabyDragonAnimationState BabyDragonState = EAcidBabyDragonAnimationState::Idle;

	private UPlayerAcidBabyDragonComponent DragonComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureMioAirDive NewFeature = GetFeatureAsClass(ULocomotionFeatureMioAirDive);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		DragonComp = UPlayerAcidBabyDragonComponent::Get(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		BabyDragonState = DragonComp.AnimationState.Get();
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
