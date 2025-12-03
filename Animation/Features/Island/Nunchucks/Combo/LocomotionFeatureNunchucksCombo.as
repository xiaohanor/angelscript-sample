struct FLocomotionFeatureNunchucksComboAnimData
{
	UPROPERTY(Category = "NunchucksCombo")
	FHazePlaySequenceData Combo1;

	UPROPERTY(Category = "NunchucksCombo")
	FHazePlaySequenceData Combo1Settle;
	
	UPROPERTY(Category = "NunchucksCombo")
	FHazePlaySequenceData Combo2;

	UPROPERTY(Category = "NunchucksCombo")
	FHazePlaySequenceData Combo2Settle;

	UPROPERTY(Category = "NunchucksCombo")
	FHazePlaySequenceData Combo3;

	UPROPERTY(Category = "NunchucksCombo")
	FHazePlaySequenceData Combo3Settle;

	UPROPERTY(Category = "NunchucksCombo")
	FHazePlaySequenceData Combo4;

	UPROPERTY(Category = "NunchucksCombo")
	FHazePlaySequenceData Combo4Settle;

	UPROPERTY(Category = "NunchucksCombo")
	FHazePlaySequenceData Left1;

	UPROPERTY(Category = "NunchucksCombo")
	FHazePlaySequenceData Left1Settle;

	UPROPERTY(Category = "NunchucksCombo")
	FHazePlaySequenceData Right1;

	UPROPERTY(Category = "NunchucksCombo")
	FHazePlaySequenceData Right1Settle;

	UPROPERTY(Category = "NunchucksCombo")
	FHazePlaySequenceData Backward1;

	UPROPERTY(Category = "NunchucksCombo")
	FHazePlaySequenceData Backward1Settle;
}

class ULocomotionFeatureNunchucksCombo : UHazeLocomotionFeatureBase
{
	default Tag = n"NunchucksCombo";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureNunchucksComboAnimData AnimData;
}