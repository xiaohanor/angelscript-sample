class UPrisonBossScissorsExitCapability : UPrisonBossChildCapability
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
		if (ActiveDuration >= PrisonBoss::ScissorsExitDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.AnimationData.bIsExitingScissors = true;

		UPrisonBossEffectEventHandler::Trigger_ScissorsExit(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsExitingScissors = false;
		Boss.CurrentAttackType = EPrisonBossAttackType::None;

		Boss.OnAttackCompleted.Broadcast(EPrisonBossAttackType::Scissors);

		UPrisonBossEffectEventHandler::Trigger_ScissorsFinished(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

	}
}