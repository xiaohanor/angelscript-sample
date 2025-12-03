event void FIslandWalkerPhaseComponentPhaseChangeSignature(EIslandWalkerPhase NewPhase);
event void FIslandWalkerOnSkipIntroSignature(EIslandWalkerPhase NewPhase);

enum EIslandWalkerPhase
{
	Intro,
	IntroEnd, 
	Walking,
	WalkingCollapse, 	// Dummy phase, BP through arena only
	Suspended,
	SuspendedFall, 		// Dummy phase, BP through arena only
	Decapitated,
	ReadyForSwimming,	// Dummy phase, BP through arena only
	Swimming,
	ThrowOffPlayers, 	// Dummy phase, BP through arena only
	Escaping,
	Destroyed
}

class UIslandWalkerPhaseComponent : UActorComponent
{
	EIslandWalkerPhase InternalPhase = EIslandWalkerPhase::Intro;

	UPROPERTY()
	FIslandWalkerPhaseComponentPhaseChangeSignature OnPhaseChange;
	
	FIslandWalkerOnSkipIntroSignature OnSkipIntro;
	float PhaseChangeTime = 0.0;

	UFUNCTION()
	EIslandWalkerPhase GetPhase() property
	{
		return InternalPhase;
	}

	UFUNCTION()
	void SetPhase(EIslandWalkerPhase InPhase) property
	{
		if(InPhase != InternalPhase)
		{
			InternalPhase = InPhase;
			PhaseChangeTime	= Time::GameTimeSeconds;		
			OnPhaseChange.Broadcast(InPhase);
		}
	}

	void SkipIntro()
	{
		OnSkipIntro.Broadcast(InternalPhase);
	}
}
