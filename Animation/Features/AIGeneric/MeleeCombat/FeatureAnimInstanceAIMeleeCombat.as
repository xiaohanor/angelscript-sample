
namespace SubTagAIMeleeCombat
{
	const FName SingleAttack = n"SingleAttack";	
	const FName DualAttack = n"DualAttack";	
	const FName FinisherAttack = n"FinisherAttack";	
	const FName ChargeAttack = n"ChargeAttack";	
	const FName HeavyAttack = n"HeavyAttack";
}

struct FAIMeleeCombatSubTags
{
	UPROPERTY()
	FName SingleAttackName = SubTagAIMeleeCombat::SingleAttack;	
	UPROPERTY()
	FName DualAttackName = SubTagAIMeleeCombat::DualAttack;	
	UPROPERTY()
	FName FinisherAttackName = SubTagAIMeleeCombat::FinisherAttack;	
	UPROPERTY()
	FName ChargeAttackName = SubTagAIMeleeCombat::ChargeAttack;	
	UPROPERTY()
	FName HeavyAttackName = SubTagAIMeleeCombat::HeavyAttack;	
}

UCLASS(Abstract)
class UFeatureAnimInstanceAIMeleeCombat : UFeatureAnimInstanceAIBase
{
	UPROPERTY()
	FAIMeleeCombatSubTags SubTags;

    UPROPERTY(Transient, BlueprintHidden, NotEditable)
    ULocomotionFeatureAIMeleeCombat CurrentFeature;

    UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FLocomotionFeatureAIMeleeCombatData FeatureData;

    // Add Custom Variables Here

	UPROPERTY()
	int ComboContinue = 0;

	UPROPERTY()
	float AnticipationTime = 0.5;

	UPROPERTY()
	float AttackTime = 0.5;

	UPROPERTY()
	float SettleTime = 0.5;

    
    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();

        ULocomotionFeatureAIMeleeCombat NewFeature = GetFeatureAsClass(ULocomotionFeatureAIMeleeCombat);
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