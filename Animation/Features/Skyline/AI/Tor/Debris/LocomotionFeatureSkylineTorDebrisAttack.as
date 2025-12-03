struct FLocomotionFeatureSkylineTorDebrisAttackAnimData
{	
	UPROPERTY(Category = "DebrisAttack")
	FHazePlaySequenceData DebrisAttack;
}

class ULocomotionFeatureSkylineTorDebrisAttack : UHazeLocomotionFeatureBase
{
	default Tag = SkylineTorFeatureTags::DebrisAttack;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSkylineTorDebrisAttackAnimData AnimData;

}

