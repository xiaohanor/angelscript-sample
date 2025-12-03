struct FLocomotionFeatureDragonDashAnimData
{
	UPROPERTY(Category = "DragonDash")
	FHazePlaySequenceData DashEnter;

	UPROPERTY(Category = "DragonDash")
	FHazePlaySequenceData DashToMh;

	UPROPERTY(Category = "DragonDash")
	FHazePlaySequenceData DashToMovement;

	UPROPERTY(Category = "DragonDash")
	FHazePlaySequenceData DashToRun;
}

class ULocomotionFeatureDragonDash : UHazeLocomotionFeatureBase
{
	default Tag = n"DragonDash";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureDragonDashAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
