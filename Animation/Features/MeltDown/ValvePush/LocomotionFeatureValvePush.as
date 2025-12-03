struct FLocomotionFeatureValvePushAnimData
{
	UPROPERTY(Category = "ValvePush")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "ValvePush")
	FHazePlaySequenceData MH;

	UPROPERTY(Category = "ValvePush")
	FHazePlaySequenceData Struggle;

	UPROPERTY(Category = "ValvePush")
	FHazePlaySequenceData MoveFwd;

	UPROPERTY(Category = "ValvePush")
	FHazePlaySequenceData Exit;
}

class ULocomotionFeatureValvePush : UHazeLocomotionFeatureBase
{
	default Tag = n"ValvePush";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureValvePushAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
