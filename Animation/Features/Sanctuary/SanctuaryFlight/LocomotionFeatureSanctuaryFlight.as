struct FLocomotionFeatureSanctuaryFlightAnimData
{
	UPROPERTY(Category = "SanctuaryFlight")
	FHazePlayBlendSpaceData FlightBS;

	UPROPERTY(Category = "SanctuaryFlight")
	FHazePlayBlendSpaceData DashStartBS;

	UPROPERTY(Category = "SanctuaryFlight")
	FHazePlayBlendSpaceData DashStopBS;

	UPROPERTY(Category = "SanctuaryFlight")	
	FHazePlaySequenceData DashUp;

	UPROPERTY(Category = "SanctuaryFlight")	
	FHazePlaySequenceData DashUpStop;

	UPROPERTY(Category = "SanctuaryFlight")	
	FHazePlaySequenceData DashDown;

	UPROPERTY(Category = "SanctuaryFlight")	
	FHazePlaySequenceData DashDownStop;

	UPROPERTY(Category = "SanctuaryFlight")	
	FHazePlaySequenceData DashLeft;

	UPROPERTY(Category = "SanctuaryFlight")	
	FHazePlaySequenceData DashRight;

	UPROPERTY(Category = "SanctuaryFlight")
	FHazePlaySequenceByValueData DashValueTest;

	UPROPERTY(Category = "SanctuaryFlight")
	FHazePlayBlendSpaceData StartBS;

	UPROPERTY(Category = "SanctuaryFlight")
	FHazePlayBlendSpaceData StopBS;
}

class ULocomotionFeatureSanctuaryFlight : UHazeLocomotionFeatureBase
{
	default Tag = n"SanctuaryFlight";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSanctuaryFlightAnimData AnimData;
}

enum EHazeSanctuaryFlightDashAnimationType
{
	Upwards,
	Downwards,
	Left,
	Right,
	UpLeft,
	UpRight,
	DownLeft,
	DownRight,
	None,

}