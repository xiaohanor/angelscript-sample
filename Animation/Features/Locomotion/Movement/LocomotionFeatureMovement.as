struct FLocomotionFeatureMovementAnimData
{
	UPROPERTY(BlueprintReadOnly, Category = "Mh")
    FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Mh")
    FHazePlaySequenceData RelaxedMh;

	UPROPERTY(BlueprintReadOnly, Category = "Mh")
    FHazePlaySequenceData ActionMh;

	UPROPERTY(BlueprintReadOnly, Category = "Mh")
    FHazePlaySequenceData IdleToRelaxed;

	UPROPERTY(BlueprintReadOnly, Category = "Mh")
    FHazePlaySequenceData RelaxedToIdle;

	UPROPERTY(BlueprintReadOnly, Category = "Mh")
    FHazePlaySequenceData IdleToAction;

	UPROPERTY(BlueprintReadOnly, Category = "Mh")
    FHazePlaySequenceData ActionToIdle;

	UPROPERTY(BlueprintReadOnly, Category = "AFKIdle")
    FHazePlaySequenceData AFKIdleEnter;

	UPROPERTY(BlueprintReadOnly, Category = "AFKIdle")
    FHazePlaySequenceData AFKIdleMH;


	UPROPERTY(BlueprintReadOnly, Category = "Walk")
	FHazePlayBlendSpaceData WalkBS;

	UPROPERTY(BlueprintReadOnly, Category = "Walk")
	FHazePlayBlendSpaceData WalkStartBS;

	UPROPERTY(BlueprintReadOnly, Category = "Walk")
	FHazePlayBlendSpaceData WalkStopBS;


	UPROPERTY(BlueprintReadOnly, Category = "Jog")
	FHazePlayBlendSpaceData JogBS;

	UPROPERTY(BlueprintReadOnly, Category = "Jog")
	FHazePlayBlendSpaceData JogStartBS;

	UPROPERTY(BlueprintReadOnly, Category = "Jog")
	FHazePlaySequenceData JogStart;

	UPROPERTY(BlueprintReadOnly, Category = "Jog")
	FHazePlayBlendSpaceData JogStopBS;

	UPROPERTY(BlueprintReadOnly, Category = "Jog")
	FHazePlaySequenceData JogStopEasy;

	UPROPERTY(BlueprintReadOnly, Category = "Jog")
	FHazePlaySequenceData JogStopSlowdown;


	UPROPERTY(BlueprintReadOnly, Category = "Run")
	FHazePlayBlendSpaceData RunBS;

	UPROPERTY(BlueprintReadOnly, Category = "Run")
	FHazePlayBlendSpaceData RunStartBS;

	UPROPERTY(BlueprintReadOnly, Category = "Run")
	FHazePlayBlendSpaceData RunStopBS;

	UPROPERTY(BlueprintReadOnly, Category = "Sprint")
	FHazePlayBlendSpaceData Sprint;

	UPROPERTY(BlueprintReadOnly, Category = "Sprint|Starts")
	FHazePlayBlendSpaceData SprintStartLeftFoot;

	UPROPERTY(BlueprintReadOnly, Category = "Sprint|Starts")
	FHazePlayBlendSpaceData SprintStartRightFoot;

	UPROPERTY(BlueprintReadOnly, Category = "Sprint|Stops")
	FHazePlayBlendSpaceData SprintStopLeftFoot;
	
	UPROPERTY(BlueprintReadOnly, Category = "Sprint|Stops")
	FHazePlayBlendSpaceData SprintStopRightFoot;


	

	UPROPERTY(BlueprintReadOnly, Category = "Additional")
	FHazePlayBlendSpaceData AdditiveBanking;
	
	UPROPERTY(BlueprintReadOnly, Category = "TurnAround")
	FHazePlaySequenceData RunTurn180LeftFoot;

	UPROPERTY(BlueprintReadOnly, Category = "TurnAround")
	FHazePlaySequenceData RunTurn180RightFoot;

	UPROPERTY(BlueprintReadOnly, Category = "TurnAround")
	FHazePlaySequenceData SprintTurn180LeftFoot;

	UPROPERTY(BlueprintReadOnly, Category = "TurnAround")
	FHazePlaySequenceData SprintTurn180RightFoot;

	UPROPERTY(BlueprintReadOnly, Category = "TurnAround")
	FHazePlayBlendSpaceData SprintTurn180LeftFootBS;

	UPROPERTY(BlueprintReadOnly, Category = "TurnAround")
	FHazePlayBlendSpaceData SprintTurn180RightFootBS;


	UPROPERTY(BlueprintReadOnly, Category = "Action")
	FHazePlayBlendSpaceData ActionWalkStartBS;

	UPROPERTY(BlueprintReadOnly, Category = "Action")
	FHazePlayBlendSpaceData ActionWalkStopBS;

	UPROPERTY(BlueprintReadOnly, Category = "Action")
	FHazePlayBlendSpaceData ActionJogStartBS;

	UPROPERTY(BlueprintReadOnly, Category = "Action")
	FHazePlayBlendSpaceData ActionJogStopBS;

	UPROPERTY(BlueprintReadOnly, Category = "Action")
	FHazePlayBlendSpaceData ActionRunStartBS;

	UPROPERTY(BlueprintReadOnly, Category = "Action")
	FHazePlayBlendSpaceData ActionRunStopBS;

	UPROPERTY(BlueprintReadOnly, Category = "Action")
	FHazePlayBlendSpaceData ActionSprintStopLeftFoot;

	UPROPERTY(BlueprintReadOnly, Category = "Action")
	FHazePlayBlendSpaceData ActionSprintStopRightFoot;

	UPROPERTY(BlueprintReadOnly, Category = "Balance")
	FHazePlayBlendSpaceData CounterbalanceMH_BS;
	
	UPROPERTY(BlueprintReadOnly, Category = "Balance")
	FHazePlayBlendSpaceData UnstableMH_BS;

	UPROPERTY(BlueprintReadOnly, Category = "LookAt")
	float LookAtAlpha = 1;
}

class ULocomotionFeatureMovement : UHazeLocomotionFeatureBase
{
	default Tag = n"Movement";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureMovementAnimData AnimData;

	UPROPERTY(Category = "Action")
	bool bUseActionMH = false;

	//This is the value our ActionTimerScore needs to pass for ActionStates to be valid 
	UPROPERTY(Category = "Timers")
	float ActionTimerThreshold = 10;

	UPROPERTY(Category = "Timers")
	FHazeRange RelaxTimeRange;

	default RelaxTimeRange.Min = 10;
	default RelaxTimeRange.Max = 20;

	UPROPERTY(Category = "Timers")
	FHazeRange AFKIdleTimeRange;
	
	default AFKIdleTimeRange.Min = 60;
	default AFKIdleTimeRange.Max = 80;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}

enum EHazeIdleAnimationType
{
	MH,
	RelaxedMH,
	ActionMH,
	AFKIdle,
};