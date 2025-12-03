struct FLocomotionFeatureTreeGuardianRangedHitAnimData
{
	UPROPERTY(Category = "TreeGuardianRangedHit")
	FHazePlayBlendSpaceData FailStart;

	UPROPERTY(Category = "TreeGuardianRangedHit")
	FHazePlayBlendSpaceData FailMh;

	UPROPERTY(Category = "TreeGuardianRangedHit")
	FHazePlayBlendSpaceData FailExit;

	
	UPROPERTY(Category = "TreeGuardianRangedHit")
	FHazePlaySequenceData Mh;
}

class ULocomotionFeatureTreeGuardianRangedHit : UHazeLocomotionFeatureBase
{
	default Tag = n"TreeGuardianRangedHit";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureTreeGuardianRangedHitAnimData AnimData;
}
