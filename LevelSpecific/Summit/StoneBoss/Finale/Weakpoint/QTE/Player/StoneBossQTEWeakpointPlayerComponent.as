enum EPlayerStoneBossQTEWeakpointState
{
	Default,
	Charge,
	Ready,
	Syncing,
	Release,
	Success,
	Failure,
}

enum EPlayerStoneBossQTEWeakpointType
{
	Regular,
	Final
}

enum EPlayerStoneBossQTEFinalWeakpointStateInfo
{
	WeakpointStab,
	ButtonMashStab,
	ButtonMash,
	FinalStab
}

class UStoneBossQTEWeakpointPlayerComponent : UActorComponent
{
	access ReadOnly = private, *(readonly);

	UPROPERTY()
	EPlayerStoneBossQTEWeakpointState State;

	access:ReadOnly TInstigated<EPlayerStoneBossQTEWeakpointState> InstigatedState;

	const float DrawBackAlphaThreshold = 0.9;

	AStoneBossQTEWeakpoint Weakpoint;

	EPlayerStoneBossQTEWeakpointType WeakpointType;

	EPlayerStoneBossQTEFinalWeakpointStateInfo FinalWeakpointActiveStateInfo;

	UPROPERTY()
	float DrawBackAlpha = 0.0;

	AHazePlayerCharacter PlayerOwner;

	UStoneBossQTEWeakpointPlayerComponent OtherPlayerComponent;

	UButtonMashComponent ButtonMashComp;

	bool bHoldSuccessMH;

	bool bIsInsideStabWindow;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		ButtonMashComp = UButtonMashComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (OtherPlayerComponent == nullptr)
			OtherPlayerComponent = UStoneBossQTEWeakpointPlayerComponent::Get(PlayerOwner.OtherPlayer);

		if (Weakpoint == nullptr)
			return;

		State = InstigatedState.Get();

#if EDITOR
		auto TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Value("State", State);
		TemporalLog.Value("StateInstigator", InstigatedState.CurrentInstigator);
		TemporalLog.Value("Weakpoint", Weakpoint);
		TemporalLog.Value("WeakpointType", WeakpointType);
		TemporalLog.Value("FinalWeakpointStateInfo", FinalWeakpointActiveStateInfo);
		// TemporalLog.Value("HitSyncInfo", HitSyncInfo);
		TemporalLog.Value("DrawbackAlpha", DrawBackAlpha);

		if (OtherPlayerComponent != nullptr)
		{
			TemporalLog.Value("OtherPlayer;State", OtherPlayerComponent.State);
			TemporalLog.Value("OtherPlayer;StateInstigator", OtherPlayerComponent.InstigatedState.CurrentInstigator);
			TemporalLog.Value("OtherPlayer;Weakpoint", OtherPlayerComponent.Weakpoint);
			TemporalLog.Value("OtherPlayer;WeakpointType", OtherPlayerComponent.WeakpointType);
			TemporalLog.Value("OtherPlayer;FinalWeakpointStateInfo", OtherPlayerComponent.FinalWeakpointActiveStateInfo);
			// TemporalLog.Value("OtherPlayer;HitSyncInfo", OtherPlayerComponent.HitSyncInfo);
			TemporalLog.Value("OtherPlayer;DrawbackAlpha", OtherPlayerComponent.DrawBackAlpha);
		}
#endif
		if (FinalWeakpointActiveStateInfo == EPlayerStoneBossQTEFinalWeakpointStateInfo::FinalStab || FinalWeakpointActiveStateInfo == EPlayerStoneBossQTEFinalWeakpointStateInfo::WeakpointStab)
			return;

		if (ButtonMashComp.GetButtonMashProgress(Weakpoint.CurrentButtonMashInstigator) >= 0.5)
		{
			FinalWeakpointActiveStateInfo = EPlayerStoneBossQTEFinalWeakpointStateInfo::ButtonMash;
		}
		else
		{
			FinalWeakpointActiveStateInfo = EPlayerStoneBossQTEFinalWeakpointStateInfo::ButtonMashStab;
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbApplyInstigatedState(EPlayerStoneBossQTEWeakpointState NewState, FInstigator Instigator, EInstigatePriority Priority)
	{
		InstigatedState.Clear(Instigator);
		InstigatedState.Apply(NewState, Instigator, Priority);
	}

	UFUNCTION(CrumbFunction)
	void CrumbClearInstigatedState(FInstigator Instigator)
	{
		InstigatedState.Clear(Instigator);
	}

	void SetHoldSuccessAnim()
	{
		bHoldSuccessMH = true;
	}

	void ClearHoldSuccessAnim()
	{
		bHoldSuccessMH = false;
	}

	void SetActiveWeakpoint(AStoneBossQTEWeakpoint WeakpointTarget)
	{
		if (HasControl())
			CrumbSetWeakpoint(WeakpointTarget);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetWeakpoint(AStoneBossQTEWeakpoint WeakpointTarget)
	{
		Weakpoint = WeakpointTarget;
		WeakpointType = WeakpointTarget.bActivateMashOnHealthDepleted ? EPlayerStoneBossQTEWeakpointType::Final : EPlayerStoneBossQTEWeakpointType::Regular;
	}

	bool IsFurtherAheadThanOtherPlayer() const
	{
		return InstigatedState.Get() > OtherPlayerComponent.InstigatedState.Get();
	}

	FName GetDrawSwordInstigator() const property
	{
		return PlayerOwner.IsMio() ? n"MioDrawSwordTutorialInstigator" : n"ZoeDrawSwordTutorialInstigator";
	}

	FName GetReleaseInstigator() const property
	{
		return PlayerOwner.IsMio() ? n"MioReleaseTutorialInstigator" : n"ZoeReleaseTutorialInstigator";
	}
};