
namespace SubTagAIShooting
{
	const FName SingleShot = n"SingleShot";	
	const FName Reload = n"Reload";	
}

UCLASS(Abstract)
class UFeatureAnimInstanceAIShooting : UFeatureAnimInstanceAIBase
{
	UPROPERTY()
	FName SingleShotName = SubTagAIShooting::SingleShot;	
	UPROPERTY()
	FName ReloadName = SubTagAIShooting::Reload;	

    UPROPERTY(Transient, BlueprintHidden, NotEditable)
    ULocomotionFeatureAIShooting CurrentFeature;

    UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FLocomotionFeatureAIShootingData FeatureData;

    // Add Custom Variables Here
    
    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();

        ULocomotionFeatureAIShooting NewFeature = GetFeatureAsClass(ULocomotionFeatureAIShooting);
        if (CurrentFeature != NewFeature)
        {
            CurrentFeature = NewFeature;
            FeatureData = NewFeature.FeatureData;
        }
        if (CurrentFeature == nullptr)
            return;
        
        // Implement Custom Stuff Here
        
    }

   
    // For AI controlled ABPs which are "fire-and-forget", i.e. you request the tag one frame and 
	// then do not have to keep requesting them, you should:
	// - Make sure all animation states terminate in a state with the 'Finished' state name
	// - Have the below CanTransitionFrom and OnTransitionFrom functions
	// This allow the AI to stop the ABP by requesting a higher prio feature and let's it know when 
	// the ABP has finished normally.
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom() const
    {
		// Always allow exit when done
		if (GetTopLevelGraphRelevantStateName() == FinishedStateName)
			return true;

		// Check if some other feature has stolen prio
		if (!AnimComp.HasPriority(CurrentFeature.Tag))
		 	return true;

		// Still ongoing, will not exit until done or something else takes prio
		return false;
    }
    
    // See comment for CanTransition from above
    UFUNCTION(BlueprintOverride)
    void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
    {
		AnimComp.ClearPrioritizedFeatureTag(CurrentFeature.Tag);
    }
}