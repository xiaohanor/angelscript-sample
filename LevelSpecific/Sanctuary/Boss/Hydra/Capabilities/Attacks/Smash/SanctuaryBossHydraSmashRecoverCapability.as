class USanctuaryBossHydraSmashRecoverCapability : USanctuaryBossHydraChildCapability
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
			RecoverDuration = Settings.SmashRecoverDuration;

		Head.AnimationData.bIsSmashRecovering = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Head.AnimationData.bIsSmashRecovering = false;
	}
}