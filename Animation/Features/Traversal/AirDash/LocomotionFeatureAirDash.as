struct FLocomotionFeatureAirDashAnimData
{
	UPROPERTY(Category = "AirDash")
	FHazePlaySequenceData AirDash_Left;

	UPROPERTY(Category = "AirDash")
	FHazePlaySequenceData AirDash_Right;
}

class ULocomotionFeatureAirDash : UHazeLocomotionFeatureBase
{
	default Tag = n"AirDash";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAirDashAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
