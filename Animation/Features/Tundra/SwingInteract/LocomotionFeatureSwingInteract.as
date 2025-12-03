struct FLocomotionFeatureSwingInteractAnimData
{
	UPROPERTY(Category = "SwingInteract")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "SwingInteract")
	FHazePlayBlendSpaceData Mh;

	UPROPERTY(Category = "SwingInteract")
	FHazePlaySequenceData Punched;
}

class ULocomotionFeatureSwingInteract : UHazeLocomotionFeatureBase
{
	default Tag = n"SwingInteract";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSwingInteractAnimData AnimData;
}
