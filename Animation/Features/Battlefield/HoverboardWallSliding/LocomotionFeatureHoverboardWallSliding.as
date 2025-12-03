struct FLocomotionFeatureHoverboardWallSlidingAnimData
{
	UPROPERTY(Category = "HoverboardLeftWallSliding")
	FHazePlayBlendSpaceData WallSlideLeftMh;

	UPROPERTY(Category = "HoverboardLeftWallSliding")
	FHazePlaySequenceData WallSlideLeftEnter;

	UPROPERTY(Category = "HoverboardLeftWallSliding")
	FHazePlaySequenceData WallSlideLeftExit;

	UPROPERTY(Category = "HoverboardLeftWallSliding")
	FHazePlaySequenceData WallSlideLeftTransfer;

	UPROPERTY(Category = "HoverboardLeftWallSliding")
	FHazePlaySequenceData WallSlideLeftMhExit;


	UPROPERTY(Category = "HoverboardRightWallSliding")
	FHazePlayBlendSpaceData WallSlideRightMh;

	UPROPERTY(Category = "HoverboardRightWallSliding")
	FHazePlaySequenceData WallSlideRightEnter;

	UPROPERTY(Category = "HoverboardRightWallSliding")
	FHazePlaySequenceData WallSlideRightExit;

	UPROPERTY(Category = "HoverboardRightWallSliding")
	FHazePlaySequenceData WallSlideRightTransfer;

	UPROPERTY(Category = "HoverboardRightWallSliding")
	FHazePlaySequenceData WallSlideRightMhExit;

	UPROPERTY(Category = "HoverboardJumping")
	FHazePlayBlendSpaceData Banking;
}

class ULocomotionFeatureHoverboardWallSliding : UHazeLocomotionFeatureBase
{
	default Tag = n"HoverboardWallSliding";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureHoverboardWallSlidingAnimData AnimData;
}
