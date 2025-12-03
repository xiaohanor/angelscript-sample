struct FLocomotionFeatureTreeGuardianStrafeAnimData
{
	UPROPERTY(Category = "TreeGuardianStrafe")
	FHazePlayBlendSpaceData Strafe;


}

class ULocomotionFeatureTreeGuardianStrafe : UHazeLocomotionFeatureBase
{
	default Tag = n"TreeGuardianStrafe";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureTreeGuardianStrafeAnimData AnimData;
}
