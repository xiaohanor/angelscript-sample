struct FLocomotionFeatureFlowerHatAnimData
{
	UPROPERTY(Category = "FlowerHat")
	FHazePlaySequenceData EnterMio;
	UPROPERTY(Category = "FlowerHat")
	FHazePlaySequenceData EnterZoe;
	UPROPERTY(Category = "FlowerHat")
	FHazePlaySequenceData Start;
	UPROPERTY(Category = "FlowerHat")
	FHazePlayBlendSpaceData Loop;
	UPROPERTY(Category = "FlowerHat")
	FHazePlaySequenceData End;

}

class ULocomotionFeatureFlowerHat : UHazeLocomotionFeatureBase
{
	default Tag = n"FlowerHat";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureFlowerHatAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
