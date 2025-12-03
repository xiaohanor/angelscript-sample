class USanctuaryGrimbeastActionsComponent : UActorComponent
{
	FHazeStructQueue ActionQueue;
}

asset GrimbeastActionSelectionSheet of UHazeCapabilitySheet
{
	AddCapability(n"SanctuaryGrimbeastActionSelectionCapability");
	AddCapability(n"SanctuaryGrimbeastActionIdleCapability");
	AddCapability(n"SanctuaryGrimbeastActionBoulderLaunchCapability");
	AddCapability(n"SanctuaryGrimbeastActionRaisePillarsCapability");
};

class USanctuaryGrimbeastActionSelectionCapability : UHazeCapability
{
	default CapabilityTags.Add(GrimbeastTags::Grimbeast);
	default CapabilityTags.Add(GrimbeastTags::Action);
	USanctuaryGrimbeastActionsComponent ActionComp;
	AAISanctuaryGrimbeast Grimbeast;
	USanctuaryGrimbeastSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ActionComp = USanctuaryGrimbeastActionsComponent::GetOrCreate(Owner);
		Grimbeast = Cast<AAISanctuaryGrimbeast>(Owner);
		Settings = USanctuaryGrimbeastSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl())
			return false;
		if (ActionComp.ActionQueue.IsEmpty())
			return true;
		// some culling check, don't activate if we're like super far or something
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!ActionComp.ActionQueue.IsEmpty())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ShootyBehavior();
	}

	private void ChillBehavior()
	{
		Idle(3.0);
	}

	private void ShootyBehavior()
	{
		RaisePillar();
		Idle(0.2);
		RaisePillar();
		Idle(0.2);
		RaisePillar();
		Idle(0.2);
		CircleShootAttack(0.0);
		Idle(0.1);
		CircleShootAttack(15.0);
		Idle(0.5);
		RaisePillar();
		Idle(0.5);
		RaisePillar();
		Idle(0.5);
		SpiralShootAttack();
		Idle(0.5);
		SpiralShootAttack(false);
		Idle(2.0);
	}

	// -----------

	private void SpiralShootAttack(bool bClockWise = true)
	{
		FSanctuaryGrimbeastBoulderPatternData Data;
		Data.PatternType = bClockWise ? ESanctuaryGrimbeastBoulderPattern::SpiralShot : ESanctuaryGrimbeastBoulderPattern::AntiSpiralShot;
		Data.Amount = 10;
		Data.AngleSpread = 60.0;
		Data.AngleSpace = ESanctuaryGrimbeastBoulderAngleSpace::TowardsCentipedeMiddle;
		ShootPattern(Data);
	}

	private void CircleShootAttack(float AngleOffset)
	{
		FSanctuaryGrimbeastBoulderPatternData Data;
		Data.PatternType = ESanctuaryGrimbeastBoulderPattern::Circle;
		Data.AngleSpace = ESanctuaryGrimbeastBoulderAngleSpace::WorldSpace;
		Data.Amount = 13;
		Data.AngleOffset = AngleOffset;
		ShootPattern(Data);
	}

	// -----------

	private void ShootPattern(FSanctuaryGrimbeastBoulderPatternData ShootPattern)
	{
		FSanctuaryGrimbeastActionBoulderData Data;
		Data.PatternData = ShootPattern;
		ActionComp.ActionQueue.Queue(Data);
	}

	private void Idle(float Duration)
	{
		FSanctuaryGrimbeastActionIdleData Data;
		Data.Duration = Duration;
		ActionComp.ActionQueue.Queue(Data);
	}

	private void RaisePillar()
	{
		TListedActors<ASanctuaryGrimbeastPillar> Pillars;
		if (Pillars.Num() > 0)
		{
			TArray<ASanctuaryGrimbeastPillar> PossiblePillarsToRaise;
			int RaisedPillars = 0;
			for (auto Pillar : Pillars)
			{
				if (Pillar.bFreeForAction)
					PossiblePillarsToRaise.Add(Pillar);
				else
					++RaisedPillars;
			}
			if (PossiblePillarsToRaise.Num() > 0 && RaisedPillars < 5)
			{
				int RandomPillarIdx = Math::RandRange(0, PossiblePillarsToRaise.Num() -1);
				FSanctuaryGrimbeastActionRaisePillarsData Data;
				Data.PillarToRaise = PossiblePillarsToRaise[RandomPillarIdx];
				Data.PillarToRaise.bFreeForAction = false;
				Data.Duration = Math::RandRange(0.1, 2.0);
				Data.HeightMultiplier = Math::RandRange(0.2, 0.7);
				ActionComp.ActionQueue.Queue(Data);
			}
		}
	}
}
