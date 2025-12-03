struct FLocomotionFeatureFanatsyFairyDashAnimData
{
	UPROPERTY(Category = "FanatsyFairyDash")
	FHazePlaySequenceData Dash;

	UPROPERTY(Category = "FanatsyFairyDash")
	FHazePlaySequenceData DashToMh;

	UPROPERTY(Category = "FanatsyFairyDash")
	FHazePlaySequenceData DashToMovement;

	UPROPERTY(Category = "FanatsyFairyDash")
	FHazePlaySequenceData DashToSprint;
}

class ULocomotionFeatureFanatsyFairyDash : UHazeLocomotionFeatureBase
{
	default Tag = n"FanatsyFairyDash";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureFanatsyFairyDashAnimData AnimData;
}
