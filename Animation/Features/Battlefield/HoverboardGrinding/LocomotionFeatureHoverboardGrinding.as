struct FLocomotionFeatureHoverboardGrindingAnimData
{
	UPROPERTY(Category = "HoverboardFrontGrinding")
	FHazePlaySequenceData GrindFrontMh;

	UPROPERTY(Category = "HoverboardFrontGrinding")
	FHazePlaySequenceData GrindFrontEnter;

	UPROPERTY(Category = "HoverboardFrontGrinding")
	FHazePlaySequenceData GrindFrontJump;

	UPROPERTY(Category = "HoverboardFrontGrinding")
	FHazePlaySequenceData GrindFrontMhExit;

	UPROPERTY(Category = "HoverboardFrontGrinding")
	FHazePlaySequenceData GrindFrontExit;

	UPROPERTY(Category = "HoverboardFrontGrinding")
	FHazePlaySequenceData GrindFrontFallingAntiClockwise;

	UPROPERTY(Category = "HoverboardFrontGrinding")
	FHazePlayBlendSpaceData GrindFrontBanking;

	UPROPERTY(Category = "HoverboardFrontGrinding")
	FHazePlayBlendSpaceData GrindFrontTurnBanking;
	


	UPROPERTY(Category = "HoverboardBackGrinding")
	FHazePlaySequenceData GrindBackMh;

	UPROPERTY(Category = "HoverboardBackGrinding")
	FHazePlaySequenceData GrindBackEnter;

	UPROPERTY(Category = "HoverboardBackGrinding")
	FHazePlaySequenceData GrindBackJump;

	UPROPERTY(Category = "HoverboardBackGrinding")
	FHazePlaySequenceData GrindBackMhExit;

	UPROPERTY(Category = "HoverboardBackGrinding")
	FHazePlaySequenceData GrindBackExit;

	UPROPERTY(Category = "HoverboardBackGrinding")
	FHazePlayBlendSpaceData GrindBackBanking;

	UPROPERTY(Category = "HoverboardBackGrinding")
	FHazePlayBlendSpaceData GrindBackTurnBanking;

	UPROPERTY(Category = "HoverboardJumping")
	FHazePlayBlendSpaceData Banking;
}

class ULocomotionFeatureHoverboardGrinding : UHazeLocomotionFeatureBase
{
	default Tag = n"HoverboardGrinding";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureHoverboardGrindingAnimData AnimData;
}
