struct FLocomotionFeatureFairyMovementAnimData
{
	UPROPERTY(Category = "FairyPerch")
	FHazePlaySequenceData Mh;

	

	

	//UPROPERTY(Category = "FairyPerch")
	//FHazePlaySequenceData WalkStart;

	//UPROPERTY(Category = "FairyPerch")
	//FHazePlaySequenceData WalkLoop;

	//UPROPERTY(Category = "FairyPerch")
	//FHazePlaySequenceData WalkStop;

	UPROPERTY(Category = "FairyPerch")
	FHazePlayBlendSpaceData Loco;

	UPROPERTY(Category = "FairyPerch")
	FHazePlayBlendSpaceData LocoStop;
	
	UPROPERTY(Category = "FairyPerch")
	FHazePlayBlendSpaceData LocoStart;

	
	UPROPERTY(Category = "FairyPerch")
	FHazePlaySequenceData Turn180Right;

	UPROPERTY(Category = "FairyPerch")
	FHazePlaySequenceData Turn180Left;
}

class ULocomotionFeatureFairyMovement : UHazeLocomotionFeatureBase
{
	default Tag = n"Perch";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureFairyMovementAnimData AnimData;
}
