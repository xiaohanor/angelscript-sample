struct FLocomotionFeatureVortexTridentAnimData
{
	UPROPERTY(Category = "VortexTrident")
	FHazePlaySequenceData PhaseStart;

	UPROPERTY(Category = "VortexTrident")
	FHazePlaySequenceData NeutralMH;

	UPROPERTY(Category = "VortexTrident")
	FHazePlaySequenceData SummonStart;

	UPROPERTY(Category = "VortexTrident")
	FHazePlaySequenceData SummonMH;

	UPROPERTY(Category = "VortexTrident")
	FHazePlaySequenceData SummonExit;

	UPROPERTY(Category = "VortexTrident")
	FHazePlaySequenceData TridentSlamStart;

	UPROPERTY(Category = "VortexTrident")
	FHazePlaySequenceData TridentSlamMH;

	UPROPERTY(Category = "VortexTrident")
	FHazePlaySequenceData TridentSlamMid;

	UPROPERTY(Category = "VortexTrident")
	FHazePlaySequenceData TridentSlamLeft;

	UPROPERTY(Category = "VortexTrident")
	FHazePlaySequenceData TridentSlamRight;

	UPROPERTY(Category = "VortexTrident")
	FHazePlaySequenceData TridentSlamFinished;

	UPROPERTY(Category = "VortexTrident")
	FHazePlaySequenceData ExitFromNeutral;

	UPROPERTY(Category = "VortexTrident")
	FHazePlaySequenceData ExitFromSummon;

	UPROPERTY(Category = "VortexTrident")
	FHazePlaySequenceData ExitFromTridentSlam;

	UPROPERTY(Category = "VortexTrident")
	FHazePlaySequenceData PhaseFinish;
}

class ULocomotionFeatureVortexTrident : UHazeLocomotionFeatureBase
{
	default Tag = n"VortexTrident";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureVortexTridentAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
