struct FLocomotionFeatureWalkerHeadHatchAnimData
{
	UPROPERTY(Category = "WalkerHeadHatch")
	FHazePlaySequenceData AttachLoop;

	UPROPERTY(Category = "WalkerHeadHatch")
	FHazePlaySequenceData GrabHatch;

	UPROPERTY(Category = "WalkerHeadHatch")
	FHazePlaySequenceData HatchStruggle;

	
	UPROPERTY(Category = "WalkerHeadHatch")
	FHazePlaySequenceData Openhatch;

	UPROPERTY(Category = "WalkerHeadHatch")
	FHazePlaySequenceData HatchShoot;

	UPROPERTY(Category = "WalkerHeadHatch")
	FHazePlaySequenceData HatchStartLiftOff;


}

class ULocomotionFeatureWalkerHeadHatch : UHazeLocomotionFeatureBase
{
	default Tag = n"WalkerHeadHatch";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureWalkerHeadHatchAnimData AnimData;
}
