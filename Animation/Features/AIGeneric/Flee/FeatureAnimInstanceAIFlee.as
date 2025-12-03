
namespace SubTagAIFlee
{
	const FName StartFleeing = n"StartFleeing";	
}

struct FAIFleeSubTags
{
	UPROPERTY()
	FName StartFleeingName = SubTagAIFlee::StartFleeing;	
}

UCLASS(Abstract)
class UFeatureAnimInstanceAIFlee : UFeatureAnimInstanceAIBase
{
    UPROPERTY(Transient, BlueprintHidden, NotEditable)
    ULocomotionFeatureAIFlee CurrentFeature;

    UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FLocomotionFeatureAIFleeData FeatureData;

	UPROPERTY()
	FAIFleeSubTags SubTags;

    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();

        ULocomotionFeatureAIFlee NewFeature = GetFeatureAsClass(ULocomotionFeatureAIFlee);
        if (CurrentFeature != NewFeature)
        {
            CurrentFeature = NewFeature;
            FeatureData = NewFeature.FeatureData;
        }
        if (CurrentFeature == nullptr)
            return;
        
        // Implement Custom Stuff Here
    }

    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom() const
    {
		return true;
    }
}