struct FLocomotionFeatureTreeGuardianDistanceInteractAnimData
{
	UPROPERTY(Category = "TreeGuardianDistanceInteract")
	FHazePlaySequenceData DistanceInteractLoop;
	
	UPROPERTY(Category = "TreeGuardianDistanceInteract")
	FHazePlayBlendSpaceData DistanceInteract;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Enter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Exit;
}


class ULocomotionFeatureTreeGuardianDistanceInteract : UHazeLocomotionFeatureBase
{
	default Tag = n"TreeGuardianDistanceInteract";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureTreeGuardianDistanceInteractAnimData AnimData;
}
