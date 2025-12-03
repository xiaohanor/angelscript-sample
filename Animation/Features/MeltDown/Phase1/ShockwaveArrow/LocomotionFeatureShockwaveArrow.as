struct FLocomotionFeatureShockwaveArrowAnimData
{
	UPROPERTY(Category = "ShockwaveArrow")
	FHazePlaySequenceData PhaseStart;

	UPROPERTY(Category = "ShockwaveArrow")
	FHazePlaySequenceData MH;

	UPROPERTY(Category = "ShockwaveArrow")
	FHazePlayRndSequenceData LeftHandThrow;

	UPROPERTY(Category = "ShockwaveArrow")
	FHazePlayRndSequenceData RightHandThrow;

	UPROPERTY(Category = "ShockwaveArrow")
	FHazePlaySequenceData PhaseExit;
}

class ULocomotionFeatureShockwaveArrow : UHazeLocomotionFeatureBase
{
	default Tag = n"ShockwaveArrow";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureShockwaveArrowAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
