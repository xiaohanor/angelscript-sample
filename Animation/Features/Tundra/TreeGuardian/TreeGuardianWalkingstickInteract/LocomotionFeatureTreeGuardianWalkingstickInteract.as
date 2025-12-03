struct FLocomotionFeatureTreeGuardianWalkingstickInteractAnimData
{
	UPROPERTY(Category = "TreeGuardianWalkingstickInteract")
	FHazePlayBlendSpaceData InteractBS;

	UPROPERTY(Category = "TreeGuardianWalkingstickInteract")
	FHazePlaySequenceData InteractEnd;

	UPROPERTY(Category = "TreeGuardianWalkingstickInteract")
	FHazePlaySequenceData InteractStart;
}

class ULocomotionFeatureTreeGuardianWalkingstickInteract : UHazeLocomotionFeatureBase
{
	default Tag = n"TreeGuardianWalkingstickInteract";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureTreeGuardianWalkingstickInteractAnimData AnimData;
}
