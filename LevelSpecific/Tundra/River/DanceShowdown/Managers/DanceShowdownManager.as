event void FDanceShowdownNoParamsEvent();
event void FDanceShowdownStageAdanceEvent(int Stage);
event void FDanceShowdownStageStartedEvent(int Stage);

struct FDanceShowdownNewMeasureData
{
	int Stage;
}


UCLASS(Abstract)
class ADanceShowdownManager : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UDanceShowdownPoseManager PoseManager;
	
	UPROPERTY(DefaultComponent)
	UDanceShowdownRhythmManager RhythmManager;

	UPROPERTY(DefaultComponent)
	UDanceShowdownScoreManager ScoreManager;

	UPROPERTY(DefaultComponent)
	UDanceShowdownCameraManager CameraManager;

	UPROPERTY(DefaultComponent)
	UDanceShowdownFaceMonkeyManager FaceMonkeyManager;

	UPROPERTY(DefaultComponent)
	UDanceShowdownTutorialManager TutorialManager;

	UPROPERTY(DefaultComponent)
	UDanceShowdownCrowdMonkeyManager CrowdMonkeyManager;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;

	UPROPERTY()
	FDanceShowdownNoParamsEvent OnGameStartedEvent;

	UPROPERTY()
	FDanceShowdownNoParamsEvent OnGameEndedEvent;

	UPROPERTY()
	FDanceShowdownNoParamsEvent OnPlayerSuccess;

	UPROPERTY()
	FDanceShowdownNoParamsEvent OnPlayerFail;

	UPROPERTY()
	FDanceShowdownNoParamsEvent OnMonkeyRecovery;

	UPROPERTY()
	FDanceShowdownStageAdanceEvent OnStageAdvancedEvent;

	UPROPERTY()
	FDanceShowdownStageStartedEvent OnStageStartedEvent;

	UPROPERTY()
	FDanceShowdownNoParamsEvent OnMonkeyKingMovesetShownEvent;

	UPROPERTY()
	FDanceShowdownNoParamsEvent OnStopFlourish;
	
	//Added by Johannes to bind to event in VO sounddef
	UPROPERTY()
	FDanceShowdownNoParamsEvent OnMainGameStartedEvent;

	ADanceShowdownMonkeyKing MonkeyKing;

	private bool bIsActive = false;

	UFUNCTION(BlueprintCallable)
	void StartDanceShowdown()
	{
		RhythmManager.SetExplicitTimeStart();
		RequestCapabilityComp.StartInitialSheetsAndCapabilities(Game::GetMio(), this);
		RequestCapabilityComp.StartInitialSheetsAndCapabilities(Game::GetZoe(),this );
		OnGameStartedEvent.Broadcast();
		bIsActive = true;

		if(DanceShowdown::SkipTutorial.IsEnabled())
			StartMainGame();
		else
			TutorialManager.StartTutorial();

	// VO needs events from players
		auto MonkeyActor = UTundraPlayerShapeshiftingComponent::Get(Game::GetMio()).BigShapeComponent.GetShapeActor();
		auto Treeguardian = UTundraPlayerShapeshiftingComponent::Get(Game::GetZoe()).BigShapeComponent.GetShapeActor();
		EffectEvent::LinkActorToReceiveEffectEventsFrom(this, MonkeyActor);
		EffectEvent::LinkActorToReceiveEffectEventsFrom(this, Treeguardian);

	}

	UFUNCTION(BlueprintCallable)
	void StartMainGame()
	{
		RhythmManager.Activate();
		OnMainGameStartedEvent.Broadcast();

		FaceMonkeyManager.RaisePillars();
		OnMonkeyKingMovesetShownEvent.AddUFunction(FaceMonkeyManager, n"RaisePillars");
	}

	void StopDanceShowdown()
	{
		RequestCapabilityComp.StopInitialSheetsAndCapabilities(Game::GetMio(), this);
		RequestCapabilityComp.StopInitialSheetsAndCapabilities(Game::GetZoe(), this);
		OnGameEndedEvent.Broadcast();
		RhythmManager.Deactivate();
		bIsActive = false;
	}

	bool IsActive() const
	{
		return bIsActive;
	}

	UFUNCTION(BlueprintPure)
	void GetDanceShowdownStage(int&out CurrentStage)
	{
		CurrentStage = RhythmManager.GetCurrentStage();
	}
}