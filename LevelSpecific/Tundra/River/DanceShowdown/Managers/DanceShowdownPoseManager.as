event void FDanceShowdownOnPlayerFailedEvent(UDanceShowdownPlayerComponent Player);
event void FDanceShowdownOnBothPlayersSucceededEvent();
event void FDanceShowdownOnNewPoseEvent(EDanceShowdownPose NewPose);
event void FDanceShowdownOnNewDisplayPoseEvent(EDanceShowdownPose NewPose);

class UDanceShowdownPoseManager : UActorComponent
{
	EDanceShowdownPose CurrentPose = EDanceShowdownPose::None;
	private EDanceShowdownPose NextPose;
	

	UDanceShowdownPlayerComponent Mio;
	UDanceShowdownPlayerComponent Zoe;

	FDanceShowdownOnPlayerFailedEvent OnPlayerFailedEvent;
	FDanceShowdownOnBothPlayersSucceededEvent OnBothPlayersSucceededEvent;
	FDanceShowdownOnNewPoseEvent OnNewPoseEvent;
	UPROPERTY()
	FDanceShowdownOnNewDisplayPoseEvent OnNewDisplayPoseEvent;

	int PlayersSubmitted = 0;
	bool bMeasureCanceled = false;


	UFUNCTION(NetFunction)
	void NetSetNextPose(EDanceShowdownPose Pose, bool bIsFirstBeat)
	{
		check(Pose != EDanceShowdownPose::None);

		NextPose = Pose;

		if(bIsFirstBeat)
		{
			bMeasureCanceled = false;
			SetPose(Pose);
		}
	}

	void SetPose(EDanceShowdownPose Pose)
	{
		CurrentPose = Pose;
		OnNewPoseEvent.Broadcast(CurrentPose);

		if(CurrentPose != EDanceShowdownPose::None)
		{
			FDanceShowdownNewPoseEvent EventData;
			EventData.Pose = CurrentPose;
			UDanceShowdownEventHandler::Trigger_OnPoseUpdated(DanceShowdown::GetManager(), EventData);
		}
	}

	void SubmitPose(UDanceShowdownPlayerComponent DanceComp, EDanceShowdownPose PlayerPose, bool bIsFinal)
	{		
		CheckPose(DanceComp, PlayerPose, bIsFinal);
	}

	UFUNCTION(NetFunction)
	void NetPlayerFailed(UDanceShowdownPlayerComponent DanceComp)
	{
		if(DanceShowdown::IgnoreZoeScore.IsEnabled() && DanceComp.Player.IsZoe())
			return;

		if(DanceShowdown::NoFail.IsEnabled())
			return;

		DanceComp.Fail();
		bMeasureCanceled = true;
		DanceShowdown::GetManager().RhythmManager.CancelMeasure();
		DanceShowdown::GetManager().RhythmManager.Pause();
		OnPlayerFailedEvent.Broadcast(DanceComp);
		DanceShowdown::GetManager().OnPlayerFail.Broadcast();
	}

	UFUNCTION(NetFunction)
	void NetIncreaseSubmittedPoseCount(bool bFinalBeat)
	{
		if(!HasControl())
			return;

		PlayersSubmitted += 1;
		if(PlayersSubmitted == 2)
		{
			CurrentPose = EDanceShowdownPose::None;

			if(!bMeasureCanceled && !bFinalBeat)
				NetUpdatePose(NextPose);
			else
				NetUpdatePose(CurrentPose);

			if(bFinalBeat)
			{
				if(!bMeasureCanceled)
				{
					NetBroadcastSuccessEvent();
					NextPose = EDanceShowdownPose::None;
					DanceShowdown::GetManager().ScoreManager.IncreaseScore();
				}

				bMeasureCanceled = false;
			}

			PlayersSubmitted = 0;
		}
	}

	UFUNCTION(NetFunction)
	void NetBroadcastSuccessEvent()
	{
		OnBothPlayersSucceededEvent.Broadcast();
	}

	UFUNCTION(NetFunction)
	void NetUpdatePose(EDanceShowdownPose NewPose)
	{
		SetPose(NewPose);
	}

	private void CheckPose(UDanceShowdownPlayerComponent DanceComp, EDanceShowdownPose PlayerPose, bool bFinalBeat)
	{
		if(CurrentPose == EDanceShowdownPose::None)
			return;
		
		if(PlayerPose == CurrentPose)
		{
			DanceComp.NetSuccess();
		}
		else
		{
			TEMPORAL_LOG(this).Event(DanceComp.Player.Name + " failed the pose. They submitted " + PlayerPose + " but the correct pose was " + CurrentPose);
			NetPlayerFailed(DanceComp);
		}
		
		NetIncreaseSubmittedPoseCount(bFinalBeat);
	}
};