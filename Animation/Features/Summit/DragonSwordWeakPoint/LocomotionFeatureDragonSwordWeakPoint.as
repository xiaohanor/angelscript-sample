struct FLocomotionFeatureDragonSwordWeakPointAnimData
{
	UPROPERTY(Category = "DragonSwordWeakPoint")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "DragonSwordWeakPoint")
	FHazePlaySequenceData Exit;

	UPROPERTY(Category = "DragonSwordWeakPoint")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "DragonSwordWeakPoint")
	FHazePlaySequenceData Charge;

	UPROPERTY(Category = "DragonSwordWeakPoint")
	FHazePlaySequenceData ChargeMh;

	UPROPERTY(Category = "DragonSwordWeakPoint")
	FHazePlaySequenceData Release;

	UPROPERTY(Category = "DragonSwordWeakPoint")
	FHazePlaySequenceData Success;

	UPROPERTY(Category = "DragonSwordWeakPoint")
	FHazePlaySequenceData Failure;

	UPROPERTY(Category = "DragonSwordFinalWeakPoint")
	FHazePlaySequenceData FinalSuccess;

	UPROPERTY(Category = "DragonSwordFinalWeakPoint")
	FHazePlaySequenceData SuccessMh;

	UPROPERTY(Category = "DragonSwordFinalWeakPoint")
	FHazePlaySequenceData BackToMh;

	UPROPERTY(Category = "DragonSwordFinalWeakPoint")
	FHazePlaySequenceData FirstStab;

	UPROPERTY(Category = "DragonSwordFinalWeakPoint")
	FHazePlaySequenceData FirstButtonMash;

	UPROPERTY(Category = "DragonSwordFinalWeakPoint")
	FHazePlaySequenceData SecondStab;

	UPROPERTY(Category = "DragonSwordFinalWeakPoint")
	FHazePlaySequenceData SecondButtonMash;

	UPROPERTY(Category = "DragonSwordFinalWeakPoint")
	FHazePlaySequenceData FinalStab;


	
}

class ULocomotionFeatureDragonSwordWeakPoint : UHazeLocomotionFeatureBase
{
	default Tag = n"DragonSwordWeakPoint";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureDragonSwordWeakPointAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
