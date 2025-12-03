struct FLocomotionFeatureAISmasherDigAnimData
{
	UPROPERTY(Category = "AI_Bhv_Smasher")
	FHazePlaySequenceData DigDown;

	UPROPERTY(Category = "AI_Bhv_Smasher")
	FHazePlaySequenceData DigUp;
}

class ULocomotionFeatureAISmasherDig : UHazeLocomotionFeatureBase
{
	default Tag = LocomotionFeatureAISummitTags::SmasherDig;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAISmasherDigAnimData AnimData;
}
