struct FLocomotionFeatureBallistaInteractAnimData
{
	UPROPERTY(Category = "BallistaInteract")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "BallistaInteract")
	FHazePlaySequenceData AdditiveMh;

	UPROPERTY(Category = "BallistaInteract")
	FHazePlaySequenceData AdditiveStruggle;

	UPROPERTY(Category = "BallistaInteract")
	FHazePlaySequenceData Turn;
	
	UPROPERTY(Category = "BallistaInteract")
	FHazePlayBlendSpaceData StrafeBS;

	UPROPERTY(Category = "BallistaInteract")
	FHazePlaySequenceData Exit;
}

class ULocomotionFeatureBallistaInteract : UHazeLocomotionFeatureBase
{
	default Tag = n"BallistaInteract";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureBallistaInteractAnimData AnimData;
}
