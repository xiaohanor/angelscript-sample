struct FLocomotionFeatureStrafeDashAnimData
{
	UPROPERTY(Category = "StrafeDash")
	FHazePlayBlendSpaceData StrafeDashBlendspace;

	UPROPERTY(Category = "StrafeDash")
	FHazePlayBlendSpaceData ExitBlendspace_Fwd;

	UPROPERTY(Category = "StrafeDash")
	FHazePlayBlendSpaceData ExitBlendspace_Left;

	UPROPERTY(Category = "StrafeDash")
	FHazePlayBlendSpaceData ExitBlendspace_Right;

	UPROPERTY(Category = "StrafeDash")
	FHazePlayBlendSpaceData ExitBlendspace_Bwd;

	UPROPERTY(Category = "StrafeDash")
	FHazePlayBlendSpaceData ExitBlendspace_Still;

	UPROPERTY(Category = "StrafeDash")
	FHazePlayBlendSpaceData ExitBlendspace_Move;

	UPROPERTY(Category = "RollDash")
	FHazePlaySequenceData RollDash;

	UPROPERTY(Category = "RollDash")
	FHazePlayBlendSpaceData RollDashBlendspace;

	UPROPERTY(Category = "RollDash")
	FHazePlaySequenceData RollDash_Bwd;

	UPROPERTY(Category = "RollDash")
	FHazePlayBlendSpaceData RollDashExitBlendspace_Move;

	UPROPERTY(Category = "RollDash")
	FHazePlayBlendSpaceData RollDashExitBlendspace_Fwd;

	UPROPERTY(Category = "RollDash")
	FHazePlayBlendSpaceData RollDashExitBlendspace_Left;

	UPROPERTY(Category = "RollDash")
	FHazePlayBlendSpaceData RollDashExitBlendspace_Right;

	UPROPERTY(Category = "RollDash")
	FHazePlayBlendSpaceData RollDashExitBlendspace_Bwd;
}

class ULocomotionFeatureStrafeDash : UHazeLocomotionFeatureBase
{
	default Tag = n"StrafeDash";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureStrafeDashAnimData AnimData;
}
