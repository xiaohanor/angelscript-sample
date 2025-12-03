struct FLocomotionFeatureFantasyOtterSlideAnimData
{
	UPROPERTY(Category = "Slide")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "Slide")
	FHazePlaySequenceData LandingEnter;

	UPROPERTY(Category = "Slide")
	FHazePlaySequenceData DefaultAnimation;

	UPROPERTY(Category = "Slide")
	FHazePlaySequenceData SlideJump;
	
	UPROPERTY(Category = "Slide")
	FHazePlayBlendSpaceData SlideFallingLoopBS;

	UPROPERTY(Category = "Slide")
	FHazePlayBlendSpaceData SlideBS;

	UPROPERTY(Category = "Slide")
	FHazePlaySequenceData SlideExit;
}

class ULocomotionFeatureFantasyOtterSlide : UHazeLocomotionFeatureBase
{
	default Tag = n"Slide";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureFantasyOtterSlideAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph

	// Settings

	UPROPERTY(Category = "Settings")
	float MaxTurnSpeed = 500;

	UPROPERTY(Category = "Settings")
	float RootRotationTarget = 1;
}
