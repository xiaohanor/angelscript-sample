enum ELiftSectionLevelState
{
	None,
	Roller,
	Crush,
	SpongeThing,
	PowerWashTracker,
	Fan,
	Alarm,
	TiltSequence,
	WingChop,
	Thruster,
	HoleInWall,
	TurretLaserWingChop,
	Outro
}

event void FLiftSectionLevelStatedEvent(ELiftSectionLevelState LevelState);

class ULiftSectionManagerComponent : UActorComponent
{
	UPROPERTY(BlueprintReadWrite)
	FLiftSectionLevelStatedEvent OnLevelStateChanged;

	UPROPERTY(BlueprintReadWrite)
	FLiftSectionLevelStatedEvent OnLevelStateDone;

	private ELiftSectionLevelState LevelState = ELiftSectionLevelState::None;
	private TArray<FInstigator> LevelStateSourcesDoingStuff;

	private bool bIsGameNetworked = false;
	private bool bControllerDone = false;
	private bool bRemoteDone = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bIsGameNetworked = Network::IsGameNetworked();
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		GetTemporalLog().Value("Lift Section Level State", LevelState);
	}
#endif

	void AddLevelStateInstigatorDoingStuff(FInstigator Source)
	{
		LevelStateSourcesDoingStuff.Add(Source);
		TemporalLog("Lift Section Actor Doing Stuff: " + Source.ToString());
	}

	void RemoveLevelStateInstigatorDoingStuff(FInstigator Source)
	{
		LevelStateSourcesDoingStuff.Remove(Source);
		TemporalLog("Lift Section Actor Stopped Doing Stuff: " + Source.ToString());

		if (LevelStateSourcesDoingStuff.Num() == 0)
		{
			SetLevelStateDone(LevelState);
		}
	}

	void SetInLevelState(ELiftSectionLevelState InLevelState)
	{
		if (InLevelState != ELiftSectionLevelState::None && LevelState == InLevelState)
			return; 
		
		if (HasControl())
			CrumbChangeLevelState(InLevelState);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbChangeLevelState(ELiftSectionLevelState InLevelState)
	{
		ChangeLevelState(InLevelState);
	}

	private void ChangeLevelState(ELiftSectionLevelState InLevelState)
	{
		bControllerDone = false;
		bRemoteDone = !bIsGameNetworked;
		LevelState = InLevelState;
		OnLevelStateChanged.Broadcast(InLevelState);
		TemporalLog("LiftSection Level State Changed");
	}

	ELiftSectionLevelState GetLevelState() const
	{
		return LevelState;
	}

	void SetLevelStateDone(ELiftSectionLevelState InLevelState)
	{
		if (HasControl())
		{
			bControllerDone = true;
			if (bRemoteDone)
				CrumbDone();
		}
		else
		{
			CrumbRemoteDone(InLevelState);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbRemoteDone(ELiftSectionLevelState InLevelState)
	{
		if (InLevelState != LevelState)
		{
			TemporalLog("LiftSection Level States aren't synced properly o-o'");
			return;
		}
		bRemoteDone = true;
		if (HasControl() && bControllerDone)
		{
			CrumbDone();
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDone()
	{
		Done();
	}

	private void Done()
	{
		OnLevelStateDone.Broadcast(LevelState);
	}

	private void TemporalLog(FString Message)
	{
#if EDITOR
			GetTemporalLog().Event(Message);
#endif		
	}

#if EDITOR
	FTemporalLog GetTemporalLog() const
	{
		return TEMPORAL_LOG("LiftSectionManager");
	}
#endif

	void PrintAllDoingStuff() const
	{
		Print("Lift Section Doing Stuff:", 0.f);
		for (int i = 0; i < LevelStateSourcesDoingStuff.Num(); ++i) 
		{
			Print("" + LevelStateSourcesDoingStuff[i].ToString(), 0.f);
		}
	}
};