enum EDesertLevelState
{
	None,
	Vortex,
	Climb,
	Steer,
	Fall,
}

event void FDesertLevelStatedChanged(EDesertLevelState NewLevelState);

class UDesertManagerComponent : UActorComponent
{
	TArray<UDesertLandscapeComponent> Landscapes;
	TMap<ESandSharkLandscapeLevel, UDesertLandscapeComponent> LandscapesByLevel;

	// Sandfish
	private EDesertLevelState LevelState = EDesertLevelState::None;
	private EDesertLevelState ProgressPointLevelState = EDesertLevelState::None;

	private ESandSharkLandscapeLevel RelevantLandscapeLevel = ESandSharkLandscapeLevel::Lower;

	UPROPERTY()
	FDesertLevelStatedChanged OnLevelStateChanged;

	// Vortex
	AVortexSandFish VortexSandfish;
    TArray<AVortexSandFishBreakablePillar> Pillars;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		GetTemporalLog().Value("Desert Level State", LevelState);
	}
#endif

	void SetRelevantLandscapeLevel(ESandSharkLandscapeLevel NewLandscapeLevel)
	{
		RelevantLandscapeLevel = NewLandscapeLevel;
	}

	ESandSharkLandscapeLevel GetRelevantLandscapeLevel()
	{
		return RelevantLandscapeLevel;
	}

	void SetLevelState(EDesertLevelState InLevelState, bool bIsProgressPoint)
	{
		if(LevelState == InLevelState)
			return;

		if(bIsProgressPoint)
		{
			LevelState = InLevelState;
			ProgressPointLevelState = InLevelState;
		}
		else if(HasControl())
		{
			CrumbSetLevelStateNoProgressPoint(InLevelState);
		}

#if EDITOR
		GetTemporalLog().Event("Desert Level State Changed");
#endif
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSetLevelStateNoProgressPoint(EDesertLevelState InLevelState)
	{
		LevelState = InLevelState;
		OnLevelStateChanged.Broadcast(InLevelState);
	}

	EDesertLevelState GetLevelState() const
	{
		return LevelState;
	}

	EDesertLevelState GetProgressPointLevelState() const
	{
		return ProgressPointLevelState;
	}

#if EDITOR
	FTemporalLog GetTemporalLog() const
	{
		return TEMPORAL_LOG("DesertManager");
	}
#endif
};