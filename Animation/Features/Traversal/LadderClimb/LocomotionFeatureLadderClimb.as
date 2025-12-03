struct FLocomotionFeatureLadderClimbAnimData
{
	UPROPERTY(Category = "Enters")
	FHazePlaySequenceData BottomEnter;

	UPROPERTY(Category = "Enters")
	FHazePlaySequenceData BottomEnterFromLeft;

	UPROPERTY(Category = "Enters")
	FHazePlaySequenceData BottomEnterFromRight;

	UPROPERTY(Category = "Enters")
	FHazePlaySequenceData TopEnter;

	UPROPERTY(Category = "Enters")
	FHazePlaySequenceData TopEnterBwd;

	UPROPERTY(Category = "Enters")
	FHazePlaySequenceData TopEnterClockwise;

	UPROPERTY(Category = "Enters")
	FHazePlaySequenceData TopEnterCounterClockwise;

	UPROPERTY(Category = "Enters")
	FHazePlaySequenceData AirEnter;

	UPROPERTY(Category = "Enters")
	FHazePlaySequenceData WallRunEnterLeft;
	
	UPROPERTY(Category = "Enters")
	FHazePlaySequenceData WallRunEnterRight;

	UPROPERTY(Category = "LadderClimb")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "LadderClimb")
	FHazePlaySequenceData StartUp;

	UPROPERTY(Category = "LadderClimb")
	FHazePlaySequenceData MoveUp;

	UPROPERTY(Category = "LadderClimb")
	FHazePlaySequenceData UpStop;

	UPROPERTY(Category = "LadderClimb")
	FHazePlaySequenceData UpStopLeft;

	UPROPERTY(Category = "LadderClimb")
	FHazePlaySequenceData MhLeft;

	UPROPERTY(Category = "LadderClimb")
	FHazePlaySequenceData MhRight;

	UPROPERTY(Category = "LadderClimb")
	FHazePlaySequenceData MoveUpLeft;

	UPROPERTY(Category = "LadderClimb")
	FHazePlaySequenceData MoveUpRight;

	UPROPERTY(Category = "LadderClimb")
	FHazePlaySequenceData MoveDownLeft;

	UPROPERTY(Category = "LadderClimb")
	FHazePlaySequenceData MoveDownRight;

	UPROPERTY(Category = "LadderClimb")
	FHazePlaySequenceData JumpUp;

	UPROPERTY(Category = "LadderClimb")
	FHazePlaySequenceData JumpUpLeft;

	UPROPERTY(Category = "Slide")
	FHazePlaySequenceData SlideStartLeft;

	UPROPERTY(Category = "Slide")
	FHazePlaySequenceData SlideStartRight;

	UPROPERTY(Category = "Slide")
	FHazePlaySequenceData SlideMove;

	UPROPERTY(Category = "Slide")
	FHazePlaySequenceData SlideCancel;

	UPROPERTY(Category = "Exits")
	FHazePlaySequenceData TopExitLeft;

	UPROPERTY(Category = "Exits")
	FHazePlaySequenceData TopExitRight;

	UPROPERTY(Category = "Exits")
	FHazePlaySequenceData BottomExitLeft;

	UPROPERTY(Category = "Exits")
	FHazePlaySequenceData BottomExitRight;
	
	UPROPERTY(Category = "Exits")
	FHazePlaySequenceData SlideExit;

	UPROPERTY(Category = "Exits")
	FHazePlaySequenceData SlideExitToAir;

	UPROPERTY(Category = "Exits")
	FHazePlaySequenceData LetGoLeft;

	UPROPERTY(Category = "Exits")
	FHazePlaySequenceData LetGoRight;

	UPROPERTY(Category = "Exits")
	FHazePlaySequenceData JumpOutRight;


}

class ULocomotionFeatureLadderClimb : UHazeLocomotionFeatureBase
{
	default Tag = n"LadderClimb";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureLadderClimbAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
