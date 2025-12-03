struct FLocomotionFeatureVaultAnimData
{
	UPROPERTY(Category = "Vault")
	FHazePlayBlendSpaceData EnterBS;

	UPROPERTY(Category = "Vault")
	FHazePlaySequenceData Exit;

	UPROPERTY(Category = "Vault")
	FHazePlaySequenceData Climb;

	UPROPERTY(Category = "Vault")
	FHazePlaySequenceData SlideEnter;

	UPROPERTY(Category = "Vault")
	FHazePlaySequenceData SlideMH;

	UPROPERTY(Category = "Vault")
	FHazePlaySequenceData SlideExit;


	UPROPERTY(Category = "Mirror")
	FHazePlayBlendSpaceData EnterBSMirror;

	UPROPERTY(Category = "Mirror")
	FHazePlaySequenceData ExitMirror;

	UPROPERTY(Category = "Mirror")
	FHazePlaySequenceData ClimbMirror;

	UPROPERTY(Category = "Mirror")
	FHazePlaySequenceData SlideEnterMirror;

	UPROPERTY(Category = "Mirror")
	FHazePlaySequenceData SlideMHMirror;

	UPROPERTY(Category = "Mirror")
	FHazePlaySequenceData SlideExitMirror;

}

class ULocomotionFeatureVault : UHazeLocomotionFeatureBase
{
	default Tag = n"Vault";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureVaultAnimData AnimData;
}
