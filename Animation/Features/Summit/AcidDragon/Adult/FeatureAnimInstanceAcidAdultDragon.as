UCLASS(Abstract)
class UFeatureAnimInstanceAcidAdultDragon : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureAcidAdultDragon Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureAcidAdultDragonAnimData AnimData;

	UPROPERTY(BlueprintReadOnly)
	float FlyingTurnAmount = 0.0;

	UPROPERTY(BlueprintReadOnly)
	float FlyingForwardAmount = 0.0;

	UPROPERTY(BlueprintReadOnly)
	EAdultDragonAnimationState AnimationState;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	protected AAdultDragon AdultDragon;

	UPlayerAcidAdultDragonComponent DragonComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureAcidAdultDragon NewFeature = GetFeatureAsClass(ULocomotionFeatureAcidAdultDragon);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		AdultDragon = Cast<AAdultDragon>(HazeOwningActor);
		DragonComp = Cast<UPlayerAcidAdultDragonComponent>(AdultDragon.DragonComponent);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		AnimationState = DragonComp.AnimationState.Get();
		FlyingTurnAmount = DragonComp.AnimParams.AnimationFlyingTurnAmount;
		FlyingForwardAmount = DragonComp.AnimParams.AnimationFlyingForwardAmount;
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
