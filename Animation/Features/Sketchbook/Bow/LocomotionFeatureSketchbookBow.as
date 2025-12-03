struct FLocomotionFeatureSketchbookBowAnimData
{
	UPROPERTY(Category = "Bow")
	FHazePlayBlendSpaceData AimFwd;

	UPROPERTY(Category = "Bow")
	FHazePlayBlendSpaceData AimBck;

	UPROPERTY(Category = "Bow")
	FHazePlayBlendSpaceData ShootFwd;

	UPROPERTY(Category = "Bow")
	FHazePlayBlendSpaceData ShootBck;
}

class ULocomotionFeatureSketchbookBow : UHazeLocomotionFeatureBase
{
	default Tag = Sketchbook::Bow::Feature;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSketchbookBowAnimData AnimData;
}
