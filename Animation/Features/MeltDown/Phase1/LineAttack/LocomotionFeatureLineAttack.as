struct FLocomotionFeatureLineAttackAnimData
{
	UPROPERTY(Category = "LineAttack")
	FHazePlaySequenceData PhaseStart;

	UPROPERTY(Category = "LineAttack")
	FHazePlaySequenceData MH;

	UPROPERTY(Category = "LineAttack")
	FHazePlayBlendSpaceData LeftHandAttack_Var1;

	UPROPERTY(Category = "LineAttack")
	FHazePlayBlendSpaceData RightHandAttack_Var1;

	UPROPERTY(Category = "LineAttack")
	FHazePlaySequenceData PhaseExit;

	UPROPERTY(Category = "AdditiveMovement")
	FHazePlayBlendSpaceData AdditiveMoveBS;

	UPROPERTY(Category = "AdditiveMovement")
	FHazePlaySequenceData LeftStart;

	UPROPERTY(Category = "AdditiveMovement")
	FHazePlaySequenceData MoveLeft;

	UPROPERTY(Category = "AdditiveMovement")
	FHazePlaySequenceData LeftStop;

	UPROPERTY(Category = "AdditiveMovement")
	FHazePlaySequenceData RightStart;

	UPROPERTY(Category = "AdditiveMovement")
	FHazePlaySequenceData MoveRight;

	UPROPERTY(Category = "AdditiveMovement")
	FHazePlaySequenceData RightStop;


}

class ULocomotionFeatureLineAttack : UHazeLocomotionFeatureBase
{
	default Tag = n"LineAttack";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureLineAttackAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
