struct FLocomotionFeatureSnowMonkeyBossPunchAnimData
{	
	UPROPERTY(Category = "SnowMonkeyBossPunch")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "SnowMonkeyBossPunch")
	FHazePlaySequenceData MH;

	UPROPERTY(Category = "SnowMonkeyBossPunch")
	FHazePlaySequenceData Punch1;

	UPROPERTY(Category = "SnowMonkeyBossPunch")
	FHazePlaySequenceData Punch2;

	UPROPERTY(Category = "SnowMonkeyBossPunch")
	FHazePlaySequenceData Punch3;

	UPROPERTY(Category = "SnowMonkeyBossPunch")
	FHazePlaySequenceData Punch4;

	UPROPERTY(Category = "SnowMonkeyBossPunch")
	FHazePlaySequenceData Punch5;

	UPROPERTY(Category = "SnowMonkeyBossPunch")
	FHazePlaySequenceData Punch6;

	UPROPERTY(Category = "SnowMonkeyBossPunch")
	FHazePlaySequenceData Knockback;
}

class ULocomotionFeatureSnowMonkeyBossPunch : UHazeLocomotionFeatureBase
{
	default Tag = n"SnowMonkeyBossPunch";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSnowMonkeyBossPunchAnimData AnimData;
}
