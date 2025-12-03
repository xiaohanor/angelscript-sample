struct FLocomotionFeatureOgreStealthAnimData
{

	UPROPERTY(Category = "Stealth")
	FHazePlaySequenceData MH;

	UPROPERTY(Category = "Stealth")
	FHazePlaySequenceData Throw;

	UPROPERTY(Category = "Stealth")
	FHazePlaySequenceData Turn;

	UPROPERTY(Category = "Stealth")
	FHazePlaySequenceData TurnMH;

	UPROPERTY(Category = "Stealth")
	FHazePlaySequenceData TurnBack;

	UPROPERTY(Category = "Stealth")
	FHazePlaySequenceData ThrowTurned;
}

class ULocomotionFeatureOgreStealth : UHazeLocomotionFeatureBase
{
	default Tag = n"Stealth";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureOgreStealthAnimData AnimData;
}