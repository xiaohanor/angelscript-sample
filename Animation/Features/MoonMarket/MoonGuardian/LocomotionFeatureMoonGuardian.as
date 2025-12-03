struct FLocomotionFeatureMoonGuardianAnimData
{
	UPROPERTY(Category = "MH")
	FHazePlayBlendSpaceData MH;
	UPROPERTY(Category = "")
	FHazePlaySequenceData HalfSleep;
	UPROPERTY(Category = "")
	FHazePlaySequenceData Sleep;
	UPROPERTY(Category = "")
	FHazePlaySequenceData Hiss;
	UPROPERTY(Category = "Transition")
	FHazePlaySequenceData MHToHalfSleep;
	UPROPERTY(Category = "Transition")
	FHazePlaySequenceData HalfSleepToSleep;
	UPROPERTY(Category = "Fail")
	FHazePlaySequenceData FootstepFail_HalfSleep;
	UPROPERTY(Category = "Fail")
	FHazePlaySequenceData FootstepFail_Sleep;
	UPROPERTY(Category = "Fail")
	FHazePlaySequenceData HarpFail_HalfSleep;
	UPROPERTY(Category = "Fail")
	FHazePlaySequenceData HarpFail_Sleep;
}

class ULocomotionFeatureMoonGuardian : UHazeLocomotionFeatureBase
{
	default Tag = n"MoonGuardian";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureMoonGuardianAnimData AnimData;
}
