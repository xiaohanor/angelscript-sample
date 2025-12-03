//event void FDanceShowdownOnScoreChangedEvent(float NewScore);
event void FDanceShowdownOnScoreChangedEvent(int Score);
event void FDanceShowdownOnPerfectMeasureEvent();

class UDanceShowdownScoreManager : UActorComponent
{
	private int Score = 0;

 	FDanceShowdownOnScoreChangedEvent OnScoreChanged;
 	FDanceShowdownOnPerfectMeasureEvent OnPerfectMeasure;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DanceShowdown::IgnoreZoeScore.MakeVisible();
		DanceShowdown::NoFail.MakeVisible();
		DanceShowdown::DontIncreaseScore.MakeVisible();
	}

	int GetScore() const
	{
		return Score;
	}

	void IncreaseScore()
	{
		if(DanceShowdown::DontIncreaseScore.IsEnabled())
			return;

		Score++;
		Score = Math::Clamp(Score, 0, DanceShowdown::AmountOfScoreRequired);

		FDanceShowdownSequenceSucceededEvent EventData;
		EventData.SequencesCompleted = Score;
		UDanceShowdownEventHandler::Trigger_OnSequenceSucceeded(DanceShowdown::GetManager(), EventData);

		NetSetScore(Score, true);
	}

	UFUNCTION(NetFunction)
	private void NetSetScore(int NewScore, bool bPerfectMeasure)
	{
		Score = NewScore;

		if(Score == DanceShowdown::AmountOfScoreRequired)
		{
			if(HasControl())
				DanceShowdown::GetManager().RhythmManager.NetIncreaseStage();
		}

		OnScoreChanged.Broadcast(Score);

		if(bPerfectMeasure)
		{
			OnPerfectMeasure.Broadcast();
			DanceShowdown::GetManager().OnPlayerSuccess.Broadcast();
		}
	}

	void ResetScore()
	{
		if(!HasControl())
			return;

		NetSetScore(0, false);
	}


#if EDITOR

	UFUNCTION(DevFunction)
	void NextStage()
	{
		if(!HasControl())
			return;
		
		DanceShowdown::GetManager().RhythmManager.NetIncreaseStage();
	}


	UFUNCTION(DevFunction)
	void WinGame()
	{		
		DanceShowdown::GetManager().RhythmManager.StopDanceShowdown();
	}
#endif

};