struct FLocomotionFeatureSnowMonkeyBossFinalPunchAnimData
{
	UPROPERTY(Category = "SnowMonkeyBossPunch")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "SnowMonkeyBossPunch")
	FHazePlaySequenceData EnterPunch1;

	UPROPERTY(Category = "SnowMonkeyBossPunch")
	FHazePlaySequenceData EnterPunch2;

	UPROPERTY(Category = "SnowMonkeyBossPunch")
	FHazePlaySequenceData JumpUp;

	UPROPERTY(Category = "SnowMonkeyBossPunch")
	FHazePlaySequenceData MH;

	UPROPERTY(Category = "SnowMonkeyBossPunch")
	FHazePlayRndSequenceData RandomFinalPunch;

	UPROPERTY(Category = "SnowMonkeyBossPunch")
	FHazePlaySequenceData LastFinalPunch;
}

class ULocomotionFeatureSnowMonkeyBossFinalPunch : UHazeLocomotionFeatureBase
{
	default Tag = n"SnowMonkeyBossFinalPunch";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSnowMonkeyBossFinalPunchAnimData AnimData;
}
