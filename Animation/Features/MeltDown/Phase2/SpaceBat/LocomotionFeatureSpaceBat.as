struct FLocomotionFeatureSpaceBatAnimData
{
	UPROPERTY(Category = "SpaceBat")
	FHazePlaySequenceData PickUpBat;

	UPROPERTY(Category = "SpaceBat")
	FHazePlaySequenceData MH;

	UPROPERTY(Category = "SpaceBat")
	FHazePlayRndSequenceData SwingLeft;

	UPROPERTY(Category = "SpaceBat")
	FHazePlayRndSequenceData SwingRight;

	UPROPERTY(Category = "SpaceBat")
	FHazePlaySequenceData DropBat;

	UPROPERTY(Category = "SpaceBat")
	FHazePlaySequenceData PhaseFinish_Batter;

	UPROPERTY(Category = "SpaceBat")
	FHazePlaySequenceData PhaseFinish_Neutral;


}

class ULocomotionFeatureSpaceBat : UHazeLocomotionFeatureBase
{
	default Tag = n"SpaceBat";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSpaceBatAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
