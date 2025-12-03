struct FLocomotionFeatureWallRunAnimData
{
	
	UPROPERTY(BlueprintReadOnly, Category = "WallRun")
    FHazePlayBlendSpaceData WallRun;


	UPROPERTY(BlueprintReadOnly, Category = "WallRun|Enter")
    FHazePlaySequenceData WallRunEnterLeft;

	UPROPERTY(BlueprintReadOnly, Category = "WallRun|Enter")
    FHazePlaySequenceData WallRunEnterRight;


    UPROPERTY(BlueprintReadOnly, Category = "WallRun|Dash")
    FHazePlaySequenceData WallRunDashLeft;

    UPROPERTY(BlueprintReadOnly, Category = "WallRun|Dash")
    FHazePlaySequenceData WallRunDashRight;


    UPROPERTY(BlueprintReadOnly, Category = "WallRun|Jump")
    FHazePlaySequenceData WallRunJumpLeft;

    UPROPERTY(BlueprintReadOnly, Category = "WallRun|Jump")
    FHazePlaySequenceData WallRunJumpRight;




	UPROPERTY(BlueprintReadOnly, Category = "WallRunLedge")
    FHazePlaySequenceData WallRunLedgeLeft;

	UPROPERTY(BlueprintReadOnly, Category = "WallRunLedge")
    FHazePlaySequenceData WallRunLedgeRight;


	UPROPERTY(BlueprintReadOnly, Category = "WallRunLedge|Enter")
    FHazePlaySequenceData WallRunLedgeEnterLeft;

	UPROPERTY(BlueprintReadOnly, Category = "WallRunLedge|Enter")
    FHazePlaySequenceData WallRunLedgeEnterRight;


	UPROPERTY(BlueprintReadOnly, Category = "WallRunLedge|Dash")
    FHazePlaySequenceData WallRunLedgeDashLeft;

    UPROPERTY(BlueprintReadOnly, Category = "WallRunLedge|Dash")
    FHazePlaySequenceData WallRunLedgeDashRight;


    UPROPERTY(BlueprintReadOnly, Category = "WallRunLedge|Jump")
    FHazePlaySequenceData WallRunLedgeJumpLeft;

    UPROPERTY(BlueprintReadOnly, Category = "WallRunLedge|Jump")
    FHazePlaySequenceData WallRunLedgeJumpRight;

	UPROPERTY(BlueprintReadOnly, Category = "WallRunLedge|Mantle")
    FHazePlaySequenceData WallRunLedgeMantleLeft;

	UPROPERTY(BlueprintReadOnly, Category = "WallRunLedge|Mantle")
    FHazePlaySequenceData WallRunLedgeMantleRight;

	UPROPERTY(BlueprintReadOnly, Category = "WallRunLedge|TurnAround")
    FHazePlaySequenceData WallRunLedgeTurnAroundLeft;

	UPROPERTY(BlueprintReadOnly, Category = "WallRunLedge|TurnAround")
    FHazePlaySequenceData WallRunLedgeTurnAroundRight;

}

class ULocomotionFeatureWallRun : UHazeLocomotionFeatureBase
{
	default Tag = n"WallRun";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureWallRunAnimData AnimData;
}
