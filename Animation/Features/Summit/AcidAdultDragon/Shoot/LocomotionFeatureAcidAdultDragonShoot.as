struct FLocomotionFeatureAcidAdultDragonShootAnimData
{
	UPROPERTY(Category = "AcidAdultDragonShoot")
	FHazePlaySequenceData Charge;

	UPROPERTY(Category = "AcidAdultDragonShoot")
	FHazePlaySequenceData Shoot;

}

class ULocomotionFeatureAcidAdultDragonShoot : UHazeLocomotionFeatureBase
{
	default Tag = n"AcidAdultDragonShoot";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAcidAdultDragonShootAnimData AnimData;
}
