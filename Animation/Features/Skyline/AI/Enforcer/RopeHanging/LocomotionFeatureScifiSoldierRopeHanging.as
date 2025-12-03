struct FLocomotionFeatureScifiSoldierRopeHangingAnimData
{
	UPROPERTY(Category = "ScifiSoldierRopeHanging")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "ScifiSoldierRopeHanging")
	FHazePlayBlendSpaceData Aim;
}

class ULocomotionFeatureScifiSoldierRopeHanging : UHazeLocomotionFeatureBase
{
	default Tag = LocomotionFeatureAISkylineTags::ScifiSoldierRopeHanging;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureScifiSoldierRopeHangingAnimData AnimData;
}
