struct FLocomotionFeatureNunchucksAreaAttackWeaponAnimData
{
	UPROPERTY(Category = "NunchucksAttackWeapon")
	FHazePlaySequenceData Attack1;

	UPROPERTY(Category = "NunchucksAttackWeapon")
	FHazePlaySequenceData Attack1Settle;

	UPROPERTY(Category = "NunchucksAttackWeapon")
	FHazePlaySequenceData Attack2;

	UPROPERTY(Category = "NunchucksAttackWeapon")
	FHazePlaySequenceData Attack2Settle;

	UPROPERTY(Category = "NunchucksAttackWeapon")
	FHazePlaySequenceData Attack3;

	UPROPERTY(Category = "NunchucksAttackWeapon")
	FHazePlaySequenceData Attack3Settle;

	UPROPERTY(Category = "NunchucksAttackWeapon")
	FHazePlaySequenceData Attack4;

	UPROPERTY(Category = "NunchucksAttackWeapon")
	FHazePlaySequenceData Attack4Settle;

	UPROPERTY(Category = "NunchucksAreaAttackWeapon")
	FHazePlaySequenceData AreaAttackStart;

	UPROPERTY(Category = "NunchucksAreaAttackWeapon")
	FHazePlaySequenceData AreaAttack;

	UPROPERTY(Category = "NunchucksAttackWeapon")
	FHazePlaySequenceData LeftAttack1;

	UPROPERTY(Category = "NunchucksAttackWeapon")
	FHazePlaySequenceData LeftAttack1Settle;

	UPROPERTY(Category = "NunchucksAttackWeapon")
	FHazePlaySequenceData RightAttack1;

	UPROPERTY(Category = "NunchucksAttackWeapon")
	FHazePlaySequenceData RightAttack1Settle;

	UPROPERTY(Category = "NunchucksAttackWeapon")
	FHazePlaySequenceData BackwardAttack1;

	UPROPERTY(Category = "NunchucksAttackWeapon")
	FHazePlaySequenceData BackwardAttack1Settle;
}

class ULocomotionFeatureNunchucksAreaAttackWeapon : UHazeLocomotionFeatureBase
{
	default Tag = n"NunchucksAreaAttackWeapon";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureNunchucksAreaAttackWeaponAnimData AnimData;
}
