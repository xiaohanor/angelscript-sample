struct FLocomotionFeaturePrisonGuardAnimData
{
	UPROPERTY(Category = "PrisonGuard")
	FHazePlaySequenceData MH;


	UPROPERTY(Category = "PrisonGuard|Walk")
	FHazePlaySequenceData WalkStart;

	UPROPERTY(Category = "PrisonGuard|Walk")
	FHazePlaySequenceData Walk1;

	UPROPERTY(Category = "PrisonGuard|Walk")
	FHazePlaySequenceData Walk2;

	UPROPERTY(Category = "PrisonGuard|Walk")
	FHazePlaySequenceData Walk3;

	UPROPERTY(Category = "PrisonGuard|Walk")
	FHazePlaySequenceData Walk4;

	UPROPERTY(Category = "PrisonGuard|Walk")
	FHazePlaySequenceData WalkStop1;

	UPROPERTY(Category = "PrisonGuard|Walk")
	FHazePlaySequenceData WalkStop2;

	UPROPERTY(Category = "PrisonGuard|Walk")
	FHazePlaySequenceData WalkStop3;

	UPROPERTY(Category = "PrisonGuard|Walk")
	FHazePlaySequenceData WalkStop4;


	UPROPERTY(Category = "PrisonGuard|Turns")
	FHazePlaySequenceData TurnLeft45;

	UPROPERTY(Category = "PrisonGuard|Turns")
	FHazePlaySequenceData TurnLeft90;

	UPROPERTY(Category = "PrisonGuard|Turns")
	FHazePlaySequenceData TurnLeft135;

	UPROPERTY(Category = "PrisonGuard|Turns")
	FHazePlaySequenceData TurnLeft180;

	UPROPERTY(Category = "PrisonGuard|Turns")
	FHazePlaySequenceData TurnRight45;

	UPROPERTY(Category = "PrisonGuard|Turns")
	FHazePlaySequenceData TurnRight90;

	UPROPERTY(Category = "PrisonGuard|Turns")
	FHazePlaySequenceData TurnRight135;

	UPROPERTY(Category = "PrisonGuard|Turns")
	FHazePlaySequenceData TurnRight180;


	UPROPERTY(Category = "PrisonGuard|Attack")
	FHazePlaySequenceData Attack;


	UPROPERTY(Category = "PrisonGuard|Stunned")
	FHazePlaySequenceData StunnedEnter;

	UPROPERTY(Category = "PrisonGuard|Stunned")
	FHazePlaySequenceData StunnedMH;

	UPROPERTY(Category = "PrisonGuard|Stunned")
	FHazePlaySequenceData StunnedExit;

}

class ULocomotionFeaturePrisonGuard : UHazeLocomotionFeatureBase
{
	default Tag = n"PrisonGuard";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeaturePrisonGuardAnimData AnimData;
}
