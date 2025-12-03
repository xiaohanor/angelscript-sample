UCLASS(Abstract)
class UFeatureAnimInstanceEnforcerJetpackLeap : UFeatureAnimInstanceAIBase
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureAIEnforcerJetpackLeap Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureAIEnforcerJetpackLeapAnimData AnimData;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
		ULocomotionFeatureAIEnforcerJetpackLeap NewFeature = GetFeatureAsClass(ULocomotionFeatureAIEnforcerJetpackLeap);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;
	}
}