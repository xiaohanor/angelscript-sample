struct FSketchbookMeleeAttackAnimData
{
	UPROPERTY(EditDefaultsOnly)
	FHazePlaySequenceData Animation;

	UPROPERTY(EditDefaultsOnly)
	float BlockAttackDuration = 0;

	UPROPERTY(EditDefaultsOnly)
	float BlockMovementDuration = 0;
}

struct FSketchbookMeleeAttackAnimSequence
{
	/** Sequence of attacks meant to be played in order */
	UPROPERTY(EditDefaultsOnly)
	TArray<FSketchbookMeleeAttackAnimData> Sequence;
}

struct FLocomotionFeatureSketchbookMeleeAnimData
{
	UPROPERTY(Category = "SketchbookMelee")
	FHazePlaySequenceData Mh;

	/** List of attack sequences to randomize from */
	UPROPERTY(Category = "Attacks")
	TArray<FSketchbookMeleeAttackAnimSequence> AttackSequences;

	UPROPERTY(Category = "Attacks")
	FSketchbookMeleeAttackAnimData AirAttack;
}

class ULocomotionFeatureSketchbookMelee : UHazeLocomotionFeatureBase
{
	default Tag = n"SketchbookMelee";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSketchbookMeleeAnimData AnimData;

	UPROPERTY(Category = "Settings")
	bool bUseActionMh = false;

	UPROPERTY(Category = "Settings")
	UHazeBoneFilterAsset DefaultAttackBoneFilter;
}
