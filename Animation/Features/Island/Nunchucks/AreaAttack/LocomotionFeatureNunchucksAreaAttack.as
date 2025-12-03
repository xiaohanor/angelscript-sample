struct FLocomotionFeatureNunchucksAreaAttackAnimData
{
	UPROPERTY(Category = "NunchucksAreaAttack")
	FHazePlaySequenceData Start;

	UPROPERTY(Category = "NunchucksAreaAttack")
	FHazePlaySequenceData Attack;
}

class ULocomotionFeatureNunchucksAreaAttack : UHazeLocomotionFeatureBase
{
	default Tag = n"NunchucksAreaAttack";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureNunchucksAreaAttackAnimData AnimData;
}
