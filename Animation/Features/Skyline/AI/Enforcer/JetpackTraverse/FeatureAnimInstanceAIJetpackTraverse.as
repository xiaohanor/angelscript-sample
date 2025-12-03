
namespace SubTagAIJetpackTraverse
{
	const FName Launch = n"Launch";
	const FName Land = n"Land";
}

struct FJetpackTraverseSubTags
{
	UPROPERTY()
	FName Launch = SubTagAIJetpackTraverse::Launch;	
	UPROPERTY()
	FName Land = SubTagAIJetpackTraverse::Land;	
}

UCLASS(Abstract)
class UFeatureAnimInstanceAIJetpackTraverse : UFeatureAnimInstanceAIBase
{
	UPROPERTY()
	FJetpackTraverseSubTags SubTags;

    UPROPERTY(Transient, BlueprintHidden, NotEditable)
    ULocomotionFeatureAIJetpackTraverse CurrentFeature;

    UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FLocomotionFeatureAIJetpackTraverseAnimData FeatureData;

    // Add Custom Variables Here

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ArcAlpha;

	UEnforcerJetpackComponent JetpackComp;

    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();

        ULocomotionFeatureAIJetpackTraverse NewFeature = GetFeatureAsClass(ULocomotionFeatureAIJetpackTraverse);
        if (CurrentFeature != NewFeature)
        {
            CurrentFeature = NewFeature;
            FeatureData = NewFeature.AnimData;
        }
        if (CurrentFeature == nullptr)
            return;
        
        // Implement Custom Stuff Here

		if (HazeOwningActor != nullptr)
			JetpackComp = UEnforcerJetpackComponent::Get(HazeOwningActor);
    }

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		Super::BlueprintUpdateAnimation(DeltaTime);

		if (JetpackComp != nullptr)
			ArcAlpha = JetpackComp.AnimArcAlpha;

#if EDITOR		
		if ((HazeOwningActor != nullptr) && HazeOwningActor.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugString(HazeOwningActor.FocusLocation, "SpeedUp: " + SpeedUp, Scale = 2.0);
			Print("ArcAlpha: " + ArcAlpha, 0.f);
			Debug::DrawDebugString(HazeOwningActor.FocusLocation, "SpeedUp: " + SpeedUp, Scale = 2.0);
			Debug::DrawDebugString(HazeOwningActor.FocusLocation + FVector(0.0, 0.0, 40.0), "ArcAlpha: " + ArcAlpha, Scale = 2.0);
			Debug::DrawDebugString(HazeOwningActor.FocusLocation, "SpeedRight: " + SpeedRight / 1000.0 * 45, Scale = 2.0);
			//Print("ArcAlpha: " + ArcAlpha, 0.f);
		}
#endif
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
