struct FLocomotionFeatureSkydiveAnimData
{
	UPROPERTY(Category = "Dive|Skydive")
	FHazePlaySequenceData EnterFromAirMovement_Left;

	UPROPERTY(Category = "Dive|Skydive")
	FHazePlaySequenceData EnterFromAirMovement_Right;

	UPROPERTY(Category = "Dive|Skydive")
	FHazePlayBlendSpaceData FallingMH;

	UPROPERTY(Category = "Dive|Exit")
	FHazePlayRndSequenceData ExitToLanding;

	UPROPERTY(Category = "Dive|Exit")
	FHazePlaySequenceData ExitToLandingMH;

	UPROPERTY(Category = "Dive|Exit")
	FHazePlayRndSequenceData ExitToDive;

	UPROPERTY(Category = "Dive|Exit")
	FHazePlaySequenceData ExitToDiveMH;

	UPROPERTY(Category = "Dive|Dash")
	FHazePlaySequenceData DashFwd;

	UPROPERTY(Category = "Dive|Dash")
	FHazePlaySequenceData DashBwd;
	
	UPROPERTY(Category = "Dive|Dash")
	FHazePlaySequenceData DashLeft;

	UPROPERTY(Category = "Dive|Dash")
	FHazePlaySequenceData DashRight;

	//Below are animations for the "Falling" kind of Skydive, whereas the other is more "diving"

	UPROPERTY(Category = "Fall|Skydive")
	FHazePlaySequenceData EnterFromAirMovement_Left_Fall;

	UPROPERTY(Category = "Fall|Skydive")
	FHazePlaySequenceData EnterFromAirMovement_Right_Fall;

	UPROPERTY(Category = "Fall|Skydive")
	FHazePlayBlendSpaceData FallingMH_Fall;

	UPROPERTY(Category = "Fall|Exit")
	FHazePlayRndSequenceData ExitToLanding_Fall;

	UPROPERTY(Category = "Fall|Exit")
	FHazePlaySequenceData ExitToLandingMH_Fall;

	UPROPERTY(Category = "Fall|Exit")
	FHazePlayRndSequenceData ExitToDive_Fall;

	UPROPERTY(Category = "Fall|Exit")
	FHazePlaySequenceData ExitToDiveMH_Fall;

	UPROPERTY(Category = "Fall|Dash")
	FHazePlaySequenceData DashFwd_Fall;

	UPROPERTY(Category = "Fall|Dash")
	FHazePlaySequenceData DashBwd_Fall;
	
	UPROPERTY(Category = "Fall|Dash")
	FHazePlaySequenceData DashLeft_Fall;

	UPROPERTY(Category = "Fall|Dash")
	FHazePlaySequenceData DashRight_Fall;

}

class ULocomotionFeatureSkydive : UHazeLocomotionFeatureBase
{
	default Tag = n"Skydive";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSkydiveAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
