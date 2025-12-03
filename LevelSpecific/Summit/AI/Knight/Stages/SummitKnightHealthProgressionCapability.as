class USummitKnightHealthProgressionCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UBasicAIHealthComponent HealthComp;
	USummitKnightStageComponent StageComp;
	ESummitKnightPhase Phase = ESummitKnightPhase::None;
	uint8 Round = 0;

	float AtHealth = 0.0;

	USummitKnightHealthProgressionCapability(float HealthThreshold, ESummitKnightPhase NextPhase, uint8 NextRound = 0)
	{
		Phase = NextPhase;
		Round = NextRound;
		AtHealth = HealthThreshold;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StageComp = USummitKnightStageComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (HealthComp.CurrentHealth > AtHealth)
			return false;
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
		StageComp.SetPhase(Phase, Round);
	}
}

