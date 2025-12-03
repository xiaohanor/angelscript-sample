namespace DanceShowdown
{
	ADanceShowdownManager GetManager()
	{
		return TListedActors<ADanceShowdownManager>().Single;
	}

	float GetTempoMultiplier(int Stage)
	{
		switch(Stage)
		{
			case 0: return DanceShowdown::BeatsPerMinuteStageOne / 60.0;
			case 1: return DanceShowdown::BeatsPerMinuteStageTwo / 60.0;
			case 2: return DanceShowdown::BeatsPerMinuteStageThree / 60.0;
		}
		
		return 1;
	}
}

UFUNCTION(BlueprintPure)
ADanceShowdownManager GetDanceShowdownManager()
{
	return DanceShowdown::GetManager();
}

UFUNCTION(BlueprintPure)
float GetCurrentMeasureAlpha()
{
	if(GetDanceShowdownManager() == nullptr)
		return 0;

	return GetDanceShowdownManager().RhythmManager.GetCurrentMeasureAlpha();
}

UFUNCTION(BlueprintPure)
float GetCurrentBeatAlpha()
{
	if(GetDanceShowdownManager() == nullptr)
		return 0;

	return GetDanceShowdownManager().RhythmManager.GetBeatAlpha();
}


UFUNCTION(BlueprintPure)
bool IsRestMeasure()
{
	if(GetDanceShowdownManager() == nullptr)
		return true;

	return GetDanceShowdownManager().RhythmManager.IsRestMeasure();
}

UFUNCTION(BlueprintPure)
float GetVisualScore()
{
	return 0;
	//return DanceShowdown::GetManager().ScoreManager.GetVisualScore();
}

UFUNCTION(BlueprintCallable)
void Unpause()
{
	DanceShowdown::GetManager().RhythmManager.Unpause(Time::RealTimeSeconds);
}

UFUNCTION(DevFunction)
void HideUI()
{
	UDanceShowdownPlayerComponent::Get(Game::GetMio()).Widget.HideUI();
	UDanceShowdownPlayerComponent::Get(Game::GetZoe()).Widget.HideUI();
}
