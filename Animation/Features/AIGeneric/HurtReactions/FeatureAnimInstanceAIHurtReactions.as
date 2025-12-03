
namespace SubTagAIHurtReactions
{
	const FName Default = n"HurtReactionDefault";	
	const FName Knockdown = n"Knockdown";
    
    const FName Knockback = n"Knockback";
    const FName KnockbackFlypose = n"KnockbackFlypose";
    const FName KnockbackRecover = n"KnockbackRecover";
    const FName KnockbackWallHitRecover = n"KnockbackWallHitRecover";
    const FName KnockbackWallHitDeath = n"KnockbackWallHitDeath";
}

UCLASS(Abstract)
class UFeatureAnimInstanceAIHurtReactions : UFeatureAnimInstanceAIBase
{
	UPROPERTY()
	FName HurtReactionsTag = LocomotionFeatureAITags::HurtReactions;

	UPROPERTY()
	FName DefaultName = SubTagAIHurtReactions::Default;	

   
   
    UPROPERTY()
	FName KnockbackTag = SubTagAIHurtReactions::Knockback;

    UPROPERTY()
	FName KnockbackFlyposeTag = SubTagAIHurtReactions::KnockbackFlypose;

    UPROPERTY()
	FName KnockbackRecoverTag = SubTagAIHurtReactions::KnockbackRecover;			

    UPROPERTY()
	FName KnockbackWallHitRecoverTag = SubTagAIHurtReactions::KnockbackWallHitRecover;	

    UPROPERTY()
	FName KnockbackWallHitDeathTag = SubTagAIHurtReactions::KnockbackWallHitDeath;

    	


	UPROPERTY()
	FName KnockdownName = SubTagAIHurtReactions::Knockdown;

    UPROPERTY(Transient, BlueprintHidden, NotEditable)
    ULocomotionFeatureAIHurtReactions CurrentFeature;

    UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FLocomotionFeatureAIHurtReactionsData FeatureData;

    // Add Custom Variables Here

    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();

        ULocomotionFeatureAIHurtReactions NewFeature = GetFeatureAsClass(ULocomotionFeatureAIHurtReactions);
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