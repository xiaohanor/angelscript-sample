struct FLocomotionFeatureSwingWallAnimData
{
	UPROPERTY(Category = "SwingWall")
	FHazePlayBlendSpaceData Enter;

	UPROPERTY(Category = "SwingWall")
	FHazePlayBlendSpaceData WallMovement;

	UPROPERTY(Category = "SwingWall")
	FHazePlayBlendSpaceData Jump;

	UPROPERTY(Category = "SwingWall")
	FHazePlaySequenceData Cancel;

}

class ULocomotionFeatureSwingWall : UHazeLocomotionFeatureBase
{
	default Tag = n"SwingWall";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSwingWallAnimData AnimData;
}
