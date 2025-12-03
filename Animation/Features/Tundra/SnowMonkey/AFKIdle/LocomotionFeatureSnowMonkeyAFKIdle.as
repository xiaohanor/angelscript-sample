struct FLocomotionFeatureSnowMonkey_AFKIdleAnimData
{

	UPROPERTY(Category = "SnowMonkey_AFKIdle")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "SnowMonkey_AFKIdle")
	FHazePlaySequenceData MH;

	UPROPERTY(Category = "SnowMonkey_AFKIdle")
	FHazePlaySequenceData Exit;

}

class ULocomotionFeatureSnowMonkey_AFKIdle : UHazeLocomotionFeatureBase
{
	default Tag = n"AFKIdle";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSnowMonkey_AFKIdleAnimData AnimData;
}
