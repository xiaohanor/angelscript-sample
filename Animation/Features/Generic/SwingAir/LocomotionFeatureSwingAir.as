struct FLocomotionFeatureSwingAirAnimData
{
	UPROPERTY(Category = "Still")
	FHazePlaySequenceData StillEnter;

	UPROPERTY(Category = "Still")
	FHazePlaySequenceData StillMH;

	UPROPERTY(Category = "Still")
	FHazePlaySequenceData StillExit;



	UPROPERTY(Category = "Swinging")
	FHazePlayBlendSpaceData SwingEnter;

	UPROPERTY(Category = "Swinging")
	FHazePlayBlendSpaceData SwingNoInput;

	UPROPERTY(Category = "Swinging")
	FHazePlayBlendSpaceData SwingPush;

	UPROPERTY(Category = "Swinging")
	FHazePlaySequenceData SwingImpact;



	UPROPERTY(Category = "Jump|NoInput")
	FHazePlaySequenceData NoInputJumpNoVelocity;

	UPROPERTY(Category = "Jump|NoInput")
	FHazePlaySequenceData NoInputJumpFwd;

	UPROPERTY(Category = "Jump|NoInput")
	FHazePlaySequenceData NoInputJumpBackTurnRight;

	UPROPERTY(Category = "Jump|NoInput")
	FHazePlaySequenceData NoInputJumpBackTurnLeft;



	UPROPERTY(Category = "Jump|Push")
	FHazePlaySequenceData PushJumpNoVelocity;

	UPROPERTY(Category = "Jump|Push")
	FHazePlaySequenceData PushJumpFwd;

	UPROPERTY(Category = "Jump|Push")
	FHazePlaySequenceData PushJumpBackTurnRight;

	UPROPERTY(Category = "Jump|Push")
	FHazePlaySequenceData PushJumpBackTurnLeft;



	UPROPERTY(Category = "Cancel")
	FHazePlayBlendSpaceData SwingingCancel;

		

}

class ULocomotionFeatureSwingAir : UHazeLocomotionFeatureBase
{
	default Tag = n"SwingAir";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSwingAirAnimData AnimData;

	UPROPERTY(BlueprintReadOnly, Category = "Physics")
    UHazePhysicalAnimationProfile PhysAnimProfile;
}
