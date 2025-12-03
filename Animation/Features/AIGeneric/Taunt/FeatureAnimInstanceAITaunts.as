
namespace SubTagAITaunts
{
	const FName SpotTarget = n"SpotTarget";	
	const FName Telegraph = n"Telegraph";	
	const FName Tracking = n"Tracking";
}

UCLASS(Abstract)
class UFeatureAnimInstanceAITaunts : UFeatureAnimInstanceAIBase
{
	UPROPERTY()
	FName InitialTauntName = SubTagAITaunts::SpotTarget;	
	UPROPERTY()
	FName Tracking = SubTagAITaunts::Tracking;	
	UPROPERTY()
	FName TelegraphName = SubTagAITaunts::Telegraph;	

    UPROPERTY(Transient, BlueprintHidden, NotEditable)
    ULocomotionFeatureAITaunts CurrentFeature;

    UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FLocomotionFeatureAITauntsData FeatureData;

    // Add Custom Variables Here

    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();

        ULocomotionFeatureAITaunts NewFeature = GetFeatureAsClass(ULocomotionFeatureAITaunts);
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