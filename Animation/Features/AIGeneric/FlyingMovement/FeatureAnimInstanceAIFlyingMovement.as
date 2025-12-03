
UCLASS(Abstract)
class UFeatureAnimInstanceAIFlyingMovement : UFeatureAnimInstanceAIBase
{
    UPROPERTY(Transient, BlueprintHidden, NotEditable)
    ULocomotionFeatureAIFlyingMovement CurrentFeature;

    UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FLocomotionFeatureAIFlyingMovementData FeatureData;

    // Add Custom Variables Here
    
    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();

        ULocomotionFeatureAIFlyingMovement NewFeature = GetFeatureAsClass(ULocomotionFeatureAIFlyingMovement);
        if (CurrentFeature != NewFeature)
        {
            CurrentFeature = NewFeature;
           	FeatureData = NewFeature.FeatureData;
        }
        if (CurrentFeature == nullptr)
            return;
        
        // Implement Custom Stuff Here
        
    }
    
    // Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom() const
    {
        return true;
    }
    
    // On Transition From
    UFUNCTION(BlueprintOverride)
    void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
    {
		AnimComp.ClearPrioritizedFeatureTag(CurrentFeature.Tag);
    }

}