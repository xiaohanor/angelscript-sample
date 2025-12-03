struct FLocomotionFeatureRaftSwimAnimData
{
	UPROPERTY(Category = "RaftSwim")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "RaftSwim")
	FHazePlayBlendSpaceData SwimBS;

	UPROPERTY(Category = "RaftSwim")
	FHazePlaySequenceData Exit;
}

class ULocomotionFeatureRaftSwim : UHazeLocomotionFeatureBase
{
	default Tag = n"RaftSwim";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureRaftSwimAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
