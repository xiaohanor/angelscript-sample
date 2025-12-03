class UPrisonBossZigZagExitCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= PrisonBoss::ZigZagExitDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.AnimationData.bIsExitingZigZag = true;

		UPrisonBossEffectEventHandler::Trigger_ZigZagExit(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsExitingZigZag = false;
		Boss.CurrentAttackType = EPrisonBossAttackType::None;

		Boss.OnAttackCompleted.Broadcast(EPrisonBossAttackType::ZigZag);

		UPrisonBossEffectEventHandler::Trigger_ZigZagFinished(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		
	}
}