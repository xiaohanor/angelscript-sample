struct FLocomotionFeatureSanctuaryGhostKnightAttackAnimData
{
	UPROPERTY(Category = "Charge")
	FHazePlaySequenceData ChargeHit;

	UPROPERTY(Category = "Charge")
	FHazePlaySequenceData ChargeMiss;

	UPROPERTY(Category = "Melee")
	FHazePlayRndSequenceData MeleeRND;

	UPROPERTY(Category = "Recover")
	FHazePlaySequenceData RecoverHit;

	UPROPERTY(Category = "Recover")
	FHazePlaySequenceData RecoverMiss;
}

class ULocomotionFeatureSanctuaryGhostKnightAttack : UHazeLocomotionFeatureBase
{
	default Tag = LocomotionFeatureAISanctuaryTags::GhostKnightAttack;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSanctuaryGhostKnightAttackAnimData AnimData;
}
