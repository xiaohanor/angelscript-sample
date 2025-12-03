

class UStoneBossQTEWeakpointButtonMashComponent : UActorComponent
{
	FButtonMashSettings FirstMashSettings;
	default FirstMashSettings.bAllowPlayerCancel = StoneBossQTEWeakpoint::FirstButtonMash::bAllowPlayerCancel;
	default FirstMashSettings.Difficulty = StoneBossQTEWeakpoint::FirstButtonMash::Difficulty;
	default FirstMashSettings.Duration = StoneBossQTEWeakpoint::FirstButtonMash::Duration;

	FButtonMashSettings SecondMashSettings;
	default SecondMashSettings.bAllowPlayerCancel = StoneBossQTEWeakpoint::SecondButtonMash::bAllowPlayerCancel;
	default SecondMashSettings.Difficulty = StoneBossQTEWeakpoint::SecondButtonMash::Difficulty;
	default SecondMashSettings.Duration = StoneBossQTEWeakpoint::SecondButtonMash::Duration;

	AStoneBossQTEWeakpoint Weakpoint;

	EPlayerStoneBossQTEFinalWeakpointStateInfo FinalWeakpointActiveStateInfo;

	// Time for the animation to play before the complete logic executes
	float TimeToCompleteFirstMash = 0.6;

	// Time for the second animation to play before the complete logic executes
	float TimeToCompleteSecondMash = 1.0;

	bool bIsButtonMashActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Weakpoint = Cast<AStoneBossQTEWeakpoint>(Owner);
	}

	FInstigator GetFirstButtonMashInstigator() const
	{
		return n"WeakpointQTEFirstMashInstigator";
	}

	FInstigator GetSecondButtonMashInstigator() const
	{
		return n"WeakpointQTESecondMashInstigator";
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TEMPORAL_LOG(this).Value("FinalWeakpointActiveStateInfo", FinalWeakpointActiveStateInfo);
	}

	UFUNCTION()
	void ActivateFirstButtonMash()
	{
		bIsButtonMashActive = true;
		
		FinalWeakpointActiveStateInfo = EPlayerStoneBossQTEFinalWeakpointStateInfo::ButtonMash;
		Weakpoint.CurrentButtonMashInstigator = GetFirstButtonMashInstigator();

		FButtonMashSettings MioMashSettings = FirstMashSettings;
		MioMashSettings.WidgetAttachComponent = Weakpoint.MioSwordRoot;

		FButtonMashSettings ZoeMashSettings = FirstMashSettings;
		ZoeMashSettings.WidgetAttachComponent = Weakpoint.ZoeSwordRoot;

		ButtonMash::StartDoubleButtonMash(MioMashSettings, ZoeMashSettings, GetFirstButtonMashInstigator(), FOnButtonMashCompleted(this, n"OnFirstMashCompleted"));
		Game::Zoe.ActivateCamera(Weakpoint.ButtonMashFocusCamera, Weakpoint.ButtonMashBlendInTime, this, EHazeCameraPriority::VeryHigh);
		// Weakpoint.CrumbSetWeakpointInfo(EPlayerStoneBossQTEFinalWeakpointStateInfo::ButtonMashStab);
	}

	UFUNCTION()
	void ActivateSecondButtonMash()
	{
		FinalWeakpointActiveStateInfo = EPlayerStoneBossQTEFinalWeakpointStateInfo::ButtonMash;
		Weakpoint.CurrentButtonMashInstigator = GetSecondButtonMashInstigator();
		FButtonMashSettings MioMashSettings = SecondMashSettings;
		MioMashSettings.WidgetAttachComponent = Weakpoint.MioSwordRoot;

		FButtonMashSettings ZoeMashSettings = SecondMashSettings;
		ZoeMashSettings.WidgetAttachComponent = Weakpoint.ZoeSwordRoot;

		ButtonMash::StartDoubleButtonMash(MioMashSettings, ZoeMashSettings, GetSecondButtonMashInstigator(), FOnButtonMashCompleted(this, n"OnSecondMashCompleted"));

		Game::Zoe.ActivateCamera(Weakpoint.ButtonMashFocusCamera, Weakpoint.ButtonMashBlendInTime, this, EHazeCameraPriority::VeryHigh);
	}

	UFUNCTION()
	private void OnFirstMashCompleted()
	{
		FinalWeakpointActiveStateInfo = EPlayerStoneBossQTEFinalWeakpointStateInfo::ButtonMashStab;
		Weakpoint.CompleteFirstMash();
	}

	UFUNCTION()
	void OnSecondMashCompleted()
	{
		FinalWeakpointActiveStateInfo = EPlayerStoneBossQTEFinalWeakpointStateInfo::FinalStab;
		Weakpoint.CompleteSecondMash();
	}
}