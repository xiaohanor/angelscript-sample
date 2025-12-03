class UPinballBossVulnerableCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::Gameplay;

	APinballBoss Boss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<APinballBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Boss.bVulnerable)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Boss.bVulnerable)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.bVulnerable = true;

		Boss.OnOpenCore.Broadcast();

		UPinballBossEventHandler::Trigger_OnBecomeVulnerable(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.bVulnerable = false;

		Boss.OnCloseCore.Broadcast();

		UPinballBossEventHandler::Trigger_OnEndVulnerable(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			if(Boss.BossState != EPinballBossState::ChargeAttack && ActiveDuration > 0.1)
			{
				// After being vulnerable for 1 second, we start the charge attack
				CrumbTransitionToChargeAttack();
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbTransitionToChargeAttack()
	{
		Boss.SetBossState(EPinballBossState::ChargeAttack);
	}
};