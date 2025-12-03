struct FLocomotionFeatureMonkeyCrowdAnimData
{
	UPROPERTY(Category = "Generic")
	FHazePlayRndSequenceData GenericMh;
	UPROPERTY(Category = "Generic")
	FHazePlayRndSequenceData GenericSuccess;
	UPROPERTY(Category = "Generic")
	FHazePlayRndSequenceData GenericFail;

	UPROPERTY(Category = "DJ")
	FHazePlayRndSequenceData DJMh;
	UPROPERTY(Category = "DJ")
	FHazePlaySequenceData DjRecordScratchStart;
	UPROPERTY(Category = "DJ")
	FHazePlayRndSequenceData DjRecordScratchMh;

	UPROPERTY(Category = "SimonSays")
	FHazePlayRndSequenceData SimonSaysMh;
	UPROPERTY(Category = "SimonSays")
	FHazePlayRndSequenceData SimonSaysSuccess;
	UPROPERTY(Category = "SimonSays")
	FHazePlayRndSequenceData SimonSaysFail;

	UPROPERTY(Category = "CongaLine")
	FHazePlayRndSequenceData CongaLineMh;
	UPROPERTY(Category = "CongaLine")
	FHazePlayRndSequenceData CongaLineSuccess;
	UPROPERTY(Category = "CongaLine")
	FHazePlayRndSequenceData CongaLineFail;

	UPROPERTY(Category = "DiscoDance")
	FHazePlayRndSequenceData DiscoDanceMh;
	UPROPERTY(Category = "DiscoDance")
	FHazePlayRndSequenceData DiscoDanceSuccess;
	UPROPERTY(Category = "DiscoDance")
	FHazePlayRndSequenceData DiscoDanceFail;

	UPROPERTY(Category = "BellyDance")
	FHazePlayRndSequenceData BellyDanceMh;
	UPROPERTY(Category = "BellyDance")
	FHazePlayRndSequenceData BellyDanceSuccess;
	UPROPERTY(Category = "BellyDance")
	FHazePlayRndSequenceData BellyDanceFail;

	UPROPERTY(Category = "BreakDance")
	FHazePlayRndSequenceData BreakDanceMh;
	UPROPERTY(Category = "BreakDance")
	FHazePlayRndSequenceData BreakDanceSuccess;
	UPROPERTY(Category = "BreakDance")
	FHazePlayRndSequenceData BreakDanceFail;

}

class ULocomotionFeatureMonkeyCrowd : UHazeLocomotionFeatureBase
{
	default Tag = n"MonkeyCrowd";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureMonkeyCrowdAnimData AnimData;
}