struct FLocomotionFeatureDropAttackAnimData
{
	UPROPERTY(Category = "DropAttack")
	FHazePlaySequenceData PhaseStart;

	UPROPERTY(Category = "DropAttack")
	FHazePlaySequenceData MH;

	UPROPERTY(Category = "DropAttack")
	FHazePlaySequenceData PhaseExit;	
}

class ULocomotionFeatureDropAttack : UHazeLocomotionFeatureBase
{
	default Tag = n"DropAttack";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureDropAttackAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
