struct FLocomotionFeatureTreeGuardian_Attach_IceKingAnimData
{
	UPROPERTY(Category = "Animations", BlueprintReadOnly)
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "Animations", BlueprintReadOnly)
	FHazePlayBlendSpaceData ButtonMashBlendSpace;

	UPROPERTY(Category = "Animations", BlueprintReadOnly)
	FHazePlaySequenceData Fail;

	UPROPERTY(Category = "Animations", BlueprintReadOnly)
	FHazePlaySequenceData Success;

	UPROPERTY(Category = "Animations", BlueprintReadOnly)
	FHazePlaySequenceData SuccessMH;
}

class ULocomotionFeatureTreeGuardian_Attach_IceKing : UHazeLocomotionFeatureBase
{
	default Tag = n"TreeGuardian_Attach_IceKing";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureTreeGuardian_Attach_IceKingAnimData AnimData;
}
