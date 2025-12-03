
struct FLocomotionFeatureAIHurtReactionsData
{
    UPROPERTY(BlueprintReadOnly, Category = "AIHurtReactions")
    FHazePlaySequenceData Default;
    
	UPROPERTY(Category = "AIHurtReactions")
    FHazePlaySequenceData IdleMH;

	UPROPERTY(Category = "Knockback")
    FHazePlaySequenceData Knockback;

    UPROPERTY(Category = "Knockback")
    FHazePlaySequenceData KnockbackRecover;

	UPROPERTY(Category = "Knockback")
    FHazePlaySequenceData KnockbackFlyPose;

	UPROPERTY(Category = "Knockback")
    FHazePlaySequenceData KnockbackWallHitStunned;

    UPROPERTY(Category = "Knockback")
    FHazePlaySequenceData KnockbackWallHitDeath;

    UPROPERTY(Category = "Knockback")
    FHazePlaySequenceData DeathPose;

    UPROPERTY(Category = "AIHurtReactions")
    FHazePlaySequenceData HitReactionBig;

    UPROPERTY(Category = "AIHurtReactions")
    FHazePlaySequenceData HitReactionSmall;

}

class ULocomotionFeatureAIHurtReactions : UHazeLocomotionFeatureBase
{
    default Tag = LocomotionFeatureAITags::HurtReactions;

    UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
    FLocomotionFeatureAIHurtReactionsData FeatureData;
}