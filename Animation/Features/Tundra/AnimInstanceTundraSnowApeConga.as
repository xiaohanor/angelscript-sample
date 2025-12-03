enum ECongaSnowApeState
{
	Idle,
	Dancing,
};

class UAnimInstanceSnowApeConga : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayRndSequenceData Idle;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData IdleWithinRange;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayRndSequenceData Entering;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayRndSequenceData Dispersing;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Dance;

    UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Pose1;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Pose2;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Pose3;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Pose4;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayRndSequenceData WalkPose1;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayRndSequenceData WalkPose2;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData WalkPose3;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData WalkPose4;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Stumble;

	// Variables

	UPROPERTY()
	bool bIsIdling;

	UPROPERTY()
	bool bIsWithinRange;

	UPROPERTY()
	bool bIsEntering;

	UPROPERTY()
	bool bIsDispersing;

	UPROPERTY()
	bool bHasDispersed;

	UPROPERTY()
	bool bIsDancing;

	UPROPERTY()
	bool bIsPausing;

	UPROPERTY()
	bool bShouldStrikePose;

	UPROPERTY()
	bool bHitWall;

	UPROPERTY()
	bool bIsOnDanceFLoor;

	UPROPERTY()
	ECongaLineStrikePose PoseToStrike;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float PosePlayRate = 0.6;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int DisperseRandIndex = 0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int EnterRandIndex = 0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int PoseRandIndex = 0;

	bool PrevPose = false;

	UPROPERTY()
	ECongaSnowApeState SnowApeState;

	ACongaLineManager Manager;
	ACongaLineMonkey Monkey;

	UCongaLineStrikePoseComponent StrikePoseComp;
	UCongaLineDancerComponent DancerComp;

	// On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		PrevPose = false;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
		
		Manager = CongaLine::GetManager();
		Monkey = Cast<ACongaLineMonkey>(HazeOwningActor);

		DancerComp = UCongaLineDancerComponent::Get(HazeOwningActor);

		if(Game::Mio != nullptr)
			StrikePoseComp = UCongaLineStrikePoseComponent::Get(Game::Mio);
	}

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(HazeOwningActor == nullptr)
			return;
		if (Monkey == nullptr)
			return;

		if(Manager == nullptr)
		{
			Manager = CongaLine::GetManager();
			if(Manager == nullptr)
				return;
		}

		if(StrikePoseComp == nullptr)
		{
			if(Game::Mio == nullptr)
				return;

			StrikePoseComp = UCongaLineStrikePoseComponent::Get(Game::Mio);
			if(StrikePoseComp == nullptr)
				return;
		}

		bIsPausing = StrikePoseComp.IsStrikingPose();

		bIsIdling = DancerComp.CurrentState == ECongaLineDancerState::Idle;
		
		bHasDispersed = DancerComp.bHasDispersed;

		bHitWall = DancerComp.HasHitWall();

		bIsOnDanceFLoor = DancerComp.bIsOnDanceFloor;


		if(bIsIdling && CongaLine::IsCongaLineActive())
		{
			AHazePlayerCharacter Player = Monkey.GetClosestPlayerWithinReactionRange();
			bIsWithinRange = (Player != nullptr && (Player.IsMio() == (Monkey.ColorCode == EMonkeyColorCode::Mio)));
		}
		else
		{
			bIsWithinRange = false;
		}
		
		bool bPrevEnter = bIsEntering; 
		bIsEntering = DancerComp.CurrentState == ECongaLineDancerState::Entering;
		bIsDancing = DancerComp.CurrentState == ECongaLineDancerState::Dancing && !bIsPausing;

		if (bPrevEnter != bIsEntering)
			EnterRandIndex = Math::RandRange(0, 2);

		bool bPrevDisperse = bIsDispersing;
		bIsDispersing = DancerComp.CurrentState == ECongaLineDancerState::Dispersing;

		// if (PrevPose != Manager.IsStrikingPose())
		// {
		// 	PoseRandIndex = Math::RandRange(0, 2);
		// }
		PoseRandIndex = StrikePoseComp.RandomPoseAnimVariation;
		//Print("PoseRandIndex: " + PoseRandIndex, 0.f);

		if (bPrevDisperse != bIsDispersing)
			DisperseRandIndex = Math::RandRange(0, 3);

		if(StrikePoseComp.IsStrikingPose())
		{
			bShouldStrikePose = true;
			PoseToStrike = StrikePoseComp.CurrentPose;
		}
		else
		{
			bShouldStrikePose = false;
			PoseToStrike = ECongaLineStrikePose::None;
		}

		//GetAnimIntParam("CongaPoseIndex");
		//Print("CongaPoseIndex: " + GetAnimIntParam(n"CongaPoseIndex", false, 0), 0.f);

		if (bIsIdling || bIsEntering || bIsDispersing)
			SnowApeState = ECongaSnowApeState::Idle;
		else
			SnowApeState = ECongaSnowApeState::Dancing;

		//bIsDispersing = CongaComp.bShouldDisperse;
		//Print("bIsDispersing: " + bIsDispersing, 0.f);

        //bIsWalking = CongaLine::IsMoving();

		//PrevPose = Manager.IsStrikingPose();
	}
    
}