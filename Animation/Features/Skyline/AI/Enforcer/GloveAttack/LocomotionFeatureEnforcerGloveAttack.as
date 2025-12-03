struct FLocomotionFeatureEnforcerGloveAttackAnimData
{	
	UPROPERTY(Category = "Enforcer_GloveAttack")
	FHazePlaySequenceData GloveTelegraph;

	UPROPERTY(Category = "Enforcer_GloveAttack")
	FHazePlaySequenceData GloveAttack;

	UPROPERTY(Category = "Enforcer_GloveAttack")
	FHazePlaySequenceData GloveRecover;
}

class ULocomotionFeatureEnforcerGloveAttack : UHazeLocomotionFeatureBase
{
	default Tag = LocomotionFeatureAISkylineTags::EnforcerGloveAttack;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureEnforcerGloveAttackAnimData AnimData;

}

