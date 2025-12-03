struct FLocomotionFeatureTreeGuardianHealAnimData
{
	UPROPERTY(Category = "TreeGuardianHeal")
	FHazePlayBlendSpaceData DefaultBlendSpace;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Enter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Exit;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData ToWalk;
}

class ULocomotionFeatureTreeGuardianHeal : UHazeLocomotionFeatureBase
{
	default Tag = n"TreeGuardianHeal";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureTreeGuardianHealAnimData AnimData;
}
