struct FDanceShowdownPlayerAnimData
{
	EDanceShowdownPose Pose;
	float TempoMultiplier = DanceShowdown::GetTempoMultiplier(0);
	bool bHasMonkeyOnFace = false;
	bool bSuccess = false;
	bool bFail = false;
	FVector2D StickInput;
}

struct FDanceShowdownPoseData
{
	UPROPERTY()
	EDanceShowdownPose Pose;

	FDanceShowdownPoseData(EDanceShowdownPose InPose)
	{
		Pose = InPose;
	}
}

class UDanceShowdownPlayerComponent : UActorComponent
{

	UPROPERTY()
	TSubclassOf<UDanceShowdownWidget> WidgetClass;

	UDanceShowdownWidget Widget;

	UPROPERTY()
	UForceFeedbackEffect BeatForceFeedback;

	UPROPERTY()
	UForceFeedbackEffect SuccessForceFeedback;

	UPROPERTY()
	UForceFeedbackEffect FailedForceFeedback;

	UPROPERTY()
	UForceFeedbackEffect MonkeyOnFaceForceFeedback;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> MonkeyOnFaceCameraShake;

	UPROPERTY()
	TPerPlayer<FVector> FaceMonkeyWidgetOffset;

	UPROPERTY()
	TArray<FHazePlayOverrideAnimationParams> SuccessAnimsMio;

	UPROPERTY()
	TArray<FHazePlayOverrideAnimationParams> SuccessAnimsZoe;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVector2DComponent SyncedStickWiggle;

	AHazePlayerCharacter Player;

	FDanceShowdownPlayerAnimData AnimData;

	private FVector2D Input;
	private FVector2D LastUpdatedInput;

	EDanceShowdownPose Pose;

	bool bIsSetup = false;
	bool bHasFailed = false;

	ADanceShowdownThrowableMonkey MonkeyOnFace;

	private UTundraPlayerShapeshiftingComponent ShapeshiftComp;


	float PlayCorrectPoseTime;
	bool bPlayCorrectPoseIndicator = false;
	const float PlayCorrectPoseIndicatorDelay = 0.1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SyncedStickWiggle = UHazeCrumbSyncedVector2DComponent::GetOrCreate(Owner, n"SyncedStickWiggle");
		DanceShowdown::GetManager().OnGameStartedEvent.AddUFunction(this, n"Setup");
		DanceShowdown::GetManager().PoseManager.OnPlayerFailedEvent.AddUFunction(this, n"OnFail");
		DanceShowdown::GetManager().PoseManager.OnBothPlayersSucceededEvent.AddUFunction(this, n"OnSuccess");
		DanceShowdown::GetManager().OnStopFlourish.AddUFunction(this, n"StopSuccess");
		DanceShowdown::GetManager().OnMonkeyRecovery.AddUFunction(this, n"StopFail");
		DanceShowdown::DebugPoses.MakeVisible();
	}

	UFUNCTION()
	private void OnFail(UDanceShowdownPlayerComponent InPlayer)
	{
		AnimData.bFail = true;
	}

	UFUNCTION()
	private void StopFail()
	{
		AnimData.bFail = false;
	}

	UFUNCTION()
	private void OnSuccess()
	{
		AnimData.bSuccess = true;
	}

	UFUNCTION()
	private void StopSuccess()
	{
		AnimData.bSuccess = false;
	}

	UFUNCTION(NetFunction)
	void NetSetNewPose(EDanceShowdownPose NewPose)
	{
		Pose = NewPose;
		AnimData.Pose = NewPose;

		auto TutorialManager = DanceShowdown::GetManager().TutorialManager;
		
		if(TutorialManager.bTutorialActive)
		{
			TutorialManager.NetSetPlayerPose(Player, Pose);
		}
		
		if(NewPose == DanceShowdown::GetManager().PoseManager.CurrentPose && NewPose != EDanceShowdownPose::None)
		{
			bPlayCorrectPoseIndicator = true;
			PlayCorrectPoseTime = Time::GameTimeSeconds + PlayCorrectPoseIndicatorDelay;
		}
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(DanceShowdown::DebugPoses.IsEnabled())
			Debug::DrawDebugString(Owner.ActorLocation, f"{Pose:n}", Scale = 5);

		AnimData.StickInput = SyncedStickWiggle.Value;
		if(!HasControl())
			return;

		if(!bIsSetup)
			return;

		EDanceShowdownPose NewPose;

		if(!DanceShowdown::bUseInputAutoAim ||Input.Distance(LastUpdatedInput) > 0.3 || Input.Size() <= 0.1)
		{
			NewPose = DanceShowdown::GetPoseFromInput(Input.X, Input.Y, DanceShowdown::bUseInputAutoAim);

			if(Pose != NewPose)
			{
				NetSetNewPose(NewPose);
				LastUpdatedInput = Input;
			}
		}
	}

	UFUNCTION()
	private void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		Widget = Game::GetMio().AddWidget(WidgetClass);
		Widget.DanceShowdownComp = this;


		if(Player.IsMio())
		{
			Widget.ConfigureWidgetMio();
			DanceShowdown::GetManager().PoseManager.Mio = this;
		}
		else
		{
			Widget.ConfigureWidgetZoe();
			DanceShowdown::GetManager().PoseManager.Zoe = this;
		}

		DanceShowdown::GetManager().RhythmManager.OnBeatEvent.AddUFunction(this, n"OnBeat");
		bIsSetup = true;
	}

	UFUNCTION(NetFunction)
	void NetSuccess()
	{
		FDanceShowdownPlayerEventData Data;
		Data.Player = Player;
		UDanceShowdownPlayerEventHandler::Trigger_OnSuccess(GetPlayerShapeshiftActor(), Data);
		Widget.OnSucceeded();
		
		if(HasControl())
			Player.PlayForceFeedback(SuccessForceFeedback, false, true, this, 1);
	}

	void Fail()
	{
		FDanceShowdownPlayerEventData Data;
		Data.Player = Player;
		UDanceShowdownPlayerEventHandler::Trigger_OnFail(GetPlayerShapeshiftActor(), Data);
		Player.PlayForceFeedback(FailedForceFeedback, false, true, this, 1);
		Widget.OnFailed();
		bHasFailed = true;
	}

	void SetMonkeyOnFace(ADanceShowdownThrowableMonkey Monkey)
	{
		DanceShowdown::GetManager().FaceMonkeyManager.OnMonkeyHitPlayer.Broadcast();
		MonkeyOnFace = Monkey;
		AnimData.bHasMonkeyOnFace = true;
		Input = FVector2D::ZeroVector;
	}

	void RemoveMonkey(float Time)
	{
		if(MonkeyOnFace == nullptr)
			return;
		
		bHasFailed = false;
		AnimData.bHasMonkeyOnFace = false;
		DanceShowdown::GetManager().FaceMonkeyManager.RemoveMonkey(this, Time);
		MonkeyOnFace = nullptr;
	}

	UFUNCTION()
	private void OnBeat(FDanceShowdownOnBeatEventData EventData)
	{
		if(!HasControl())
			return;

		Player.PlayForceFeedback(BeatForceFeedback, false, true, this, 1);

		if(!EventData.bIsRestMeasure)
		{
			if(!EventData.IsFirstBeat())
			{
				DanceShowdown::GetManager().PoseManager.SubmitPose(this, Pose, false);
			}
		}
		else if(EventData.IsFirstBeat() && !EventData.IsFirstMeasure())
		{
			DanceShowdown::GetManager().PoseManager.SubmitPose(this, Pose, true);
		}
	}

	AHazeActor GetPlayerShapeshiftActor()
	{
		if(ShapeshiftComp == nullptr)
			ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Owner);

		return ShapeshiftComp.BigShapeComponent.GetShapeActor();
	}

	void UpdateInput(float X, float Y)
	{
		if(bHasFailed)
			return;

		if(X != 0 || Y != 0)
			Widget.HideTutorial();

		Input = FVector2D(X, Y);
	}

	void SetStickWiggleInput(FVector2D StickInput)
	{
		SyncedStickWiggle.Value = StickInput;
	}

	void ShowUI()
	{
		Widget.ShowWidget();
	}

	void HideUI()
	{
		Widget.HideWidget();
	}
};