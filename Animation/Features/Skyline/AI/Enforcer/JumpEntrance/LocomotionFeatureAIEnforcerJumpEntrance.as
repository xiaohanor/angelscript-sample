struct FLocomotionFeatureAIEnforcerJumpEntranceAnimData
{
	UPROPERTY(Category = "AIEnforcerJumpEntrance")
	FHazePlaySequenceData Start;
	UPROPERTY(Category = "AIEnforcerJumpEntrance")
	FHazePlaySequenceData Fall;
	UPROPERTY(Category = "AIEnforcerJumpEntrance")
	FHazePlaySequenceData Land;

	
}

class ULocomotionFeatureAIEnforcerJumpEntrance : UHazeLocomotionFeatureBase
{
	default Tag = LocomotionFeatureAISkylineTags::JumpEntrance;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAIEnforcerJumpEntranceAnimData AnimData;
}
