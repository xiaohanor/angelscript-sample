class USanctuaryBossHydraFireBreathRecoverCapability : USanctuaryBossHydraChildCapability
{
	float RecoverDuration;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > RecoverDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		RecoverDuration = AttackData.RecoverDuration;
		if (RecoverDuration < 0.0)
			RecoverDuration = Settings.FireBreathRecoverDuration;

		Head.AnimationData.bIsFireBreathRecovering = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Head.AnimationData.bIsFireBreathRecovering = false;
	}
}