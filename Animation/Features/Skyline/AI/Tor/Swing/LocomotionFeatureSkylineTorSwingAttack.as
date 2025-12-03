struct FLocomotionFeatureSkylineTorSwingAttackAnimData
{	
	UPROPERTY(Category = "SwingAttack")
	FHazePlaySequenceData SwingAttackStart;

	UPROPERTY(Category = "SwingAttack")
	FHazePlaySequenceData SwingAttack;

	UPROPERTY(Category = "SwingAttack")
	FHazePlaySequenceData SwingAttackEnd;
}

class ULocomotionFeatureSkylineTorSwingAttack : UHazeLocomotionFeatureBase
{
	default Tag = SkylineTorFeatureTags::SwingAttack;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSkylineTorSwingAttackAnimData AnimData;

}

