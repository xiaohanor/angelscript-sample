struct FLocomotionFeatureSpaceShipsAnimData
{
	UPROPERTY(Category = "SpaceShips")
	FHazePlaySequenceData StartPhase;

	UPROPERTY(Category = "SpaceShips")
	FHazePlaySequenceData MH_Neutral;

	UPROPERTY(Category = "SpaceShips")
	FHazePlaySequenceData MH_HoldBoth;

	UPROPERTY(Category = "SpaceShips")
	FHazePlaySequenceData MH_HoldLeftHand;

	UPROPERTY(Category = "SpaceShips")
	FHazePlaySequenceData MH_HoldRightHand;

	UPROPERTY(Category = "SpaceShips")
	FHazePlaySequenceData ThrowLeftHandFirst;

	UPROPERTY(Category = "SpaceShips")
	FHazePlaySequenceData ThrowLeftHandSecond;

	UPROPERTY(Category = "SpaceShips")
	FHazePlaySequenceData ThrowRightHandFirst;

	UPROPERTY(Category = "SpaceShips")
	FHazePlaySequenceData ThrowRightHandSecond;

	UPROPERTY(Category = "SpaceShips")
	FHazePlaySequenceData PhaseFinish_Neutral;
}

class ULocomotionFeatureSpaceShips : UHazeLocomotionFeatureBase
{
	default Tag = n"SpaceShips";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSpaceShipsAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
