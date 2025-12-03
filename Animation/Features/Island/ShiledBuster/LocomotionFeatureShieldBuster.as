struct FLocomotionFeatureShieldBusterAnimData
{
	UPROPERTY(Category = "ShieldBuster")
	FHazePlayBlendSpaceData RightArm;

	UPROPERTY(Category = "ShieldBuster")
	FHazePlayBlendSpaceData LeftArm;
}

class ULocomotionFeatureShieldBuster : UHazeLocomotionFeatureBase
{
	default Tag = n"ShieldBuster";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureShieldBusterAnimData AnimData;
}
