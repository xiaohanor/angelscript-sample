class USummitKnightCheckProgressCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	USummitKnightStageComponent StageComp;
	UBasicAIHealthComponent HealthComp;
	ESummitKnightPhase Phase = ESummitKnightPhase::None;
	uint8 Round = 0;
	USummitKnightSettings Settings;

	USummitKnightCheckProgressCapability(ESummitKnightPhase CheckPhase, uint8 CheckRound = 0)
	{
		Phase = CheckPhase;
		Round = CheckRound;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StageComp = USummitKnightStageComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		Settings = USummitKnightSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!ShouldProgress())		
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

	bool ShouldProgress() const
	{
		if (Phase == ESummitKnightPhase::MobileStart)
		{
			return true;
		}
		if (Phase == ESummitKnightPhase::MobileCircling)
		{
			if (HealthComp.CurrentHealth < Settings.HealthThresholdStartToCircling)
				return true;
		}
		if (Phase == ESummitKnightPhase::MobileMain)
		{
			return true;
		}
		if (Phase == ESummitKnightPhase::MobileEndCircling)
		{
			if (HealthComp.CurrentHealth < Settings.HealthThresholdMainToEndCircling)
				return true;
		}
		if (Phase == ESummitKnightPhase::MobileEndRun)
		{
			return true;
		}
		if (Phase == ESummitKnightPhase::MobileAlmostDead)
		{
			if (HealthComp.CurrentHealth < Settings.SmashCrystalDamage)
				return true;
		}		
		return false;
	}
}

