struct FLocomotionFeatureSlideAnimData
{
    UPROPERTY(BlueprintReadOnly, Category = "Slide")
    FHazePlayBlendSpaceData Slide;

	UPROPERTY(Category = "Slide")
    FHazePlaySequenceData SlideFast;


	UPROPERTY(BlueprintReadOnly, Category = "Slide|Enters")
    FHazePlaySequenceData Enter;

	UPROPERTY(BlueprintReadOnly, Category = "Slide|Enters")
    FHazePlaySequenceData JumpToSlide;

	UPROPERTY(BlueprintReadOnly, Category = "Slide|Enters")
    FHazePlaySequenceData RollDashToSlide;

	UPROPERTY(BlueprintReadOnly, Category = "Slide|Enters")
    FHazePlaySequenceData StepDashToSlide;


	UPROPERTY(BlueprintReadOnly, Category = "Slide|Exits")
    FHazePlaySequenceData ExitToMh;

	UPROPERTY(BlueprintReadOnly, Category = "Slide|Exits")
    FHazePlaySequenceData ExitToRun;

	UPROPERTY(BlueprintReadOnly, Category = "Slide|Exits")
    FHazePlaySequenceData ExitToSprint;

	UPROPERTY(BlueprintReadOnly, Category = "Slide|Exits")
    FHazePlaySequenceData Jump;

	UPROPERTY(BlueprintReadOnly, Category = "Slide|Exits")
    FHazePlaySequenceData Dash;
}

class ULocomotionFeatureSlide : UHazeLocomotionFeatureBase
{
	default Tag = n"Slide";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSlideAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
