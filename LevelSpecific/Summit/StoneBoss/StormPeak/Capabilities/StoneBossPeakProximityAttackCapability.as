class UStoneBossPeakProximityAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AStoneBossPeak StoneBoss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StoneBoss = Cast<AStoneBossPeak>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!StoneBoss.ProxmityStrikeAttackData.bProximityStrikeActive)
			return false;

		if (StoneBoss.State == EStoneBossPeakPhase::Vulnerable)
			return false;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!StoneBoss.ProxmityStrikeAttackData.bProximityStrikeActive)
			return true;
		
		if (StoneBoss.State == EStoneBossPeakPhase::Vulnerable)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};