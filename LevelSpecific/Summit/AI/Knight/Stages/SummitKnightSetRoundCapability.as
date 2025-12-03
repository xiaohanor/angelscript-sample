class USummitKnightSetRoundCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	USummitKnightStageComponent StageComp;
	uint8 Round = 0;

	USummitKnightSetRoundCapability(uint8 NextRound)
	{
		Round = NextRound;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StageComp = USummitKnightStageComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StageComp.SetPhase(StageComp.Phase, Round);
	}
}

