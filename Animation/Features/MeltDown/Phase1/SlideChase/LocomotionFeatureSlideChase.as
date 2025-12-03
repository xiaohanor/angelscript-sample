struct FLocomotionFeatureSlideChaseAnimData
{
	UPROPERTY(Category = "SlideChase")
	FHazePlaySequenceData PhaseStart;

	UPROPERTY(Category = "SlideChase")
	FHazePlaySequenceData MH;

	UPROPERTY(Category = "SlideChase")
	FHazePlaySequenceData MoveStart;

	UPROPERTY(Category = "SlideChase")
	FHazePlayBlendSpaceData MoveBS;

	UPROPERTY(Category = "SlideChase")
	FHazePlayBlendSpaceData AdditiveLeanBS;

	UPROPERTY(Category = "SlideChase")
	FHazePlaySequenceData MoveStop;

	UPROPERTY(Category = "SlideChase")
	FHazePlayRndSequenceData MoveAttack;

	UPROPERTY(Category = "SlideChase")
	FHazePlayRndSequenceData StillAttack;

	UPROPERTY(Category = "SlideChase")
	FHazePlaySequenceData PhaseFinish;


}

class ULocomotionFeatureSlideChase : UHazeLocomotionFeatureBase
{
	default Tag = n"SlideChase";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSlideChaseAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
