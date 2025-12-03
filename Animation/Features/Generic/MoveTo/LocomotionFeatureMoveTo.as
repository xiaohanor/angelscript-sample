struct FLocomotionFeatureMoveToAnimData
{
	UPROPERTY(Category = "Grounded")
	FHazePlayBlendSpaceData Start_Close;

	UPROPERTY(Category = "Grounded")
	FHazePlayBlendSpaceData Start_Far;

	UPROPERTY(Category = "Airborne")
	FHazePlayBlendSpaceData Start_Close_InAir;

	UPROPERTY(Category = "Airborne")
	FHazePlayBlendSpaceData Start_Far_InAir;

}

class ULocomotionFeatureMoveTo : UHazeLocomotionFeatureBase
{
	default Tag = n"MoveTo";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureMoveToAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
