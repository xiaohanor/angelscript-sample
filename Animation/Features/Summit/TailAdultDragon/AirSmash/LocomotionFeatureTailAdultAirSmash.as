struct FLocomotionFeatureTailAdultAirSmashAnimData
{
	UPROPERTY(Category = "Right")
	FHazePlaySequenceData Start;

	UPROPERTY(Category = "Right")
	FHazePlaySequenceData Loop;

	UPROPERTY(Category = "Right")
	FHazePlayBlendSpaceData ExitBS;

	UPROPERTY(Category = "Left")
	FHazePlaySequenceData StartLeft;

	UPROPERTY(Category = "Left")
	FHazePlaySequenceData LoopLeft;

	UPROPERTY(Category = "Left")
	FHazePlayBlendSpaceData ExitBSLeft;

	UPROPERTY(Category = "Additive")
	FHazePlayBlendSpaceData AdditiveExitBS;

}

class ULocomotionFeatureTailAdultAirSmash : UHazeLocomotionFeatureBase
{
	default Tag = n"AdultDragonAirSmash";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureTailAdultAirSmashAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
