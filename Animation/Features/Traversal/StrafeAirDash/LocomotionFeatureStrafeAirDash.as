struct FLocomotionFeatureStrafeAirDashAnimData
{
	UPROPERTY(Category = "StrafeAirDash")
	FHazePlayBlendSpaceData AirDashBS;
}

class ULocomotionFeatureStrafeAirDash : UHazeLocomotionFeatureBase
{
	default Tag = n"StrafeAirDash";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureStrafeAirDashAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
