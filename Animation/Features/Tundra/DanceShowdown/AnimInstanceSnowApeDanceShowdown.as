class UAnimInstanceSnowApeDanceShowdown : UHazeAnimInstanceBase
{
    UPROPERTY(BlueprintReadOnly, Category = "Generic")
    FHazePlayBlendSpaceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Generic")
	FHazePlayRndSequenceData Flourish;

	UPROPERTY(BlueprintReadOnly, Category = "Disco")
    FHazePlaySequenceData DiscoMh;

	UPROPERTY(BlueprintReadOnly, Category = "Disco")
    FHazePlaySequenceData DiscoPoseLeft;

	UPROPERTY(BlueprintReadOnly, Category = "Disco")
    FHazePlaySequenceData DiscoPoseRight;

	UPROPERTY(BlueprintReadOnly, Category = "Disco")
    FHazePlaySequenceData DiscoPoseUp;

	UPROPERTY(BlueprintReadOnly, Category = "Disco")
    FHazePlaySequenceData DiscoPoseDown;


	UPROPERTY(BlueprintReadOnly, Category = "Belly")
    FHazePlaySequenceData BellyMh;

	UPROPERTY(BlueprintReadOnly, Category = "Belly")
    FHazePlaySequenceData BellyPoseLeft;

	UPROPERTY(BlueprintReadOnly, Category = "Belly")
    FHazePlaySequenceData BellyPoseRight;

	UPROPERTY(BlueprintReadOnly, Category = "Belly")
    FHazePlaySequenceData BellyPoseUp;

	UPROPERTY(BlueprintReadOnly, Category = "Belly")
    FHazePlaySequenceData BellyPoseDown;

	
	UPROPERTY(BlueprintReadOnly, Category = "Break")
    FHazePlaySequenceData BreakMh;

	UPROPERTY(BlueprintReadOnly, Category = "Break")
    FHazePlaySequenceData BreakPoseLeft;

	UPROPERTY(BlueprintReadOnly, Category = "Break")
    FHazePlaySequenceData BreakPoseRight;

	UPROPERTY(BlueprintReadOnly, Category = "Break")
    FHazePlaySequenceData BreakPoseUp;

	UPROPERTY(BlueprintReadOnly, Category = "Break")
    FHazePlaySequenceData BreakPoseDown;


	UPROPERTY()
	EDanceShowdownPose PoseToStrike;

	UPROPERTY()
	bool bIsFlourishing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int StageNumber;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ExplicitTime;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int RandomMhInt = 0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float BreakPlayRate = 1.2;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTutorialActive = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bChangedPose;

    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
        
    }

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(HazeOwningActor == nullptr)
			return;
		if (!HazeOwningActor.HasActorBegunPlay())
			return;

		if(DanceShowdown::GetManager() == nullptr)
			return;
		
		auto AnimData = DanceShowdown::GetManager().MonkeyKing.AnimData;
		bChangedPose = PoseToStrike != AnimData.Pose;
		PoseToStrike = AnimData.Pose;
		bIsFlourishing = AnimData.bIsFlourishing;
		StageNumber = DanceShowdown::GetManager().RhythmManager.GetCurrentStage();
		ExplicitTime = DanceShowdown::GetManager().RhythmManager.GetExplicitTime();
		
		bTutorialActive = DanceShowdown::GetManager().TutorialManager.bTutorialActive;

		RandomMhInt = DanceShowdown::GetManager().RhythmManager.IdleAnimationIndex;
    }
    
}