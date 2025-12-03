
UCLASS(Abstract)
class UFeatureAnimInstanceAIStrafeMovement : UFeatureAnimInstanceAIBase
{
    UPROPERTY(Transient, BlueprintHidden, NotEditable)
    ULocomotionFeatureAIStrafeMovement CurrentFeature;

    UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FLocomotionFeatureAIStrafeMovementData FeatureData;

	UPROPERTY()
    FVector Speed;

	UPROPERTY()
    bool bWasAlreadyMoving;

    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();

        ULocomotionFeatureAIStrafeMovement NewFeature = GetFeatureAsClass(ULocomotionFeatureAIStrafeMovement);
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
	void BlueprintUpdateAnimation(float DeltaTime)
    {
        if (CurrentFeature == nullptr)
            return;
        
        bWasAlreadyMoving = (HazeOwningActor.GetRawLastFrameTranslationVelocity().Size() >= 50.0);
        Print("bWasAlreadyMoving: " + bWasAlreadyMoving, 0.f);
        Super::BlueprintUpdateAnimation(DeltaTime);
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