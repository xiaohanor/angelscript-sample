namespace SubTagEnforcerJumpEntrance
{
	const FName Start = n"Start";
	const FName Fall = n"Fall";
	const FName Land = n"Land";
}

struct FEnforcerJumpEntranceSubTags
{
	UPROPERTY()
	FName Start = SubTagEnforcerJumpEntrance::Start;	
	UPROPERTY()
	FName Fall = SubTagEnforcerJumpEntrance::Fall;	
	UPROPERTY()
	FName Land = SubTagEnforcerJumpEntrance::Land;	
}

UCLASS(Abstract)
class UFeatureAnimInstanceEnforcerJumpEntrance : UFeatureAnimInstanceAIBase
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureAIEnforcerJumpEntrance Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureAIEnforcerJumpEntranceAnimData AnimData;

	UPROPERTY()
	FEnforcerJumpEntranceSubTags SubTags;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
		ULocomotionFeatureAIEnforcerJumpEntrance NewFeature = GetFeatureAsClass(ULocomotionFeatureAIEnforcerJumpEntrance);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (TopLevelGraphRelevantAnimTimeRemainingFraction < 0.1)
			return true;
		return false;
		
	}
}