UCLASS(Abstract)
class UFeatureAnimInstanceEnforcerMinimalHitReaction : UFeatureAnimInstanceAIBase
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureEnforcerMinimalHitReaction Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureEnforcerMinimalHitReactionAnimData AnimData;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
		ULocomotionFeatureEnforcerMinimalHitReaction NewFeature = GetFeatureAsClass(ULocomotionFeatureEnforcerMinimalHitReaction);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;
	}

	}