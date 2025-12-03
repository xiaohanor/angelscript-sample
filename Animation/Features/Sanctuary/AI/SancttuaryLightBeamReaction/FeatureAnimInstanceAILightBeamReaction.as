namespace SubTagAILightBeamReaction
{
	const FName TurnToStone = n"TurnToStone";
	const FName TurnToStoneRecover = n"TurnToStoneRecover";
}

struct FLightBeamReactionSubTags
{
	UPROPERTY()
	FName TurnToStone = SubTagAILightBeamReaction::TurnToStone;	
	UPROPERTY()
	FName TurnToStoneRecover = SubTagAILightBeamReaction::TurnToStoneRecover;	
}	


UCLASS(Abstract)
class UFeatureAnimInstanceAILightBeamReaction : UFeatureAnimInstanceAIBase
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureAILightBeamReaction Feature;

	UPROPERTY()
	FLightBeamReactionSubTags SubTags;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureAILightBeamReactionAnimData AnimData;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
		ULocomotionFeatureAILightBeamReaction NewFeature = GetFeatureAsClass(ULocomotionFeatureAILightBeamReaction);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;
	}
}
