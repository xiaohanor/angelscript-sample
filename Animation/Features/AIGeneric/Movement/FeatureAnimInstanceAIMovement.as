
UCLASS(Abstract)
class UFeatureAnimInstanceAIMovement : UFeatureAnimInstanceAIBase
{
    UPROPERTY(Transient, BlueprintHidden, NotEditable)
    ULocomotionFeatureAIMovement CurrentFeature;

    UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FLocomotionFeatureAIMovementData FeatureData;

    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();

        ULocomotionFeatureAIMovement NewFeature = GetFeatureAsClass(ULocomotionFeatureAIMovement);
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