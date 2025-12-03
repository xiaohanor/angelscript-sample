
namespace SubTagAIGravityWhippable
{
	const FName Grabbed = n"Grabbed";
	const FName GrabbedLand = n"GrabbedLand";
	const FName GrabbedRelease = n"GrabbedRelease";
	const FName Thrown = n"Thrown";
	const FName Stumble = n"Stumble";
	const FName Flinch = n"Flinch";
}

struct FGravityWhippableSubTags
{
	UPROPERTY()
	FName Grabbed = SubTagAIGravityWhippable::Grabbed;	
	UPROPERTY()
	FName GrabbedLand = SubTagAIGravityWhippable::GrabbedLand;	
	UPROPERTY()
	FName GrabbedRelease = SubTagAIGravityWhippable::GrabbedRelease;	
	UPROPERTY()
	FName Thrown = SubTagAIGravityWhippable::Thrown;
	UPROPERTY()
	FName Stumble = SubTagAIGravityWhippable::Stumble;
	UPROPERTY()
	FName Flinch = SubTagAIGravityWhippable::Flinch;
}

UCLASS(Abstract)
class UFeatureAnimInstanceAIGravityWhippable : UFeatureAnimInstanceAIBase
{
	UPROPERTY()
	FGravityWhippableSubTags SubTags;

    UPROPERTY(Transient, BlueprintHidden, NotEditable)
    ULocomotionFeatureAIGravityWhippable CurrentFeature;

    UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FLocomotionFeatureAIGravityWhippableData FeatureData;

    // Add Custom Variables Here

	UPROPERTY()
	int RandomHoldInt;

	UPROPERTY()
	float RandomStartPosition;

    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();

        ULocomotionFeatureAIGravityWhippable NewFeature = GetFeatureAsClass(ULocomotionFeatureAIGravityWhippable);
        if (CurrentFeature != NewFeature)
        {
            CurrentFeature = NewFeature;
            FeatureData = NewFeature.FeatureData;
        }
        if (CurrentFeature == nullptr)
            return;
        
        // Implement Custom Stuff Here

		RandomHoldInt = Math::RandRange(0, 1);

		RandomStartPosition = Math::RandRange(0.0, 1.0);
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