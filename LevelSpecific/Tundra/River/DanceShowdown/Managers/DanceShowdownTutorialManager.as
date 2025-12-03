struct FDanceShowdownTutorialPlayerPoses
{
	TArray<EDanceShowdownPose> Poses;
}

class UDanceShowdownTutorialManager : UActorComponent
{
	default ComponentTickEnabled = false;

	UPROPERTY()
	FDanceShowdownNoParamsEvent OnTutorialComplete;

	bool bTutorialActive = false;
	bool bTutorialStarted = false;

	TPerPlayer<FDanceShowdownTutorialPlayerPoses> PlayerPoses;

	float TutorialStartTime;

	float MinimumTime = 3;
	float MaximumTime = 10;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DanceShowdown::SkipTutorial.MakeVisible();
		SetComponentTickEnabled(false);
	}

	UFUNCTION(NetFunction)
	void NetSetPlayerPose(AHazePlayerCharacter Player, EDanceShowdownPose Pose)
	{
		if(Pose == EDanceShowdownPose::None)
			return;
		
		if(!PlayerPoses[Player].Poses.Contains(Pose))
		{
			UDanceShowdownPlayerEventHandler::Trigger_OnTutorialPoseEntered(UTundraPlayerShapeshiftingComponent::Get(Player).BigShapeComponent.GetShapeActor());
			PlayerPoses[Player].Poses.AddUnique(Pose);
		}
	}

	void StartTutorial()
	{
		SetComponentTickEnabled(true);
		TutorialStartTime = Time::GameTimeSeconds;
		bTutorialActive = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bTutorialActive)
			return;
		
		if(Time::GetGameTimeSince(TutorialStartTime) < MinimumTime)
			return;

		if(Time::GetGameTimeSince(TutorialStartTime) > MaximumTime)
		{
			EndTutorial();
			return;
		}

		for(auto ItPlayer : Game::Players)
		{
			if(PlayerPoses[ItPlayer].Poses.Num() < 3)
				return;
		}

		EndTutorial();
	}

	void EndTutorial()
	{
		bTutorialActive = false;
		OnTutorialComplete.Broadcast();
		SetComponentTickEnabled(false);
	}
};