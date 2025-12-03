struct FLocomotionFeatureLavaAnimData
{
	
	UPROPERTY(Category = "Lava")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "Lava")
	FHazePlaySequenceData SwingLeft;

	UPROPERTY(Category = "Lava")
	FHazePlaySequenceData SwingRight;

	UPROPERTY(Category = "Lava")
	FHazePlaySequenceData SwingDoubleHorizontal;

	UPROPERTY(Category = "Lava")
	FHazePlaySequenceData OverHeadSwing;

	UPROPERTY(Category = "Lava")
	FHazePlayBlendSpaceData OverHeadSwingBS;
}

class ULocomotionFeatureLava : UHazeLocomotionFeatureBase
{
	default Tag = n"Lava";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureLavaAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
