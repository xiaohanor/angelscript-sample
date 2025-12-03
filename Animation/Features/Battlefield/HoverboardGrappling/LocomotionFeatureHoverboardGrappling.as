struct FLocomotionFeatureHoverboardGrapplingAnimData
{
	UPROPERTY(Category = "Throw")
	FHazePlaySequenceData GrappleThrowGrounded;

	UPROPERTY(Category = "Throw")
	FHazePlaySequenceData GrappleThrowGroundedUpsideDown;

	UPROPERTY(Category = "Launch")
	FHazePlaySequenceData Launch;

	UPROPERTY(Category = "HoverboardGrapplingGrinding")
	FHazePlaySequenceData GrappleGrindFwd;

	UPROPERTY(Category = "HoverboardGrapplingGrinding")
	FHazePlaySequenceData GrappleGrindLeft;

	UPROPERTY(Category = "HoverboardGrapplingGrinding")
	FHazePlaySequenceData GrappleGrindRight;

	UPROPERTY(Category = "HoverboardGrapplingGrinding")
	FHazePlaySequenceData GrappleGrindUpsideDown;

	UPROPERTY(Category = "HoverboardGrapplingGrinding")
	FHazePlaySequenceData GrappleGrindInAir;

	UPROPERTY(Category = "HoverboardGrapplingWallslide")
	FHazePlaySequenceData GrappleWallslideToLeftFwd;

	UPROPERTY(Category = "HoverboardGrapplingWallslide")
	FHazePlaySequenceData GrappleWallslideToLeftLeft;

	UPROPERTY(Category = "HoverboardGrapplingWallslide")
	FHazePlaySequenceData GrappleWallslideToLeftRight;

	UPROPERTY(Category = "HoverboardGrapplingWallslide")
	FHazePlaySequenceData GrappleWallslideToLeftUpsideDown;

	UPROPERTY(Category = "HoverboardGrapplingWallslide")
	FHazePlaySequenceData GrappleWallslideToLeftInAir;

	UPROPERTY(Category = "HoverboardGrapplingWallslide")
	FHazePlaySequenceData GrappleWallslideToRightFwd;

	UPROPERTY(Category = "HoverboardGrapplingWallslide")
	FHazePlaySequenceData GrappleWallslideToRightLeft;

	UPROPERTY(Category = "HoverboardGrapplingWallslide")
	FHazePlaySequenceData GrappleWallslideToRightRight;

	UPROPERTY(Category = "HoverboardGrapplingWallslide")
	FHazePlaySequenceData GrappleWallslideToRightUpsideDown;

	UPROPERTY(Category = "HoverboardGrapplingWallslide")
	FHazePlaySequenceData GrappleWallslideToRightInAir;

	UPROPERTY(Category = "HoverboardGrapplingWallslideFar")
	FHazePlaySequenceData GrappleWallslideFarToLeftFwd;

	UPROPERTY(Category = "HoverboardGrapplingWallslideFar")
	FHazePlaySequenceData GrappleWallslideFarToLeftLeft;

	UPROPERTY(Category = "HoverboardGrapplingWallslideFar")
	FHazePlaySequenceData GrappleWallslideFarToLeftRight;

	UPROPERTY(Category = "HoverboardGrapplingWallslideFar")
	FHazePlaySequenceData GrappleWallslideFarToRightFwd;

	UPROPERTY(Category = "HoverboardGrapplingWallslideFar")
	FHazePlaySequenceData GrappleWallslideFarToRightLeft;

	UPROPERTY(Category = "HoverboardGrapplingWallslideFar")
	FHazePlaySequenceData GrappleWallslideFarToRightRight;

}

class ULocomotionFeatureHoverboardGrappling : UHazeLocomotionFeatureBase
{
	default Tag = n"HoverboardGrappling";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureHoverboardGrapplingAnimData AnimData;
}
