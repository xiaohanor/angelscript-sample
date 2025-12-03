struct FLocomotionFeatureSpaceBomberAnimData
{
	UPROPERTY(Category = "SpaceBomber")
	FHazePlaySequenceData GrabBomber;

	UPROPERTY(Category = "SpaceBomber")
	FHazePlaySequenceData MH_Bomber;

	UPROPERTY(Category = "SpaceBomber")
	FHazePlaySequenceData MH_Neutral;

	UPROPERTY(Category = "SpaceBomber")
	FHazePlaySequenceData Shooting;

	UPROPERTY(Category = "SpaceBomber")
	FHazePlaySequenceData LetGo;

	UPROPERTY(Category = "SpaceBomber")
	FHazePlaySequenceData Defeat_Bomber;

	UPROPERTY(Category = "SpaceBomber")
	FHazePlaySequenceData Defeat_Neutral;
}

class ULocomotionFeatureSpaceBomber : UHazeLocomotionFeatureBase
{
	default Tag = n"SpaceBomber";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSpaceBomberAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
