UFUNCTION(BlueprintCallable)
ACongaLineManager GetMonkeyCongaLineManager()
{
	return CongaLine::GetManager();
}

UFUNCTION(BlueprintCallable)
void StartMonkeyCongaLine()
{
	CongaLine::GetManager().Activate();
	CongaLine::GetDanceFloor().InitiateMonkeyConga();
}

UFUNCTION(BlueprintCallable)
void StopMonkeyCongaLine()
{
	CongaLine::GetManager().Deactivate();
}

UFUNCTION(BlueprintCallable)
void IgnoreCollisions()
{
	CongaLine::GetManager().bShouldCollide = false;
}

namespace CongaLine
{
	ACongaLineManager GetManager()
	{
		return TListedActors<ACongaLineManager>().Single;
	}

	UFUNCTION(BlueprintPure)
	ACongaLineDanceFloor GetDanceFloor()
	{
		return TListedActors<ACongaLineDanceFloor>().Single;
	}

	bool IsSystemActive()
	{
		auto Manager = CongaLine::GetManager();
		if(Manager == nullptr)
			return false;

		return Manager.IsActive();
	}

	bool IsCongaLineActive()
	{
		if(!IsSystemActive())
			return false;

		auto CongaComp = CongaLine::GetPlayerComponent();
		if(CongaComp == nullptr)
			return false;
		
		return CongaComp.IsLeadingCongaLine();
	}


	UCongaLinePlayerComponent GetPlayerComponent()
	{
		return UCongaLinePlayerComponent::Get(Game::Mio);
	}

	UFUNCTION(BlueprintPure)
	float GetCurrentMeasureAlpha()
	{
		return CongaLine::GetManager().GetCurrentMeasureAlpha();
	}

	UFUNCTION(BlueprintPure)
	float GetExplicitTime(float Multiplier)
	{
		float BeatDuration = 60 / (CongaLine::BeatsPerMinute / Multiplier);
		float TimeInCurrentBeat = CongaLine::GetManager().GetActiveDuration() % (BeatDuration*2);
		float BeatAlpha = TimeInCurrentBeat / BeatDuration;
		return BeatAlpha;
	}
}