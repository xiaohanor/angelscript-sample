struct FLocomotionFeatureInteractPunchAnimData
{
	UPROPERTY(Category = "StartPunch")
	FHazePlaySequenceData PunchStart;

	UPROPERTY(Category = "InteractPunch")
	FHazePlaySequenceData Punch_var1;

	UPROPERTY(Category = "InteractPunch")
	FHazePlaySequenceData Punch_var2;

	UPROPERTY(Category = "InteractPunch")
	FHazePlaySequenceData Punch_var3;

	UPROPERTY(Category = "InteractPunch")
	FHazePlaySequenceData Mh;
}

class ULocomotionFeatureInteractPunch : UHazeLocomotionFeatureBase
{
	default Tag = n"InteractPunch";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureInteractPunchAnimData AnimData;
}
