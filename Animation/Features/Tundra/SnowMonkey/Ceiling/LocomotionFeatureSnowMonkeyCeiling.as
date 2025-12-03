struct FLocomotionFeatureSnowMonkeyCeilingAnimData
{
	UPROPERTY(Category = "MH")
	FHazePlaySequenceData MHLeftHand;

	UPROPERTY(Category = "MH")
	FHazePlaySequenceData MHRightHand;


	UPROPERTY(Category = "Fwd")
	FHazePlayBlendSpaceData FwdLeftHand;

	UPROPERTY(Category = "Fwd")
	FHazePlayBlendSpaceData FwdRightHand;


	UPROPERTY(Category = "FwdToMH")
	FHazePlaySequenceData FwdToMhLeftHand;

	UPROPERTY(Category = "FwdToMH")
	FHazePlaySequenceData FwdToMhRightHand;


	UPROPERTY(Category = "Reach")
	FHazePlaySequenceData ReachLeftHand;

	UPROPERTY(Category = "Reach")
	FHazePlaySequenceData ReachRightHand;

}

class ULocomotionFeatureSnowMonkeyCeiling : UHazeLocomotionFeatureBase
{
	default Tag = n"SnowMonkeyCeiling";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSnowMonkeyCeilingAnimData AnimData;
}
