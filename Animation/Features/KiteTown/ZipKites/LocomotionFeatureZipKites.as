struct FLocomotionFeatureZipKitesAnimData
{
	UPROPERTY(Category = "ZipKites | Swing")
	FHazePlayBlendSpaceData SwingBS;

	UPROPERTY(Category = "ZipKites | Swing")
	FHazePlaySequenceData RollDashJump;

	UPROPERTY(Category = "ZipKites | Swing")
	FHazePlaySequenceData AerialMH;
}

class ULocomotionFeatureZipKites : UHazeLocomotionFeatureBase
{
	default Tag = n"ZipKites";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureZipKitesAnimData AnimData;

}
