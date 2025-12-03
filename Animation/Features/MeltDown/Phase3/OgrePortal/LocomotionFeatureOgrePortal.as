struct FLocomotionFeatureOgrePortalAnimData
{
	UPROPERTY(Category = "FirstPortal")
	FHazePlaySequenceData EnterPhase;

	UPROPERTY(Category = "FirstPortal")
	FHazePlaySequenceData EnterPhaseFast;

	UPROPERTY(Category = "FirstPortal")
	FHazePlaySequenceData FirstPortalMH;

	UPROPERTY(Category = "FirstPortal")
	FHazePlaySequenceData FirstPortalShakeStart;

	UPROPERTY(Category = "FirstPortal")
	FHazePlaySequenceData FirstPortalShake;

	UPROPERTY(Category = "SecondPortal")
	FHazePlaySequenceData FirstToSecondPortal;

	UPROPERTY(Category = "SecondPortal")
	FHazePlaySequenceData SecondPortalMH;
	
	UPROPERTY(Category = "SecondPortal")
	FHazePlaySequenceData SecondPortalShakeStart;

	UPROPERTY(Category = "SecondPortal")
	FHazePlaySequenceData SecondPortalShake;
	
	UPROPERTY(Category = "ThirdPortal")
	FHazePlaySequenceData SecondToThirdPortal;

	UPROPERTY(Category = "ThirdPortal")
	FHazePlaySequenceData ThirdPortalMH;

	UPROPERTY(Category = "ThirdPortal")
	FHazePlaySequenceData ThirdPortalShakeStart;

	UPROPERTY(Category = "ThirdPortal")
	FHazePlaySequenceData ThirdPortalShake;

	UPROPERTY(Category = "ThirdPortal")
	FHazePlaySequenceData ThirdToFirstPortal;

	UPROPERTY(Category = "ThirdPortal")
	FHazePlaySequenceData PhaseFinished;
}

class ULocomotionFeatureOgrePortal : UHazeLocomotionFeatureBase
{
	default Tag = n"OgrePortal";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureOgrePortalAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
