struct FLocomotionFeatureVillagePushBoxAnimData
{
	UPROPERTY(Category = "VillagePushBox")
	FHazePlaySequenceData Mh_LeftFootFwd;

	UPROPERTY(Category = "VillagePushBox")
	FHazePlaySequenceData Mh_RightFootFwd;

	UPROPERTY(Category = "VillagePushBox")
	FHazePlaySequenceData Struggle_LeftFootFwd;
	
	UPROPERTY(Category = "VillagePushBox")
	FHazePlaySequenceData Struggle_RightFootFwd;

	UPROPERTY(Category = "VillagePushBox")
	FHazePlaySequenceData Push;
}

class ULocomotionFeatureVillagePushBox : UHazeLocomotionFeatureBase
{
	default Tag = n"VillagePushBox";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureVillagePushBoxAnimData AnimData;
}
