struct FLocomotionFeatureGameShowBombOverrideAnimData
{
	UPROPERTY(Category = "GameShowBombOverride")
	FHazePlaySequenceData BackPackMH;
	
	UPROPERTY(Category = "GameShowBombOverride")
	FHazePlaySequenceData ThrowFwd;

	UPROPERTY(Category = "GameShowBombOverride")
	FHazePlaySequenceData ThrowLeft;

	UPROPERTY(Category = "GameShowBombOverride")
	FHazePlaySequenceData ThrowRight;

	UPROPERTY(Category = "GameShowBombOverride")
	FHazePlaySequenceData ThrowBwd;

	UPROPERTY(Category = "GameShowBombOverride")
	FHazePlaySequenceData Catch;

}

class ULocomotionFeatureGameShowBombOverride : UHazeLocomotionFeatureBase
{
	default Tag = n"GameShowBombOverride";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureGameShowBombOverrideAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
