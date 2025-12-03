
namespace SubTagAIRecovery
{
	const FName Rest = n"Rest";	
	const FName Duck = n"Duck";	
}

UCLASS(Abstract)
class UFeatureAnimInstanceAIRecovery : UFeatureAnimInstanceAIBase
{
	UPROPERTY()
	FName RestName = SubTagAIRecovery::Rest;	
	UPROPERTY()
	FName DuckName = SubTagAIRecovery::Duck;	

    UPROPERTY(Transient, BlueprintHidden, NotEditable)
    ULocomotionFeatureAIRecovery CurrentFeature;

    UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FLocomotionFeatureAIRecoveryData FeatureData;

    // Add Custom Variables Here

    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();

        ULocomotionFeatureAIRecovery NewFeature = GetFeatureAsClass(ULocomotionFeatureAIRecovery);
        if (CurrentFeature != NewFeature)
        {
            CurrentFeature = NewFeature;
            FeatureData = NewFeature.FeatureData;
        }
        if (CurrentFeature == nullptr)
            return;
        
        // Implement Custom Stuff Here
    }

	// Can exit at any time
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom() const
    {
	 	return true;
    }

    UFUNCTION(BlueprintOverride)
    void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
    {
		AnimComp.ClearPrioritizedFeatureTag(CurrentFeature.Tag);
    }
}