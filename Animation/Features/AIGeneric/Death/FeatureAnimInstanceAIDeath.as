
namespace SubTagAIDeath
{
	const FName Default = n"DeathDefault";	
    const FName DeathKnockback = n"DeathKnockback";	
    const FName DeathLeft = n"DeathLeft";	
    const FName DeathPushback = n"DeathPushback";	
    const FName DeathSlipback = n"DeathSlipback";	
    const FName DeathTwistRight = n"DeathTwistRight";	
    const FName DeathTwistLeft = n"DeathTwistLeft";	
    const FName DeathFlungBack = n"DeathFlungBack";	
    const FName DeathAirEnter = n"DeathAirEnter";	
    const FName DeathAirMh = n"DeathAirMh";	
    const FName DeathAirEnd = n"DeathAirEnd";	
    



}

UCLASS(Abstract)
class UFeatureAnimInstanceAIDeath : UFeatureAnimInstanceAIBase
{
	UPROPERTY()
	FName DefaultName = SubTagAIDeath::Default;	

    UPROPERTY()
	FName DeathKnockbackTag = SubTagAIDeath::DeathKnockback;

    UPROPERTY()
	FName DeathLeftTag = SubTagAIDeath::DeathLeft;	

    UPROPERTY()
	FName DeathPushbackTag = SubTagAIDeath::DeathPushback;	

    UPROPERTY()
	FName DeathSlipbackTag = SubTagAIDeath::DeathSlipback;	

    UPROPERTY()
	FName DeathTwistRightTag = SubTagAIDeath::DeathTwistRight;	

     UPROPERTY()
	FName DeathTwistLeftTag = SubTagAIDeath::DeathTwistLeft;	

     UPROPERTY()
	FName DeathFlungBackTag = SubTagAIDeath::DeathFlungBack;

    UPROPERTY()
	FName DeathAirEnterTag = SubTagAIDeath::DeathAirEnter;

    UPROPERTY()
	FName DeathAirMhTag = SubTagAIDeath::DeathAirMh;

    UPROPERTY()
	FName DeathAirEndTag = SubTagAIDeath::DeathAirEnd;





    UPROPERTY(Transient, BlueprintHidden, NotEditable)
    ULocomotionFeatureAIDeath CurrentFeature;

    UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FLocomotionFeatureAIDeathData FeatureData;

    // Add Custom Variables Here
    UPROPERTY()   
    bool bInAir;





    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();

        ULocomotionFeatureAIDeath NewFeature = GetFeatureAsClass(ULocomotionFeatureAIDeath);
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
        Super::BlueprintUpdateAnimation(DeltaTime);

        if (CurrentFeature == nullptr)
                    return;
    bInAir = HazeOwningActor.GetFallingData().bIsFalling; 
    }
	// Death is very much fire-and-forget, since we won't have any higher brain functions left. 
	// Resurrection (or being turned undead) are the only valid exit conditions though.
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom() const
    {
		// Note that we do not check for completion of anim states, cause death is kinda final.
		if (!AnimComp.HasPriority(CurrentFeature.Tag))
		 	return true;

		// Stay dead until something really wants to change that (like being respawned by spawn pool)
		return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
    {
		// Animcomp should be told that we're no longer dead by resetting, but just in case...
		AnimComp.ClearPrioritizedFeatureTag(CurrentFeature.Tag);
    }
}