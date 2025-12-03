struct FLocomotionFeatureCrouchAnimData
{
	UPROPERTY(Category = "Crouch")
	FHazePlaySequenceData EnterMh;

	UPROPERTY(Category = "Crouch")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "Crouch")
	FHazePlaySequenceData Start;

	UPROPERTY(Category = "Crouch")
	FHazePlayBlendSpaceData WalkBS;

	UPROPERTY(Category = "Crouch")
	FHazePlayBlendSpaceData RunBS;

	UPROPERTY(Category = "Crouch")
	FHazePlaySequenceData StopLeft;

	UPROPERTY(Category = "Crouch")
	FHazePlaySequenceData StopRight;

	UPROPERTY(Category = "Crouch")
	FHazePlaySequenceData ExitMh;

	UPROPERTY(Category = "Crouch")
	FHazePlayBlendSpaceData ExitBS;

	UPROPERTY(Category = "Banking")
	FHazePlayBlendSpaceData AdditiveBankingBS;

}

class ULocomotionFeatureCrouch : UHazeLocomotionFeatureBase
{
	default Tag = n"Crouch";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureCrouchAnimData AnimData;
}
