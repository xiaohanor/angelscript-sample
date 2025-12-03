struct FLocomotionFeatureJumpAnimData
{
	UPROPERTY(BlueprintReadOnly, Category = "Jump")
    FHazePlayBlendSpaceData JumpStillBS;

	UPROPERTY(BlueprintReadOnly, Category = "Jump")
    FHazePlayBlendSpaceData JumpBS_var1;

	UPROPERTY(BlueprintReadOnly, Category = "Jump")
    FHazePlayBlendSpaceData JumpBS_var2;

	UPROPERTY(BlueprintReadOnly, Category = "Jump")
	FHazePlaySequenceData Jump_var3;

	UPROPERTY(BlueprintReadOnly, Category = "RollDashJump")
	FHazePlayBlendSpaceData RollDashJump;

	UPROPERTY(Category = "Jump")
	FHazePlaySequenceData JumpVar1;

	UPROPERTY(Category = "Jump")
	FHazePlaySequenceData JumpFastVar1;

	UPROPERTY(Category = "Jump")
	FHazePlaySequenceData JumpVar2;

	UPROPERTY(Category = "Jump")
	FHazePlaySequenceData JumpFastVar2;

	UPROPERTY(Category = "DoubleJump")
	FHazePlaySequenceData DoubleJump;

	UPROPERTY(Category = "DoubleJump")
	FHazePlaySequenceData DoubleJumpLeft;

	



}

class ULocomotionFeatureJump : UHazeLocomotionFeatureBase
{
	default Tag = n"Jump";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureJumpAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}

enum EJumpingAnimationType

{
	JumpStill,
	JumpLeft,
	JumpRight,
	JumpVar1,
	JumpFromLanding,
	JumpVar2,
	JumpVar3,
	
	

}
