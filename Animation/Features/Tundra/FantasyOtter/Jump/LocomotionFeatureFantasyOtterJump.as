struct FLocomotionFeatureFantasyOtterJumpAnimData
{
	UPROPERTY(Category = "Jump")
	FHazePlaySequenceData JumpFromGround;

	UPROPERTY(Category = "FromWater")
	FHazePlayBlendSpaceData JumpFromWaterBS;

	UPROPERTY(Category = "ApexTricks")
	FHazePlayBlendSpaceData ApexTrick_Var1;

	UPROPERTY(Category = "ApexTricks")
	FHazePlayBlendSpaceData ApexTrick_Var2;

	UPROPERTY(Category = "ApexTricks")
	FHazePlayBlendSpaceData ApexTrick_Var3;


}

class ULocomotionFeatureFantasyOtterJump : UHazeLocomotionFeatureBase
{
	default Tag = n"Jump";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureFantasyOtterJumpAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
