struct FLocomotionFeatureEnforcerAreaAttackAnimData
{	
	UPROPERTY(Category = "Enforcer_AreaAttack")
	FHazePlaySequenceData AreaAttack;
}

class ULocomotionFeatureEnforcerAreaAttack : UHazeLocomotionFeatureBase
{
	default Tag = LocomotionFeatureAISkylineTags::EnforcerAreaAttack;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureEnforcerAreaAttackAnimData AnimData;

}

