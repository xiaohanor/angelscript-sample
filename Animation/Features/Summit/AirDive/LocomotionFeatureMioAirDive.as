struct FLocomotionFeatureMioAirDiveAnimData
{
	UPROPERTY(Category = "AirDive")
	FHazePlaySequenceData AirDiveStart;

	UPROPERTY(Category = "AirDive")
	FHazePlaySequenceData AirDiveMh;

	UPROPERTY(Category = "AirDive")
	FHazePlaySequenceData AirDiveLand;
}

class ULocomotionFeatureMioAirDive : UHazeLocomotionFeatureBase
{
	default Tag = n"MioAirDive";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureMioAirDiveAnimData AnimData;
}
