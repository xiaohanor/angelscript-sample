struct FLocomotionFeatureTreeGuardianFlowerInteractAnimData
{
	UPROPERTY(Category = "TreeGuardianFlowerInteract")
	FHazePlaySequenceData Start;

	UPROPERTY(Category = "TreeGuardianFlowerInteract")
	FHazePlaySequenceData End;

	UPROPERTY(Category = "TreeGuardianFlowerInteract")
	FHazePlayBlendSpaceData Elevator;
}


class ULocomotionFeatureTreeGuardianFlowerInteract : UHazeLocomotionFeatureBase
{
	default Tag = n"TreeGuardianFlowerInteract";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureTreeGuardianFlowerInteractAnimData AnimData;
}
