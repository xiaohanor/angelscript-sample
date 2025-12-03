struct FLocomotionFeatureLightBirdAnimData
{
	UPROPERTY(Category = "LightBird")
	FHazePlayBlendSpaceData Aiming;

	UPROPERTY(Category = "LightBird")
	FHazePlaySequenceData ChargeEnter;

	UPROPERTY(Category = "LightBird")
	FHazePlayBlendSpaceData Charge;

	UPROPERTY(Category = "LightBird")
	FHazePlayBlendSpaceData Release;

	UPROPERTY(Category = "LightBird")
	FHazePlaySequenceData IlluminateOld;

	UPROPERTY(Category = "LightBird")
	FHazePlaySequenceData Recall;
	
	UPROPERTY(Category = "LightBird|Launch")
	FHazePlayBlendSpaceData Launch;

	UPROPERTY(Category = "LightBird|Launch")
	FHazePlaySequenceData LaunchStop;

	UPROPERTY(Category = "LightBird|Lantern")
	FHazePlaySequenceData LanternRecall;

	UPROPERTY(Category = "LightBird|Lantern")
	FHazePlaySequenceData LanternEnter;

	UPROPERTY(Category = "LightBird|Lantern")
	FHazePlayBlendSpaceData LanternMh;

	UPROPERTY(Category = "LightBird|Lantern")
	FHazePlaySequenceData LanternLaunch;

	UPROPERTY(Category = "LightBird|Lantern")
	FHazePlaySequenceData LanternStop;

	UPROPERTY(Category = "LightBird|Attached")
	FHazePlaySequenceData IlluminateStart;

	UPROPERTY(Category = "LightBird|Attached")
	FHazePlaySequenceData Illuminate;

	UPROPERTY(Category = "LightBird|Attached")
	FHazePlaySequenceData IlluminateStop;

	UPROPERTY(Category = "LightBird|Attached")
	FHazePlaySequenceData IlluminateRecall;
}

class ULocomotionFeatureLightBird : UHazeLocomotionFeatureBase
{
	default Tag = n"LightBird";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureLightBirdAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
