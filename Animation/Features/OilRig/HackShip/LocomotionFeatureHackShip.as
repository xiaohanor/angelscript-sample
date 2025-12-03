struct FLocomotionFeatureHackShipAnimData
{
	UPROPERTY(Category = "HackShip")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "HackShip")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "HackShip")
	FHazePlaySequenceData Exit;

	UPROPERTY(Category = "HackShip")
	FHazePlaySequenceData TurnAdditive;
}

class ULocomotionFeatureHackShip : UHazeLocomotionFeatureBase
{
	default Tag = n"HackShip";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureHackShipAnimData AnimData;

	UPROPERTY(Category = "IK")
	bool bIKRightHand = true;
}
