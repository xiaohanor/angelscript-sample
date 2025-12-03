struct FDanceShowdownMonkeyKingAnimData
{
	EDanceShowdownPose Pose;
	bool bIsFlourishing = false;
	bool bIsAngry = false;
	bool bMioFail = false;
	bool bZoeFail = false;
	float TempoMultiplier = DanceShowdown::GetTempoMultiplier(0);
}

class ADanceShowdownMonkeyKing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeOffsetComponent MeshOffsetComponent;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	UHazeCharacterSkeletalMeshComponent SkeletalMesh;

	EDanceShowdownPose CurrentPose = EDanceShowdownPose::None;

	FDanceShowdownMonkeyKingAnimData AnimData;

	UPROPERTY()
	UNiagaraSystem TelegraphVfx;

	UPROPERTY()
	UNiagaraSystem OnBeatVfx;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor Camera;

	uint SpawnedThrowableMonkeys = 0;

	bool bHasPlayedTelegraph = true;
	float NextTelegraphTime;

	ADanceShowdownManager DanceShowdownManager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DanceShowdownManager = DanceShowdown::GetManager();
		DanceShowdownManager.MonkeyKing = this;
		DanceShowdownManager.RhythmManager.OnBeatEvent.AddUFunction(this, n"OnBeat");
		DanceShowdownManager.PoseManager.OnPlayerFailedEvent.AddUFunction(this, n"ThrowMonkeyAtPlayer");
		DanceShowdownManager.ScoreManager.OnPerfectMeasure.AddUFunction(this, n"Flourish");
		DanceShowdownManager.FaceMonkeyManager.OnBothMonkeysRemovedEvent.AddUFunction(this, n"StopBeingAngry");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(DanceShowdown::DebugPoses.IsEnabled())
			Debug::DrawDebugString(ActorLocation, f"{DanceShowdownManager.PoseManager.CurrentPose:n}", Scale = 5);

		if(!bHasPlayedTelegraph)
		{
			if(Time::GetGameTimeSeconds() >= NextTelegraphTime)
			{
				Niagara::SpawnOneShotNiagaraSystemAtLocation(TelegraphVfx, ActorLocation);
				bHasPlayedTelegraph = true;
			}
		}
	}

	void SetNextTelegraphTime()
	{
		bHasPlayedTelegraph = false;
		UDanceShowdownRhythmManager RhythmManager = DanceShowdownManager.RhythmManager;
		const float BPM = RhythmManager.GetBPM();
		NextTelegraphTime = Time::GetGameTimeSeconds() + BPM / 60.0 - DanceShowdown::TelegraphFullDuration * (DanceShowdown::BeatsPerMinuteStageOne / BPM);
	}

	UFUNCTION(BlueprintCallable)
	void SetPose(EDanceShowdownPose Pose)
	{
		CurrentPose = Pose;
		AnimData.Pose = Pose;
		DanceShowdownManager.PoseManager.OnNewDisplayPoseEvent.Broadcast(Pose);
		if(Pose != EDanceShowdownPose::None && !DanceShowdownManager.PoseManager.bMeasureCanceled)
		{
			BP_UpdatePose(Pose);
		}
	}

	UFUNCTION(NetFunction)
	void NetSetPose(EDanceShowdownPose Pose)
	{
		SetPose(Pose);
	}


	UFUNCTION()
	private void StopBeingAngry(float Time)
	{
		AnimData.bIsAngry = false;
		CurrentPose = EDanceShowdownPose::None;
		AnimData.Pose = CurrentPose;
		AnimData.bMioFail = false;
		AnimData.bZoeFail = false;
	}

	UFUNCTION()
	private void Flourish()
	{
		AnimData.bIsFlourishing = true;
	}

	UFUNCTION(BlueprintCallable)
	void StopFlourishing()
	{
		AnimData.bIsFlourishing = false;
		DanceShowdownManager.OnStopFlourish.Broadcast();
	}


	private EDanceShowdownPose GenerateNewPose()
	{
		EDanceShowdownPose NewPose = EDanceShowdownPose(Math::RandRange(1, 4));

		// Make sure we don't play the same pose twice in a row
		while(CurrentPose == NewPose)
		{
			NewPose = EDanceShowdownPose(Math::RandRange(1, 4));
		}

		return NewPose;
	}
	
	UFUNCTION()
	private void OnBeat(FDanceShowdownOnBeatEventData Data)
	{
		if(AnimData.bIsFlourishing)
			StopFlourishing();
		
		Niagara::SpawnOneShotNiagaraSystemAtLocation(OnBeatVfx, ActorLocation + -ActorForwardVector * 200);
		if(!Data.IsFirstBeat() && !Data.bIsRestMeasure)
		{
			SetNextTelegraphTime();
		}

		if(Data.bIsRestMeasure && DanceShowdownManager.RhythmManager.IsLastBeat())
		{
			FDanceShowdownLastBeatEvent EventData;
			EventData.Stage = DanceShowdownManager.RhythmManager.GetCurrentStage();
			UDanceShowdownEventHandler::Trigger_OnLastBeat(DanceShowdownManager, EventData);
		}

		if(Data.bIsRestMeasure && DanceShowdownManager.RhythmManager.IsVfxAnticipationBeat())
		{
			UDanceShowdownEventHandler::Trigger_OnVFXAnticipation(DanceShowdownManager);
		}

		if(HasControl())
		{
			if(Data.bIsRestMeasure)
			{
				if(Data.IsFirstBeat())
				{
					NetSetPose(EDanceShowdownPose::None);
				}
				return;
			}

			EDanceShowdownPose NewPose = GenerateNewPose();
			NetSetPose(NewPose);
			DanceShowdownManager.PoseManager.NetSetNextPose(NewPose, Data.IsFirstBeat());
		}
		
	}

	UFUNCTION(BlueprintCallable, BlueprintEvent)
	void BP_ShowNewMoveset(){}

	UFUNCTION(BlueprintCallable, BlueprintEvent)
	void BP_UpdatePose(EDanceShowdownPose NewPose){};

	UFUNCTION()
	private void ThrowMonkeyAtPlayer(UDanceShowdownPlayerComponent Player)
	{
		CurrentPose = EDanceShowdownPose::None;
		AnimData.Pose = CurrentPose;
		AnimData.bIsAngry = true;

		if(Player.Player.IsMio())
			AnimData.bMioFail = true;
		else
			AnimData.bZoeFail = true;
	}

	void GrabMonkey(AHazePlayerCharacter Player)
	{
		if(!HasControl())
			return;

		auto Monkey = DanceShowdown::GetManager().FaceMonkeyManager.GetMonkeyForPlayer(Player);
		Monkey.SetTargetPlayer(Player);
		Monkey.State = EThrowableMonkeyState::Grabbed;
	}

	void ThrowMonkey(AHazePlayerCharacter Player)
	{
		if(!HasControl())
			return;

		auto Monkey = DanceShowdown::GetManager().FaceMonkeyManager.GetMonkeyForPlayer(Player);
		Monkey.State = EThrowableMonkeyState::Thrown;
	}
};