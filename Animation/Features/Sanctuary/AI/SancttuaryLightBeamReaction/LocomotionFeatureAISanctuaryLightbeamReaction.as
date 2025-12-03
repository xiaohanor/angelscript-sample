struct FLocomotionFeatureAILightBeamReactionAnimData
{
	UPROPERTY(Category = "LightBeam")
	FHazePlaySequenceData TurnToStone;

	UPROPERTY(Category = "LightBeam")
	FHazePlaySequenceData TurnToStoneRecover;
}

class ULocomotionFeatureAILightBeamReaction : UHazeLocomotionFeatureBase
{
	default Tag = LocomotionFeatureAISanctuaryTags::LightBeamReaction;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAILightBeamReactionAnimData AnimData;
}
