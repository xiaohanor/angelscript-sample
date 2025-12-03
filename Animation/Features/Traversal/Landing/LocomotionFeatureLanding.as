struct FLocomotionFeatureLandingAnimData
{
	UPROPERTY(Category = "Landing")
	FHazePlayBlendSpaceData LandStillBSVar1;

	UPROPERTY(Category = "Landing")
	FHazePlayBlendSpaceData LandStillBSVar2;

	UPROPERTY(Category = "Landing")
	FHazePlayBlendSpaceData LandFwdBSVar1;

	UPROPERTY(Category = "Landing")
	FHazePlayBlendSpaceData LandFwdBSVar2;

	UPROPERTY(Category = "Landing")
	FHazePlaySequenceData LandStunned;
	
	UPROPERTY(Category = "Landing")
	FHazePlaySequenceData LandRunVar1;
	
	UPROPERTY(Category = "Landing")
	FHazePlaySequenceData LandRunVar2;

	UPROPERTY(Category = "Landing")
	FHazePlaySequenceData LandSprintVar1;
	
	UPROPERTY(Category = "Landing")
	FHazePlaySequenceData LandSprintVar2;

	UPROPERTY(Category = "Landing")
	FHazePlaySequenceData LandRunToStillVar1;

	UPROPERTY(Category = "Landing")
	FHazePlaySequenceData LandRunToStillVar2;

	UPROPERTY(Category = "Landing")
	FHazePlaySequenceData LandHighJog;

	UPROPERTY(Category = "Landing")
	FHazePlaySequenceData LandSprintToStillVar1;

	UPROPERTY(Category = "Landing")
	FHazePlaySequenceData LandSprintToStillVar2;

	UPROPERTY(Category = "LeftFoot")
	FHazePlayBlendSpaceData LandStillLeftBS;

	UPROPERTY(Category = "LeftFoot")
	FHazePlayBlendSpaceData LandFwdLeftBS;

	UPROPERTY(Category = "LeftFoot")
	FHazePlayBlendSpaceData LandHighStillLeftBS;

	UPROPERTY(Category = "LeftFoot")
	FHazePlayBlendSpaceData LandHighStillToMoveLeftBS;

	UPROPERTY(Category = "LeftFoot")
	FHazePlayBlendSpaceData LandHighFwdLeftBS;

	UPROPERTY(Category = "RightFoot")
	FHazePlayBlendSpaceData LandStillRightBS;

	UPROPERTY(Category = "RightFoot")
	FHazePlayBlendSpaceData LandFwdRightBS;

	UPROPERTY(Category = "RightFoot")
	FHazePlayBlendSpaceData LandHighStillRightBS;

	UPROPERTY(Category = "RightFoot")
	FHazePlayBlendSpaceData LandHighStillToMoveRightBS;

	UPROPERTY(Category = "RightFoot")
	FHazePlayBlendSpaceData LandHighFwdRightBS;

	UPROPERTY(Category = "HighSpeed")
	FHazePlayBlendSpaceData LandSpeedRightBS;

	UPROPERTY(Category = "HighSpeed")
	FHazePlayBlendSpaceData LandSpeedFwdRightBS;

	UPROPERTY(Category = "HighSpeed")
	FHazePlayBlendSpaceData LandSpeedFwdRightActionBS;

	UPROPERTY(Category = "Turn180")
	FHazePlaySequenceData Turn180LeftFoot;

	UPROPERTY(Category = "Turn180")
	FHazePlaySequenceData Turn180RightFoot;

	UPROPERTY(Category = "Turn180")
	FHazePlaySequenceData SprintTurn180LeftFoot;

	UPROPERTY(Category = "Turn180")
	FHazePlaySequenceData SprintTurn180RightFoot;

	// UPROPERTY(Category = "Landing")
	// float LandHighThreshold = 1000;

	UPROPERTY(Category = "Action")
	FHazePlayBlendSpaceData LandStillLeftActionBS;

	UPROPERTY(Category = "Action")
	FHazePlayBlendSpaceData LandHighStillLeftActionBS;

	UPROPERTY(Category = "Action")
	FHazePlayBlendSpaceData LandStillRightActionBS;

	UPROPERTY(Category = "Action")
	FHazePlayBlendSpaceData LandHighStillRightActionBS;

	

}


class ULocomotionFeatureLanding : UHazeLocomotionFeatureBase
{
	default Tag = n"Landing";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureLandingAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph

	UPROPERTY(Category = "Action")
	bool bUseActionMH = false;

	UPROPERTY(Category = "Timers")
	float LandHighThreshold;

	default LandHighThreshold = 1500;
}

enum EHazeLandingAnimationType

{
	LandStill,
	LandStillHigh,
	LandJog,
	LandJogHigh,
	StartFromStill,
	StartFromStillHigh,

}