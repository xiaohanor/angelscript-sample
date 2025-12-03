event void FKnightChangePhaseSignature(ESummitKnightPhase NewPhase);

enum ESummitKnightPhase
{
	None,

	MobileStart,
	MobileCircling,
	MobileMain,
	MobileEndCircling,
	MobileEndRun,
	MobileAlmostDead,

	// Deprecated
	PathStartArena,
	PathEndArena,
	CrystalCoreDamage,
	FinalArenaStart,
	FinalArenaEnd,
	HeadDamage,
	Test,
}

class USummitKnightStageComponent : UActorComponent
{
	private ESummitKnightPhase CurrentPhase = ESummitKnightPhase::None;
	private uint8 CurrentRound = 0;

	FKnightChangePhaseSignature OnChangePhase;

	void SetPhase(ESummitKnightPhase NewPhase, uint8 NewRound = 0)
	{
		bool bChangedPhase = (CurrentPhase != NewPhase);
		CurrentPhase = NewPhase;
		CurrentRound = NewRound;

		if (bChangedPhase)
			OnChangePhase.Broadcast(NewPhase);
	}

	ESummitKnightPhase GetPhase() const property
	{
		return CurrentPhase;
	}

	uint8 GetRound() const property
	{
		return CurrentRound;
	}
}
