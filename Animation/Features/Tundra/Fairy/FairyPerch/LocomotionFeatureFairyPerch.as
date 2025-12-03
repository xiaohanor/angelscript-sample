struct FLocomotionFeatureFairyPerchAnimData
{
	UPROPERTY(Category = "FairyPerch")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "FairyPerch")
	FHazePlaySequenceData PerchMh;

	UPROPERTY(Category = "FairyPerch")
	FHazePlaySequenceData TurnMh;

	UPROPERTY(Category = "FairyPerch")
	FHazePlaySequenceData WalkStart;

	UPROPERTY(Category = "FairyPerch")
	FHazePlaySequenceData WalkLoop;

	UPROPERTY(Category = "FairyPerch")
	FHazePlaySequenceData WalkStop;

	UPROPERTY(Category = "FairyPerch")
	FHazePlayBlendSpaceData Loco;

	UPROPERTY(Category = "FairyPerch")
	FHazePlayBlendSpaceData LocoStop;

	
	UPROPERTY(Category = "FairyPerch")
	FHazePlaySequenceData Turn180Right;

	UPROPERTY(Category = "FairyPerch")
	FHazePlaySequenceData Turn180Left;

	UPROPERTY(Category = "FairyPerch")
	FHazePlaySequenceData PerchJump;
}

class ULocomotionFeatureFairyPerch : UHazeLocomotionFeatureBase
{
	default Tag = n"Perch";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureFairyPerchAnimData AnimData;
}
