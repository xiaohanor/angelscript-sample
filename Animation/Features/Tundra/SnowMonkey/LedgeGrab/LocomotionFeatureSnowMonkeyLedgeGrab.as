struct FLocomotionFeatureSnowMonkeyLedgeGrabAnimData
{

	UPROPERTY(Category = "LedgeGrab")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "LedgeGrab")
	FHazePlaySequenceData MH;

	UPROPERTY(Category = "LedgeGrab")
	FHazePlaySequenceData MantleToMH;

	UPROPERTY(Category = "LedgeGrab")
	FHazePlaySequenceData Cancel;

}

class ULocomotionFeatureSnowMonkeyLedgeGrab : UHazeLocomotionFeatureBase
{
	default Tag = n"LedgeGrab";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSnowMonkeyLedgeGrabAnimData AnimData;
}
