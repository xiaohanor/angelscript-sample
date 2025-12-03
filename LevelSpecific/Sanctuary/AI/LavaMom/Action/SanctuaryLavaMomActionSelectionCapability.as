class USanctuaryLavaMomActionsComponent : UActorComponent
{
	FHazeStructQueue ActionQueue;
}

asset LavaMomActionSelectionSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USanctuaryLavaMomActionSelectionCapability);
	Capabilities.Add(USanctuaryLavaMomActionIdleCapability);
	Capabilities.Add(USanctuaryLavaMomActionBoulderLaunchCapability);
};

class USanctuaryLavaMomActionSelectionCapability : UHazeCapability
{
	default CapabilityTags.Add(LavaMomTags::LavaMom);
	default CapabilityTags.Add(LavaMomTags::Action);
	USanctuaryLavaMomActionsComponent ActionComp;
	ASanctuaryLavaMom LavaMom;
	USanctuaryLavaMomSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ActionComp = USanctuaryLavaMomActionsComponent::GetOrCreate(Owner);
		LavaMom = Cast<ASanctuaryLavaMom>(Owner);
		Settings = USanctuaryLavaMomSettings::GetSettings(Owner);
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
	void TickActive(float DeltaTime)
	{
		if (LavaMom.bAttacking)
			ShootyBehavior();		
	}

	private void ChillBehavior()
	{
		Idle(3.0);
	}

	private void ShootyBehavior()
	{
		Idle(0.2);
		CircleShootAttack(0.0);
		Idle(0.1);
		CircleShootAttack(15.0);
		Idle(0.1);
		SpiralShootAttack();
		Idle(0.1);
		SpiralShootAttack(false);
		Idle(0.1);
		BigBoulder();
		Idle(1.0);
	}

	// -----------

	private void BigBoulder()
	{
		FSanctuaryLavaMomBoulderPatternData Data;
		Data.PatternType = ESanctuaryLavaMomBoulderPattern::Arrow;
		Data.Amount = 3;
		Data.AngleSpread = 60.0;
		Data.AngleSpace = ESanctuaryLavaMomBoulderAngleSpace::TowardsCentipedeMiddle;
		Data.bBigBoulder = true;
		ShootPattern(Data);
	}

	private void SpiralShootAttack(bool bClockWise = true)
	{
		FSanctuaryLavaMomBoulderPatternData Data;
		Data.PatternType = bClockWise ? ESanctuaryLavaMomBoulderPattern::SpiralShot : ESanctuaryLavaMomBoulderPattern::AntiSpiralShot;
		Data.Amount = 5;
		Data.AngleSpread = 60.0;
		Data.AngleSpace = ESanctuaryLavaMomBoulderAngleSpace::TowardsCentipedeMiddle;
		ShootPattern(Data);
	}

	private void CircleShootAttack(float AngleOffset)
	{
		FSanctuaryLavaMomBoulderPatternData Data;
		Data.PatternType = ESanctuaryLavaMomBoulderPattern::Circle;
		Data.AngleSpace = ESanctuaryLavaMomBoulderAngleSpace::WorldSpace;
		Data.Amount = 13;
		Data.AngleOffset = AngleOffset;
		ShootPattern(Data);
	}

	// -----------

	private void ShootPattern(FSanctuaryLavaMomBoulderPatternData ShootPattern)
	{
		FSanctuaryLavaMomActionBoulderData Data;
		Data.PatternData = ShootPattern;
		ActionComp.ActionQueue.Queue(Data);
	}

	private void Idle(float Duration)
	{
		FSanctuaryLavaMomActionIdleData Data;
		Data.Duration = Duration;
		ActionComp.ActionQueue.Queue(Data);
	}
}
