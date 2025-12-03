
namespace SubTagAIGravityWhipWallImpact
{
	const FName Impact = n"Impact";	
	const FName Recover = n"Recover";
	const FName Death = n"Death";
}

struct FGravityWhipWallImpactSubTags
{
	UPROPERTY()
	FName Impact = SubTagAIGravityWhipWallImpact::Impact;	
	UPROPERTY()
	FName Recover = SubTagAIGravityWhipWallImpact::Recover;	
	UPROPERTY()
	FName Death = SubTagAIGravityWhipWallImpact::Death;	
}

UCLASS(Abstract)
class UFeatureAnimInstanceAIGravityWhipWallImpact : UFeatureAnimInstanceAIBase
{
	UPROPERTY()
	FGravityWhipWallImpactSubTags SubTags;

    UPROPERTY(Transient, BlueprintHidden, NotEditable)
    ULocomotionFeatureAIGravityWhipWallImpact CurrentFeature;

    UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FLocomotionFeatureAIGravityWhipWallImpactData FeatureData;

    // Add Custom Variables Here

	UPROPERTY()
	float HitPitchBSValue;

	UPROPERTY()
	float HitDirectionBSValue;

	UPROPERTY()
	float TookDamageAlpha;

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

        ULocomotionFeatureAIGravityWhipWallImpact NewFeature = GetFeatureAsClass(ULocomotionFeatureAIGravityWhipWallImpact);
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
		
		if (bHurtReactionThisTick)
		{
			HitPitchBSValue = Math::RandRange(-1, 1);
			HitDirectionBSValue = Math::RandRange(-1, 1);
		}

		float DamageTimeThreshold = 1.0;

		TookDamageAlpha = DamageTimeThreshold - Math::Clamp(Time::GetGameTimeSince(LastDamageTime), 0.0, DamageTimeThreshold) / DamageTimeThreshold;
		TookDamageAlpha = Math::EaseInOut(0, 1, TookDamageAlpha, 2);
		TookDamageAlpha *= 0.25;



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