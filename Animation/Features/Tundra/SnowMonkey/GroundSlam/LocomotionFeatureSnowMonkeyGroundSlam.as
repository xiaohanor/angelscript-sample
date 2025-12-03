struct FLocomotionFeatureSnowMonkeyGroundSlamAnimData
{
	UPROPERTY(Category = "SnowMonkeyGroundSlam")
	FHazePlaySequenceData Grounded;

	UPROPERTY(Category = "SnowMonkeyGroundSlam")
	FHazePlaySequenceData GroundedFwd;

	UPROPERTY(Category = "SnowMonkeyGroundSlam")
	FHazePlaySequenceData InAirStart;

	UPROPERTY(Category = "SnowMonkeyGroundSlam")
	FHazePlaySequenceData InAirMH;

	UPROPERTY(Category = "SnowMonkeyGroundSlam")
	FHazePlaySequenceData InAirEnd;

	UPROPERTY(Category = "SnowMonkeyGroundSlam")
	FHazePlaySequenceData InAirEndSettle;

	UPROPERTY(Category = "SnowMonkeyGroundSlam")
	FHazePlaySequenceData InAirEndFwd;

	UPROPERTY(Category = "SnowMonkeyGroundSlam")
	FHazePlaySequenceData InAirExitAnim;
}

class ULocomotionFeatureSnowMonkeyGroundSlam : UHazeLocomotionFeatureBase
{
	default Tag = n"SnowMonkeyGroundSlam";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSnowMonkeyGroundSlamAnimData AnimData;
}
