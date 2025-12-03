struct FLocomotionFeatureEnforcerMeleeAttackAnimData
{
	UPROPERTY(Category = "Enforcer_MeleeAttack")
	FHazePlaySequenceData MeleeAttack;
}



class ULocomotionFeatureEnforcerMeleeAttack : UHazeLocomotionFeatureBase
{
	default Tag = LocomotionFeatureAISkylineTags::EnforcerMeleeAttack;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))

	FLocomotionFeatureEnforcerMeleeAttackAnimData AnimData;

}

