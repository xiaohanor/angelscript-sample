
namespace SubTagAIGravityWhipThrown
{
	const FName Thrown = n"Thrown";	
	const FName Recover = n"Recover";
}

struct FGravityWhipThrownSubTags
{
	UPROPERTY()
	FName Thrown = SubTagAIGravityWhipThrown::Thrown;	
	UPROPERTY()
	FName Recover = SubTagAIGravityWhipThrown::Recover;	
}

UCLASS(Abstract)
class UFeatureAnimInstanceAIGravityWhipThrown : UFeatureAnimInstanceAIBase
{
	UPROPERTY()
	FGravityWhipThrownSubTags SubTags;

    UPROPERTY(Transient, BlueprintHidden, NotEditable)
    ULocomotionFeatureAIGravityWhipThrown CurrentFeature;

    UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FLocomotionFeatureAIGravityWhipThrownData FeatureData;

    // Add Custom Variables Here

	UFUNCTION(BlueprintOverride)
	float32 GetBlendTime() const
	{
		return 0.06;
	}

    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();

        ULocomotionFeatureAIGravityWhipThrown NewFeature = GetFeatureAsClass(ULocomotionFeatureAIGravityWhipThrown);
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